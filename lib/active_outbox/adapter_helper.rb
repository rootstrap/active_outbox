# frozen_string_literal: true

module ActiveOutbox
  module AdapterHelper
    def self.uuid_type
      postgres? ? 'uuid' : 'string'
    end

    def self.json_type
      'jsonb' if postgres?
      'json' if mysql?
      'string'
    end

    def self.postgres?
      ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql'
    end

    def self.mysql?
      ActiveRecord::Base.connection.adapter_name.downcase == 'mysql2'
    end
  end
end
