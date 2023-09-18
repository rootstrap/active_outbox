# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveOutbox::Outboxable do
  describe '#save' do
    subject { fake_model_instance.save }

    let(:fake_model_instance) { FakeModel.new(identifier:) }
    let(:identifier) { SecureRandom.uuid }

    context 'when record is created' do
      context 'when outbox record is created' do
        it { is_expected.to be true }

        it 'creates the record' do
          expect { subject }.to change(FakeModel, :count).by(1)
        end

        it 'creates the outbox record' do
          expect { subject }.to change(Outbox, :count).by(1)
        end

        it 'creates the outbox record with the correct data' do
          expect { subject }.to create_outbox_record(Outbox).with_attributes(lambda {
            {
              'event' => 'FAKE_MODEL_CREATED',
              'aggregate' => 'FakeModel',
              'aggregate_identifier' => identifier,
              'payload' => {
                'before' => nil,
                'after' => FakeModel.last.as_json
              }
            }
          })
        end
      end

      context 'when there is a record invalid error when creating the outbox record' do
        before do
          payload = {
            before: nil,
            after: {
              id: 1,
              identifier: '7d8f60e3-5e7f-4c11-b18b-5cc01ceea3da'
            }
          }
          outbox = Outbox.new(identifier: SecureRandom.uuid, event: nil, payload:, aggregate: FakeModel.name,
                              aggregate_identifier: fake_model_instance.identifier)
          allow(Outbox).to receive(:new).and_return(outbox)
        end

        it { is_expected.to be false }

        it 'does not create the record' do
          expect { subject }.to change(FakeModel, :count).by(0)
        end

        it 'does not create the outbox record' do
          expect { subject }.to change(Outbox, :count).by(0)
        end

        it 'adds the errors to the model' do
          expect { subject }.to change {
            fake_model_instance.errors.messages
          }.from({}).to({ "outbox.event": ["can't be blank"] })
        end
      end

      context 'when there is an error when creating the outbox record' do
        before do
          outbox = instance_double(Outbox, invalid?: false)
          allow(Outbox).to receive(:new).and_return(outbox)
          allow(outbox).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved)
        end

        it 'raises error' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotSaved)
        end

        it 'does not create the record' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotSaved).and change(FakeModel, :count).by(0)
        end

        it 'does not create the outbox record' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotSaved).and change(Outbox, :count).by(0)
        end
      end
    end

    context 'when the record could not be created' do
      let(:identifier) { nil }

      it { is_expected.to be false }

      it 'does not create the record' do
        expect { subject }.to change(FakeModel, :count).by(0)
      end

      it 'does not create the outbox record' do
        expect { subject }.to change(Outbox, :count).by(0)
      end
    end

    context 'when record is updated' do
      subject do
        fake_model_instance.identifier = new_identifier
        fake_model_instance.save
      end

      let(:fake_model_instance) { FakeModel.create(identifier:) }
      let!(:fake_model_json) { fake_model_instance.as_json }
      let(:identifier) { SecureRandom.uuid }
      let(:new_identifier) { SecureRandom.uuid }

      context 'when outbox record is created' do
        it { is_expected.to be true }

        it 'updates the record' do
          expect { subject }.to change(FakeModel, :count).by(0)
            .and change(fake_model_instance,
                        :identifier).to(new_identifier)
        end

        it 'creates the outbox record' do
          expect { subject }.to change(Outbox, :count).by(1)
        end

        it 'creates the outbox record with the correct data' do
          expect { subject }.to create_outbox_record(Outbox).with_attributes(lambda {
            {
              'event' => 'FAKE_MODEL_UPDATED',
              'aggregate' => 'FakeModel',
              'aggregate_identifier' => new_identifier,
              'payload' => {
                'before' => fake_model_json,
                'after' => FakeModel.last.as_json
              }
            }
          })
        end
      end
    end
  end

  describe '#save!' do
    subject { fake_model_instance.save! }

    let(:identifier) { SecureRandom.uuid }
    let(:fake_model_instance) { FakeModel.new(identifier:) }

    context 'when record is created' do
      context 'when outbox record is created' do
        it { is_expected.to be true }

        it 'creates the record' do
          expect { subject }.to change(FakeModel, :count).by(1)
        end

        it 'creates the outbox record' do
          expect { subject }.to change(Outbox, :count).by(1)
        end
      end

      context 'when there is a record invalid error when creating the outbox record' do
        before do
          payload = {
            before: nil,
            after: {
              id: 1,
              identifier: '7d8f60e3-5e7f-4c11-b18b-5cc01ceea3da'
            }
          }
          outbox = Outbox.new(identifier: SecureRandom.uuid, event: nil, payload:, aggregate: FakeModel.name,
                              aggregate_identifier: fake_model_instance.identifier)
          allow(Outbox).to receive(:new).and_return(outbox)
        end

        it 'raises error' do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        end

        it 'does not create the record' do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid).and change(FakeModel, :count).by(0)
        end

        it 'does not create the outbox record' do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid).and change(Outbox, :count).by(0)
        end

        it 'adds the errors to the model' do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
            .and change { fake_model_instance.errors.messages }.from({}).to({ "outbox.event": ["can't be blank"] })
        end
      end

      context 'when there is an error when creating the outbox record' do
        before do
          outbox = instance_double(Outbox, invalid?: false)
          allow(Outbox).to receive(:new).and_return(outbox)
          allow(outbox).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved)
        end

        it 'raises error' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotSaved)
        end

        it 'does not create the record' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotSaved).and change(FakeModel, :count).by(0)
        end

        it 'does not create the outbox record' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotSaved).and change(Outbox, :count).by(0)
        end
      end
    end

    context 'when the record could not be created' do
      let(:identifier) { nil }

      it 'raises error' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'does not create the record' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid).and change(FakeModel, :count).by(0)
      end

      it 'does not create the outbox record' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid).and change(Outbox, :count).by(0)
      end
    end
  end

  describe '#create' do
    subject { FakeModel.create(identifier:) }

    let(:identifier) { SecureRandom.uuid }

    context 'when record is created' do
      context 'when outbox record is created' do
        it { is_expected.to eq(FakeModel.last) }

        it 'creates the record' do
          expect { subject }.to change(FakeModel, :count).by(1)
        end

        it 'creates the outbox record' do
          expect { subject }.to change(Outbox, :count).by(1)
        end

        it 'creates the outbox record with the correct data' do
          expect { subject }.to create_outbox_record(Outbox).with_attributes(lambda {
            {
              'event' => 'FAKE_MODEL_CREATED',
              'aggregate' => 'FakeModel',
              'aggregate_identifier' => identifier,
              'payload' => {
                'before' => nil,
                'after' => FakeModel.last.as_json
              }
            }
          })
        end
      end
    end
  end

  describe '#update' do
    subject { fake_model.update(identifier: new_identifier) }

    let!(:fake_model) { FakeModel.create(identifier:) }
    let!(:fake_old_model) { fake_model.as_json }
    let(:identifier) { SecureRandom.uuid }
    let(:new_identifier) { SecureRandom.uuid }

    context 'when record is updated' do
      context 'when outbox record is created' do
        it { is_expected.to be true }

        it 'updates the record' do
          expect { subject }.to change(FakeModel, :count).by(0)
            .and change(fake_model, :identifier).to(new_identifier)
        end

        it 'creates the outbox record' do
          expect { subject }.to change(Outbox, :count).by(1)
        end

        it 'creates the outbox record with the correct data' do
          expect { subject }.to create_outbox_record(Outbox).with_attributes(lambda {
            {
              'event' => 'FAKE_MODEL_UPDATED',
              'aggregate' => 'FakeModel',
              'aggregate_identifier' => new_identifier,
              'payload' => {
                'before' => fake_old_model,
                'after' => fake_model.reload.as_json
              }
            }
          })
        end
      end
    end
  end

  describe '#destroy' do
    subject { fake_model.destroy }

    let!(:fake_model) { FakeModel.create(identifier:) }
    let(:identifier) { SecureRandom.uuid }

    context 'when record is destroyed' do
      context 'when outbox record is created' do
        it { is_expected.to eq(fake_model) }

        it 'destroys the record' do
          expect { subject }.to change(FakeModel, :count).by(-1)
        end

        it 'creates the outbox record' do
          expect { subject }.to change(Outbox, :count).by(1)
        end

        it 'creates the outbox record with the correct data' do
          expect { subject }.to create_outbox_record(Outbox).with_attributes(lambda {
            {
              'event' => 'FAKE_MODEL_DESTROYED',
              'aggregate' => 'FakeModel',
              'aggregate_identifier' => identifier,
              'payload' => {
                'before' => fake_model.as_json,
                'after' => nil
              }
            }
          })
        end
      end
    end
  end
end
