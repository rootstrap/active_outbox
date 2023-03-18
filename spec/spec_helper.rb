ENV['RAILS_ENV'] ||= 'test'

require 'active_record'
require 'active_outbox'
require 'byebug'
require 'simplecov'

SimpleCov.start

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)
