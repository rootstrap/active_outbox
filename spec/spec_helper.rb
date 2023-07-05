ENV['RAILS_ENV'] ||= 'test'

require 'active_record'
require 'active_outbox'
require 'byebug'
require 'simplecov'

SimpleCov.start 'rails' do
  add_filter 'spec/'
  add_filter '.github/'
  add_filter 'lib/generators/templates/'
  add_filter 'lib/lokalise_rails/version'
end

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)
