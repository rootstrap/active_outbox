# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  ActiveOutbox.configure do |config|
    # To configure which Outbox class maps to which domain
    # See https://github.com/rootstrap/active_outbox#advanced-usage for advanced examples
    config.outbox_mapping = {
      'default' => 'Outbox'
    }

    # Configure database adapter
    # config.adapter = :postgresql
  end
end
