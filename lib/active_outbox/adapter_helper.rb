module ActiveOutbox
  module AdapterHelper
    def self.uuid_type
      postgres? ? 'uuid' : 'string'
    end

    def self.json_type
      postgres? ? 'jsonb' : 'string'
    end

    def self.postgres?
      ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql'
    end
  end
end
