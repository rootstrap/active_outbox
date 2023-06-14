require 'active_outbox/base'
require 'active_outbox/configuration'
require 'active_outbox/outboxable'
require 'active_outbox/generators/outbox_generator'

module ActiveOutbox
  class << self
    attr_accessor :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def reset
      @configuration = Configuration.new
    end

    def configure
      yield(configuration)
    end
  end

  def configuration
    @configuration ||= Configuration.new
  end
end
