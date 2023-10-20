# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require 'active_outbox'
require 'active_record'
require 'byebug'
require 'database_cleaner/active_record'
require 'simplecov'

SimpleCov.start 'rails' do
  add_filter 'spec/'
  add_filter '.github/'
  add_filter 'lib/generators/templates/'
  add_filter 'lib/lokalise_rails/version'
end

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

db_config = if ENV['ADAPTER'] == 'postgresql'
              {
                adapter: 'postgresql',
                username: ENV.fetch('POSTGRES_USER', nil),
                host: ENV.fetch('POSTGRES_HOST', nil),
                port: ENV.fetch('POSTGRES_PORT', nil)
              }
            else
              {
                adapter: 'sqlite3',
                database: ':memory:'
              }
            end
ActiveRecord::Base.establish_connection(**db_config)

Outbox = Class.new(ActiveRecord::Base) do
  def self.name
    'Outbox'
  end

  validates_presence_of :identifier, :payload, :aggregate, :aggregate_identifier, :event
end

FakeModel = Class.new(ActiveRecord::Base) do
  def self.name
    'FakeModel'
  end

  include ActiveOutbox::Outboxable
  validates :identifier, presence: true
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include OutboxableTestHelpers

  config.before(:suite) do
    ActiveRecord::Base.connection.create_table :fake_models, if_not_exists: true do |t|
      t.string :identifier, null: false
    end

    ActiveRecord::Base.connection.create_table :outboxes, if_not_exists: true do |t|
      t.send(ActiveOutbox::AdapterHelper.uuid_type, :identifier, null: false, index: { unique: true })
      t.string :event, null: false
      t.send(ActiveOutbox::AdapterHelper.json_type, :payload)
      t.string :aggregate, null: false
      t.send(ActiveOutbox::AdapterHelper.uuid_type, :aggregate_identifier, null: false)

      t.timestamps
    end
  end

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end

RSpec::Matchers.define_negated_matcher :not_change, :change
RSpec::Matchers.define_negated_matcher :exclude, :include
