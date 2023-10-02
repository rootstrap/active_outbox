# frozen_string_literal: true

require 'rails'
require 'rails/generators'
require 'rails/generators/active_record'
require 'pry'

class ActiveOutboxGenerator < ActiveRecord::Generators::Base
  include ActiveOutbox::AdapterHelper
  source_root File.expand_path('templates', __dir__)

  class_option :root_components_path, type: :string

  def create_migration_files
    migration_path = "#{root_path}/db/migrate"
    migration_template(
      'migration.rb',
      "#{migration_path}/outbox_create_#{table_name}.rb",
      migration_version: migration_version
    )
  end

  def root_path
    options['root_components_path'] || Rails.root
  end

  def migration_version
    "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
  end

  def table_name
    "#{name}_outboxes"
  end
end
