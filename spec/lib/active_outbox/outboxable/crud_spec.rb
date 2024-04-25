# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveOutbox::Outboxable do
  let(:fake_model_class) { double }
  let(:outbox_class) { double }
  let(:fake_model_instance) { double }
  let(:identifier) { double }
  let(:new_identifier) { double }

  let(:outbox_record_attributes) do
    {
      'event' => event,
      'aggregate' => fake_model_instance.class.name,
      'aggregate_identifier' => aggregate_identifier,
      'payload' => {
        'before' => payload_before,
        'after' => payload_after
      }
    }
  end
  let(:aggregate_identifier) { identifier }
  let(:payload_before) { nil }
  let(:payload_after) { double }

  shared_examples 'creates the outbox record' do
    it { expect { subject }.to change(outbox_class, :count).by(1) }
  end

  shared_examples 'creates the record and the outbox record' do
    include_examples 'creates the outbox record'

    it { expect { subject }.to change(fake_model_class, :count).by(1) }
  end

  shared_examples 'creates the outbox record with the correct data' do
    it { expect { subject }.to create_outbox_record(outbox_class).with_attributes(-> { outbox_record_attributes }) }
  end

  shared_examples 'updates the record' do
    specify do
      expect { subject }.to not_change(fake_model_class, :count)
        .and change(fake_model_instance, fake_model_class.primary_key).to(new_identifier)
    end
  end

  shared_examples 'does not create neither the record nor the outbox record' do
    it { expect { subject }.not_to change(fake_model_class, :count) }
    it { expect { subject }.not_to change(outbox_class, :count) }
  end

  shared_examples 'raises an error and does not create neither the record nor the outbox record' do |error_class|
    it { expect { subject }.to raise_error(error_class) }
    it { expect { subject }.to raise_error(error_class).and not_change(fake_model_class, :count) }
    it { expect { subject }.to raise_error(error_class).and not_change(outbox_class, :count) }
  end

  def create_event_name(action)
    *namespace, klass = fake_model_class.name.underscore.upcase.split('/')
    namespace = namespace.reverse.join('.')
    event_name = "#{klass}_#{action.upcase}"
    "#{event_name}#{namespace.blank? ? '' : '.'}#{namespace}"
  end

  shared_examples 'model CRUD' do
    describe '#save' do
      subject(:save_instance) { fake_model_instance.save }

      context 'when record is created' do
        context 'when the ActiveOutbox configuration is not set' do
          before do
            allow(ActiveOutbox.config).to receive(:outbox_mapping).and_return({ 'default' => nil })
          end

          include_examples 'raises an error and does not create neither the record nor the outbox record',
            ActiveOutbox::OutboxClassNotFoundError
        end

        context 'when outbox record is created' do
          let(:event) { create_event_name('created') }

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

            outbox = outbox_class.new(
              identifier: SecureRandom.uuid,
              event: nil,
              payload: payload,
              aggregate: fake_model_class.name,
              aggregate_identifier: fake_model_instance.send(fake_model_class.primary_key)
            )

            allow(outbox_class).to receive(:new).and_return(outbox)
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
            outbox = instance_double(outbox_class, invalid?: false)
            allow(outbox_class).to receive(:new).and_return(outbox)
            allow(outbox).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved)
          end

          include_examples 'raises an error and does not create neither the record nor the outbox record',
            ActiveRecord::RecordNotSaved
        end
      end

      context 'when the record could not be created' do
        let(:test_field) { nil }

        include_examples 'does not create neither the record nor the outbox record'

        it { is_expected.to be false }
      end

      context 'when record is updated' do
        subject(:save_instance) do
          fake_model_instance.send("#{fake_model_class.primary_key}=", new_identifier)
          fake_model_instance.save
        end

        let(:fake_model_instance) do
          fake_model_class.create("#{fake_model_class.primary_key}": identifier, test_field: test_field)
        end

        context 'when outbox record is created' do
          let(:event) { create_event_name('updated') }
          let(:aggregate_identifier) { new_identifier }
          let(:payload_before) { fake_model_instance.as_json }

          before { payload_before }

          include_examples 'creates the outbox record'
          include_examples 'creates the outbox record with the correct data'
          include_examples 'updates the record'

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

            outbox = outbox_class.new(
              identifier: SecureRandom.uuid,
              event: nil,
              payload: payload,
              aggregate: fake_model_class.name,
              aggregate_identifier: fake_model_instance.send(fake_model_class.primary_key)
            )

            allow(outbox_class).to receive(:new).and_return(outbox)
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
            outbox = instance_double(outbox_class, invalid?: false)
            allow(outbox_class).to receive(:new).and_return(outbox)
            allow(outbox).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved)
          end

          include_examples 'raises an error and does not create neither the record nor the outbox record',
            ActiveRecord::RecordNotSaved
        end
      end

      context 'when the record could not be created' do
        let(:test_field) { nil }

        include_examples 'raises an error and does not create neither the record nor the outbox record',
          ActiveRecord::RecordInvalid
      end
    end

    describe '#create' do
      subject(:create_instance) do
        fake_model_class.create("#{fake_model_class.primary_key}": identifier, test_field: test_field)
      end

      context 'when record is created' do
        context 'when outbox record is created' do
          let(:event) { create_event_name('created') }

          include_examples 'creates the record and the outbox record'
          include_examples 'creates the outbox record with the correct data'

          it { is_expected.to eq(fake_model_class.last) }
        end
      end
    end

    describe '#update' do
      subject(:update_instance) { fake_model_instance.update("#{fake_model_class.primary_key}": new_identifier) }

      let!(:fake_model_instance) do
        fake_model_class.create("#{fake_model_class.primary_key}": identifier, test_field: test_field)
      end

      context 'when record is updated' do
        context 'when outbox record is created' do
          let(:event) { create_event_name('updated') }
          let(:aggregate_identifier) { new_identifier }
          let(:payload_before) { fake_model_instance.as_json }
          let(:payload_after) { fake_model_instance.reload.as_json }

          before { payload_before }

          include_examples 'creates the outbox record'
          include_examples 'creates the outbox record with the correct data'
          include_examples 'updates the record'

          it { is_expected.to be true }
        end
      end
    end

    describe '#destroy' do
      subject(:destroy_instance) { fake_model_instance.destroy }

      let!(:fake_model_instance) do
        fake_model_class.create("#{fake_model_class.primary_key}": identifier, test_field: test_field)
      end

      context 'when record is destroyed' do
        context 'when outbox record is created' do
          let(:event) { create_event_name('destroyed') }
          let(:payload_before) { fake_model_instance.as_json }
          let(:payload_after) { nil }

          include_examples 'creates the outbox record'
          include_examples 'creates the outbox record with the correct data'

          it { is_expected.to eq(fake_model_instance) }

          it 'destroys the record' do
            expect { destroy_instance }.to change(fake_model_class, :count).by(-1)
          end
        end
      end
    end
  end

  context 'when model has default primary_key' do
    let(:fake_model_class) { FakeModel }
    let(:outbox_class) { Outbox }
    let(:identifier) { 2 }
    let(:new_identifier) { 6 }
    let(:test_field) { 'test' }
    let(:fake_model_instance) do
      fake_model_class.new("#{fake_model_class.primary_key}": identifier, test_field: test_field)
    end
    let(:payload_after) { fake_model_class.last.as_json }

    include_examples 'model CRUD'
  end

  context 'when model has custom uuid primary_key' do
    let(:fake_model_class) { Uuid::FakeModel }
    let(:outbox_class) { Uuid::Outbox }
    let(:identifier) { 'bbdfa748-d1c4-4dc0-98d2-2246f10b5c9a' }
    let(:new_identifier) { '1fad4ed8-8d86-4661-b113-621f271a6956' }
    let(:test_field) { 'test' }
    let(:fake_model_instance) do
      fake_model_class.new("#{fake_model_class.primary_key}": identifier, test_field: test_field)
    end
    let(:payload_after) { fake_model_class.last.as_json }

    include_examples 'model CRUD'
  end
end
