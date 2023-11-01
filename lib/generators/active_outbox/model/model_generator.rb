require 'rails/generators/active_record'
require 'rails/generators/base'
require 'rails/generators/migration'

module ActiveOutbox
  module Generators
    class ModelGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __dir__)

      include ActiveOutbox::AdapterHelper
      include Rails::Generators::Migration

      class << self
        delegate :next_migration_number, to: ActiveRecord::Generators::Base
      end

      desc 'Creates the Outbox model migration'

      argument :model_name, type: :string, default: ''
      class_option :component_path, type: :string, desc: 'Indicates where to create the outbox migration'

      def create_migration_file
        migration_path = "#{root_path}/db/migrate"
        migration_template(
          'migration.rb',
          "#{migration_path}/active_outbox_create_#{table_name}.rb",
          migration_version: migration_version
        )
      end

      def root_path
        options['component_path'] || Rails.root
      end

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end

      def table_name
        model_name.blank? ? 'outboxes' : "#{model_name}_outboxes"
      end
    end
  end
end
