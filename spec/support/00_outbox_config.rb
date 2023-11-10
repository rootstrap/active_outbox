# frozen_string_literal: true

ActiveOutbox.configure do |config|
  config.outbox_mapping.merge!(
    'id' => 'Id::Outbox',
    'uuid' => 'Uuid::Outbox'
  )
end
