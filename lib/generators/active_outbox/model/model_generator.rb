# frozen_string_literal: true

require 'rails'
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
      class_option :component_path,
        type: :string,
        desc: 'Indicates where to create the outbox migration'
      class_option :uuid,
        type: :boolean,
        default: false,
        desc: 'Use UUID to identify aggregate records in events. Defaults to ID'

      def create_migration_file
        migration_path = "#{root_path}/db/migrate"
        migration_template(
          'migration.rb',
          "#{migration_path}/active_outbox_create_#{table_name}.rb",
          migration_version: migration_version
        )

        template('model.rb', "#{root_path}/app/models/#{path_name}.rb")
      end

      def root_path
        path = options['component_path'].blank? ? '' : "/#{options['component_path']}"
        "#{Rails.root}#{path}"
      end

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end

      def table_name
        *namespace, name = model_name.downcase.split('/')
        name = name.blank? ? 'outboxes' : "#{name}_outboxes"
        namespace = namespace.join('_')
        namespace.blank? ? name : "#{namespace}_#{name}"
      end

      def path_name
        name = ''
        *namespace = model_name.downcase.split('/')
        if (model_name.include?('/') && model_name.last != '/' && namespace.length > 1) || !model_name.include?('/')
          name = namespace.pop
        end
        name = name.blank? ? 'outbox' : "#{name}_outbox"
        namespace = namespace.join('/')
        namespace.blank? ? name : "#{namespace}/#{name}"
      end

      def aggregate_identifier_type
        options['uuid'].present? ? ActiveOutbox::AdapterHelper.uuid_type : ActiveOutbox::AdapterHelper.bigint_type
      end
    end
  end
end
