# frozen_string_literal: true

require 'spec_helper'
require 'generator_spec'
require 'tempfile'

RSpec.describe ActiveOutboxGenerator, type: :generator do
  destination File.expand_path('tmp', __dir__)

  before do
    prepare_destination
    travel_to Time.local(1994)
  end

  after do
    travel_back
    FileUtils.rm_rf(destination_root)
  end

  let(:table_name) { 'custom_table_name' }
  let(:migration_file_path) do
    "#{destination_root}/db/migrate/#{timestamp_of_migration}_outbox_create_#{table_name}_outboxes.rb"
  end
  let(:timestamp_of_migration) { DateTime.now.strftime("%Y%m%d%H%M%S") }

  context 'without root_component_path' do
    before do
      allow(Rails).to receive(:root).and_return(destination_root)
    end

    it 'creates the expected files' do
      run_generator [table_name]
      assert_file migration_file_path
    end
  end

  context 'with root_component_path' do
    it 'creates the expected files' do
      run_generator([table_name, "--root_components_path=#{destination_root}"])
      assert_file migration_file_path
    end
  end

  describe 'migration content' do
    subject(:generate) { run_generator([table_name, "--root_components_path=#{destination_root}"]) }

    let(:actual_content) { File.read(migration_file_path) }

    context 'when is not a postgres migration' do
      let(:expected_content) do
        <<~MIGRATION
          class OutboxCreate#{table_name.camelcase}Outbox < ActiveRecord::Migration[7.0]
            def change
              create_table :#{table_name}_outboxes do |t|
                t.string :identifier, null: false, index: { unique: true }
                t.string :event, null: false
                t.string :payload
                t.string :aggregate, null: false
                t.string :aggregate_identifier, null: false, index: true

                t.timestamps
              end
            end
          end
        MIGRATION
      end

      it 'creates the migration with the correct content' do
        generate
        expect(actual_content).to include(expected_content)
      end
    end

    context 'when it is a postgres migration' do
      before do
        allow(ActiveOutbox::AdapterHelper).to receive(:postgres?).and_return(true)
      end

      let(:expected_content) do
        <<~MIGRATION
          class OutboxCreate#{table_name.camelcase}Outbox < ActiveRecord::Migration[7.0]
            def change
              create_table :#{table_name}_outboxes do |t|
                t.uuid :identifier, null: false, index: { unique: true }
                t.string :event, null: false
                t.jsonb :payload
                t.string :aggregate, null: false
                t.uuid :aggregate_identifier, null: false, index: true

                t.timestamps
              end
            end
          end
        MIGRATION
      end

      it 'creates the migration with the correct content' do
        generate
        expect(actual_content).to include(expected_content)
      end
    end
  end
end
