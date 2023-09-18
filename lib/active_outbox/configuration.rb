# frozen_string_literal: true

module ActiveOutbox
  class << self
    attr_accessor :configuration

    def configuration
      @configuration ||= ActiveOutbox::Configuration.new
    end

    def reset
      @configuration = ActiveOutbox::Configuration.new
    end

    def configure
      yield(configuration)
    end
  end

  class Configuration
    attr_accessor :adapter, :outbox_mapping

    def initialize
      @adapter = :sqlite
      @outbox_mapping = {}
    end
  end
end
