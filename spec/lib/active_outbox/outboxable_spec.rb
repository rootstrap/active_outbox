# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveOutbox::Outboxable do
  let(:fake_model_instance) { FakeModel.new(identifier: identifier) }
  let(:identifier) { SecureRandom.uuid }

  let(:outbox_record_attributes) do
    {
      'event' => event,
      'aggregate' => 'FakeModel',
      'aggregate_identifier' => aggregate_identifier,
      'payload' => {
        'before' => payload_before,
        'after' => payload_after
      }
    }
  end
  let(:aggregate_identifier) { identifier }
  let(:payload_before) { nil }
  let(:payload_after) { FakeModel.last.as_json }

  shared_examples 'creates the outbox record' do
    it { expect { subject }.to change(Outbox, :count).by(1) }
  end

  shared_examples 'creates the record and the outbox record' do
    include_examples 'creates the outbox record'

    it { expect { subject }.to change(FakeModel, :count).by(1) }
  end

  shared_examples 'creates the outbox record with the correct data' do
    it { expect { subject }.to create_outbox_record(Outbox).with_attributes(-> { outbox_record_attributes }) }
  end

  shared_examples 'updates the record' do
    specify do
      expect { subject }.to not_change(FakeModel, :count)
        .and change(fake_model_instance, :identifier).to(new_identifier)
    end
  end

  shared_examples 'does not create neither the record nor the outbox record' do
    it { expect { subject }.not_to change(FakeModel, :count) }
    it { expect { subject }.not_to change(Outbox, :count) }
  end

  shared_examples 'raises an error and does not create neither the record nor the outbox record' do |error_class|
    it { expect { subject }.to raise_error(error_class) }
    it { expect { subject }.to raise_error(error_class).and not_change(FakeModel, :count) }
    it { expect { subject }.to raise_error(error_class).and not_change(Outbox, :count) }
  end

  describe '#save' do
    subject(:save_instance) { fake_model_instance.save }

    context 'when record is created' do
      context 'when outbox record is created' do
        let(:event) { 'FAKE_MODEL_CREATED' }

        include_examples 'creates the record and the outbox record'
        include_examples 'creates the outbox record with the correct data'

        it { is_expected.to be true }
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

          outbox = Outbox.new(
            identifier: SecureRandom.uuid,
            event: nil,
            payload: payload,
            aggregate: FakeModel.name,
            aggregate_identifier: fake_model_instance.identifier
          )

          allow(Outbox).to receive(:new).and_return(outbox)
        end

        include_examples 'does not create neither the record nor the outbox record'

        it { is_expected.to be false }

        it 'adds the errors to the model' do
          expect { save_instance }.to change {
            fake_model_instance.errors.messages
          }.from({}).to({ 'outbox.event': ["can't be blank"] })
        end
      end

      context 'when there is an error when creating the outbox record' do
        before do
          outbox = instance_double(Outbox, invalid?: false)
          allow(Outbox).to receive(:new).and_return(outbox)
          allow(outbox).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved)
        end

        include_examples 'raises an error and does not create neither the record nor the outbox record',
                         ActiveRecord::RecordNotSaved
      end
    end

    context 'when the record could not be created' do
      let(:identifier) { nil }

      include_examples 'does not create neither the record nor the outbox record'

      it { is_expected.to be false }
    end

    context 'when record is updated' do
      subject(:save_instance) do
        fake_model_instance.identifier = new_identifier
        fake_model_instance.save
      end

      let(:fake_model_instance) { FakeModel.create(identifier: identifier) }

      context 'when outbox record is created' do
        let(:event) { 'FAKE_MODEL_UPDATED' }
        let(:aggregate_identifier) { new_identifier }
        let(:payload_before) { fake_model_instance.as_json }

        before { payload_before }

        include_examples 'creates the outbox record'
        include_examples 'creates the outbox record with the correct data'
        include_examples 'updates the record' do
          let(:new_identifier) { SecureRandom.uuid }
        end

        it { is_expected.to be true }
      end
    end
  end

  describe '#save!' do
    subject(:bang_save_instance) { fake_model_instance.save! }

    context 'when record is created' do
      context 'when outbox record is created' do
        include_examples 'creates the record and the outbox record'

        it { is_expected.to be true }
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

          outbox = Outbox.new(
            identifier: SecureRandom.uuid,
            event: nil,
            payload: payload,
            aggregate: FakeModel.name,
            aggregate_identifier: fake_model_instance.identifier
          )

          allow(Outbox).to receive(:new).and_return(outbox)
        end

        include_examples 'raises an error and does not create neither the record nor the outbox record',
                         ActiveRecord::RecordInvalid

        it 'adds the errors to the model' do
          expect { bang_save_instance }.to raise_error(ActiveRecord::RecordInvalid)
            .and change { fake_model_instance.errors.messages }.from({}).to({ 'outbox.event': ["can't be blank"] })
        end
      end

      context 'when there is an error when creating the outbox record' do
        before do
          outbox = instance_double(Outbox, invalid?: false)
          allow(Outbox).to receive(:new).and_return(outbox)
          allow(outbox).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved)
        end

        include_examples 'raises an error and does not create neither the record nor the outbox record',
                         ActiveRecord::RecordNotSaved
      end
    end

    context 'when the record could not be created' do
      let(:identifier) { nil }

      include_examples 'raises an error and does not create neither the record nor the outbox record',
                       ActiveRecord::RecordInvalid
    end
  end

  describe '#create' do
    subject(:create_instance) { FakeModel.create(identifier: identifier) }

    context 'when record is created' do
      context 'when outbox record is created' do
        let(:event) { 'FAKE_MODEL_CREATED' }

        include_examples 'creates the record and the outbox record'
        include_examples 'creates the outbox record with the correct data'

        it { is_expected.to eq(FakeModel.last) }
      end
    end
  end

  describe '#update' do
    subject(:update_instance) { fake_model_instance.update(identifier: new_identifier) }

    let!(:fake_model_instance) { FakeModel.create(identifier: identifier) }

    context 'when record is updated' do
      context 'when outbox record is created' do
        let(:event) { 'FAKE_MODEL_UPDATED' }
        let(:aggregate_identifier) { new_identifier }
        let(:payload_before) { fake_model_instance.as_json }
        let(:payload_after) { fake_model_instance.reload.as_json }

        before { payload_before }

        include_examples 'creates the outbox record'
        include_examples 'creates the outbox record with the correct data'
        include_examples 'updates the record' do
          let(:new_identifier) { SecureRandom.uuid }
        end

        it { is_expected.to be true }
      end
    end
  end

  describe '#destroy' do
    subject(:destroy_instance) { fake_model_instance.destroy }

    let!(:fake_model_instance) { FakeModel.create(identifier: identifier) }

    context 'when record is destroyed' do
      context 'when outbox record is created' do
        let(:event) { 'FAKE_MODEL_DESTROYED' }
        let(:payload_before) { fake_model_instance.as_json }
        let(:payload_after) { nil }

        include_examples 'creates the outbox record'
        include_examples 'creates the outbox record with the correct data'

        it { is_expected.to eq(fake_model_instance) }

        it 'destroys the record' do
          expect { destroy_instance }.to change(FakeModel, :count).by(-1)
        end
      end
    end
  end
end
