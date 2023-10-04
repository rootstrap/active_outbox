# frozen_string_literal: true

class OutboxCreate<%= table_name.camelize.singularize %> < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table :<%= table_name %> do |t|
      t.<%= uuid_type %> :identifier, null: false, index: { unique: true }
      t.string :event, null: false
      t.<%= json_type %> :payload
      t.string :aggregate, null: false
      t.<%= uuid_type %> :aggregate_identifier, null: false, index: true

      t.timestamps
    end
  end
end
