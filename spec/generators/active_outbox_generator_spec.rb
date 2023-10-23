require 'spec_helper'
require 'generator_spec'
require 'tempfile'

RSpec.describe ActiveOutboxGenerator, type: :generator do
  destination File.expand_path("../../tmp", __FILE__)

  before do
    allow(Rails).to receive(:root).and_return(destination_root)
    prepare_destination
    FileUtils.chmod(0o777, destination_root)
    travel_to Time.local(1994)
  end

  after do
    travel_back
  end

  let(:table_name) { 'custom_table_name' }
  let(:timestamp_of_migration) { Time.now.strftime('%Y%m%d%H%M%S') }
  # Test case to check if the generator creates the expected files
  it 'creates the expected files' do
    run_generator [table_name]
    assert_file "spec/tmp/db/migrate/#{timestamp_of_migration}_outbox_create_#{table_name}_outboxes.rb"
  end
end

