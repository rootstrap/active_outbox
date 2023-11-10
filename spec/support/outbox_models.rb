# frozen_string_literal: true

Object.const_set('Uuid', Module.new)
Object.const_set('Id', Module.new)
Uuid::Outbox = Class.new(ActiveRecord::Base) do
  def self.name
    'Uuid::Outbox'
  end

  def self.table_name
    'uuid_outboxes'
  end

  validates_presence_of :identifier, :payload, :aggregate, :aggregate_identifier, :event
end

Id::Outbox = Class.new(ActiveRecord::Base) do
  def self.name
    'Id::Outbox'
  end

  def self.table_name
    'id_outboxes'
  end

  validates_presence_of :identifier, :payload, :aggregate, :aggregate_identifier, :event
end

Uuid::FakeModel = Class.new(ActiveRecord::Base) do
  def self.name
    'Uuid::FakeModel'
  end

  def self.table_name
    'uuid_fake_models'
  end

  validates_presence_of :test_field
  include ActiveOutbox::Outboxable
end

Id::FakeModel = Class.new(ActiveRecord::Base) do
  def self.name
    'Id::FakeModel'
  end

  def self.table_name
    'id_fake_models'
  end

  validates_presence_of :test_field
  include ActiveOutbox::Outboxable
end

def create_migrations
  id_migrations
  uuid_migrations
end

def id_migrations
  ActiveRecord::Base.connection.create_table :id_fake_models, if_not_exists: true do |t|
    t.string :test_field
  end

  ActiveRecord::Base.connection.create_table :id_outboxes, if_not_exists: true do |t|
    t.send(ActiveOutbox::AdapterHelper.uuid_type, :identifier, null: false, index: { unique: true })
    t.string :event, null: false
    t.send(ActiveOutbox::AdapterHelper.json_type, :payload)
    t.string :aggregate, null: false
    t.integer :aggregate_identifier, null: false

    t.timestamps
  end
end

def uuid_migrations
  ActiveRecord::Base.connection.create_table :uuid_fake_models,
    if_not_exists: true,
    primary_key: :identifier,
    id: :uuid do |t|
    t.string :test_field
  end

  ActiveRecord::Base.connection.create_table :uuid_outboxes, if_not_exists: true do |t|
    t.send(ActiveOutbox::AdapterHelper.uuid_type, :identifier, null: false, index: { unique: true })
    t.string :event, null: false
    t.send(ActiveOutbox::AdapterHelper.json_type, :payload)
    t.string :aggregate, null: false
    t.send(ActiveOutbox::AdapterHelper.uuid_type, :aggregate_identifier, null: false)

    t.timestamps
  end
end
