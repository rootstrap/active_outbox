# frozen_string_literal: true

require 'active_outbox/adapter_helper'
require 'active_outbox/errors'
require 'active_outbox/generators/active_outbox_generator'
require 'active_outbox/outboxable'
require 'active_outbox/railtie' if defined?(Rails::Railtie)
require 'dry-configurable'

module ActiveOutbox
  extend Dry::Configurable

  setting :adapter, default: :sqlite
  setting :outbox_mapping, default: {}
end
