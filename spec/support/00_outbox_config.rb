ActiveOutbox.configure do |config|
  config.outbox_mapping.merge!(
    'default' => 'Outbox'
  )
end
