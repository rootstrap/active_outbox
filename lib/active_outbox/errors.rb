# frozen_string_literal: true

module ActiveOutbox
  class OutboxConfigurationError < StandardError; end
  class OutboxClassNotFoundError < OutboxConfigurationError
    def message
      <<~MESSAGE
Missing Outbox class definition in module. Use `rails generate outbox <outbox model name>`.
Define default class in `config/initializers/active_outbox.rb`:

Rails.application.reloader.to_prepare do
  ActiveOutbox.configure do |config|
    config.outbox_mapping = {
      'Default' => <outbox model name>,
      'Meetings' => 'Meetings::Outbox'
    }
  end
end
MESSAGE
    end
  end
end
