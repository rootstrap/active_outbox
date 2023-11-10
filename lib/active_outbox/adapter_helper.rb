# frozen_string_literal: true

module ActiveOutbox
  module AdapterHelper
    def self.uuid_type
      return 'uuid' if postgres?
      return 'string' if mysql?

      'string'
    end

    def self.json_type
      return 'jsonb' if postgres?
      return 'json' if mysql?

      'string'
    end

    def self.bigint_type
      return 'bigint' if postgres? || mysql?

      'integer'
    end

    def self.postgres?
      ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql'
    end

    def self.mysql?
      ActiveRecord::Base.connection.adapter_name.downcase == 'mysql2'
    end
  end
end
