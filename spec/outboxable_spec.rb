# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveOutbox::Outboxable do
  Outbox = Class.new(ActiveOutbox::Base) do
    def self.name
      'Outbox'
    end
  end
  FakeModel = Class.new(ActiveRecord::Base) do
    def self.name
      'FakeModel'
    end

    include ActiveOutbox::Outboxable
    validates :identifier, presence: true
  end

  before(:all) do
    ActiveRecord::Base.connection.create_table :fake_models do |t|
      t.string :identifier, null: false
    end

    ActiveRecord::Base.connection.create_table :outboxes do |t|
      t.string :identifier, null: false, index: { unique: true }
      t.string :event, null: false
      t.string :payload
      t.string :aggregate, null: false
      t.string :aggregate_identifier, null: false

      t.timestamps
    end
  end

  describe '#save' do
    subject { fake_model_instance.save }

    before do
      allow_any_instance_of(FakeModel).to receive(:payload).and_wrap_original do |m, args|
        m.call(*args).to_json
      end
      allow_any_instance_of(Outbox).to receive(:payload).and_wrap_original do |m, args|
        m.call(*args).to_json
      end
    end

    let(:fake_model_instance) { FakeModel.new(identifier: identifier) }
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
          subject
          outbox = Outbox.last
          expect(outbox.aggregate).to eq('FakeModel')
          expect(outbox.aggregate_identifier).to eq(identifier)
          expect(outbox.event).to eq('FAKE_MODEL_CREATED')
          expect(outbox.identifier).not_to be_nil
          expect(outbox.payload['after']).to eq(FakeModel.last.to_json)
          expect(outbox.payload['before']).to be_nil
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
          outbox = Outbox.new(identifier: SecureRandom.uuid, event: nil, payload: payload, aggregate: FakeModel.name, aggregate_identifier: fake_model_instance.identifier)
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
          expect { subject }.to change { fake_model_instance.errors.messages }.from({}).to({ "outbox.event": ["can't be blank"] })
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
          expect { subject }.to raise_error(ActiveRecord::RecordNotSaved).and not_change(FakeModel, :count)
        end

        it 'does not create the outbox record' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotSaved).and not_change(Outbox, :count)
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

      let(:fake_model_instance) { FakeModel.create(identifier: identifier) }
      let!(:fake_model_json) { fake_model_instance.to_json }
      let(:identifier) { SecureRandom.uuid }
      let(:new_identifier) { SecureRandom.uuid }

      context 'when outbox record is created' do
        it { is_expected.to be true }

        it 'updates the record' do
          expect { subject }.to not_change(FakeModel, :count)
            .and change(fake_model_instance, :identifier).to(new_identifier)
        end

        it 'creates the outbox record' do
          expect { subject }.to change(Outbox, :count).by(1)
        end

        it 'creates the outbox record with the correct data' do
          subject
          outbox = Outbox.last
          expect(outbox.aggregate).to eq('FakeModel')
          expect(outbox.aggregate_identifier).to eq(new_identifier)
          expect(outbox.event).to eq('FAKE_MODEL_UPDATED')
          expect(outbox.identifier).not_to be_nil
          expect(outbox.payload['after']).to eq(FakeModel.last.to_json)
          expect(outbox.payload['before']).to eq(fake_model_json)
        end
      end
    end
  end

  describe '#save!' do
    subject { fake_model_instance.save! }

    let(:identifier) { SecureRandom.uuid }
    let(:fake_model_instance) { FakeModel.new(identifier: identifier) }

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
          outbox = Outbox.new(identifier: SecureRandom.uuid, event: nil, payload: payload, aggregate: FakeModel.name, aggregate_identifier: fake_model_instance.identifier)
          allow(Outbox).to receive(:new).and_return(outbox)
        end

        it 'raises error' do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        end

        it 'does not create the record' do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid).and not_change(FakeModel, :count)
        end

        it 'does not create the outbox record' do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid).and not_change(Outbox, :count)
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
          expect { subject }.to raise_error(ActiveRecord::RecordNotSaved).and not_change(FakeModel, :count)
        end

        it 'does not create the outbox record' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotSaved).and not_change(Outbox, :count)
        end
      end
    end

    context 'when the record could not be created' do
      let(:identifier) { nil }

      it 'raises error' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'does not create the record' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid).and not_change(FakeModel, :count)
      end

      it 'does not create the outbox record' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid).and not_change(Outbox, :count)
      end
    end
  end

  describe '#create' do
    subject { FakeModel.create(identifier: identifier) }

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
          subject
          outbox = Outbox.last
          expect(outbox.aggregate).to eq('FakeModel')
          expect(outbox.aggregate_identifier).to eq(identifier)
          expect(outbox.event).to eq('FAKE_MODEL_CREATED')
          expect(outbox.identifier).not_to be_nil
          expect(outbox.payload['after']).to eq(FakeModel.last.to_json)
          expect(outbox.payload['before']).to be_nil
        end
      end
    end
  end

  describe '#update' do
    subject { fake_model.update(identifier: new_identifier) }

    let!(:fake_model) { FakeModel.create(identifier: identifier) }
    let!(:fake_old_model) { fake_model.to_json }
    let(:identifier) { SecureRandom.uuid }
    let(:new_identifier) { SecureRandom.uuid }

    context 'when record is updated' do
      context 'when outbox record is created' do
        it { is_expected.to be true }

        it 'updates the record' do
          expect { subject }.to not_change(FakeModel, :count)
            .and change(fake_model, :identifier).to(new_identifier)
        end

        it 'creates the outbox record' do
          expect { subject }.to change(Outbox, :count).by(1)
        end

        it 'creates the outbox record with the correct data' do
          subject
          outbox = Outbox.last
          expect(outbox.aggregate).to eq('FakeModel')
          expect(outbox.aggregate_identifier).to eq(new_identifier)
          expect(outbox.event).to eq('FAKE_MODEL_UPDATED')
          expect(outbox.identifier).not_to be_nil
          expect(outbox.payload['before']).to eq(fake_old_model)
          expect(outbox.payload['after']).to eq(fake_model.reload.to_json)
        end
      end
    end
  end

  describe '#destroy' do
    subject { fake_model.destroy }

    let!(:fake_model) { FakeModel.create(identifier: identifier) }
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
          subject
          outbox = Outbox.last
          expect(outbox.aggregate).to eq('FakeModel')
          expect(outbox.aggregate_identifier).to eq(identifier)
          expect(outbox.event).to eq('FAKE_MODEL_DESTROYED')
          expect(outbox.identifier).not_to be_nil
          expect(outbox.payload['after']).to be_nil
          expect(outbox.payload['before']).to eq(fake_model.to_json)
        end
      end
    end
  end
end
