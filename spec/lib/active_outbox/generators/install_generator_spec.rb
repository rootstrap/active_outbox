# frozen_string_literal: true

require 'spec_helper'
require 'generator_spec'
require 'tempfile'
require 'generators/active_outbox/install/install_generator'

RSpec.describe ActiveOutbox::Generators::InstallGenerator, type: :generator do
  destination File.expand_path('tmp', __dir__)

  let(:root) { double }
  let(:initializer_file_path) { "#{destination_root}/config/initializers/active_outbox.rb" }
  let(:actual_content) { File.read(initializer_file_path) }
  let(:expected_content) do
    <<~FILE
      Rails.application.reloader.to_prepare do
        ActiveOutbox.configure do |config|
          # To configure which Outbox class maps to which domain
          # See https://github.com/rootstrap/active_outbox#advanced-usage for advanced examples
          config.outbox_mapping = {
            'default' => 'Outbox'
          }

          # Configure database adapter
          # config.adapter = :postgresql
        end
      end
    FILE
  end

  before do
    prepare_destination
    allow(Rails).to receive(:root).and_return(root)
    allow(root).to receive(:join).and_return(initializer_file_path)
  end

  after { FileUtils.rm_rf(destination_root) }

  it 'creates the initializer' do
    run_generator
    assert_file initializer_file_path
  end

  it 'creates the correct file' do
    run_generator
    expect(actual_content).to include(expected_content)
  end
end
