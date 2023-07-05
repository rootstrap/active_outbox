# frozen_string_literal: true

module ActiveOutbox
  class OutboxConfigurationError < StandardError; end
  class OutboxClassNotFoundError < OutboxConfigurationError
    def message
      <<~MESSAGE
Missing Outbox class definition. Configure mapping in `config/initializers/active_outbox.rb`:

Rails.application.reloader.to_prepare do
  ActiveOutbox.configure do |config|
    config.outbox_mapping = {
      'default' => <outbox model name>
    }
  end
end
MESSAGE
    end
  end
end
