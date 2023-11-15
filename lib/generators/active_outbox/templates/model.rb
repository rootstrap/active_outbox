# frozen_string_literal: true

class <%= path_name.camelize %> < ApplicationRecord
  validates_presence_of :identifier, :payload, :aggregate, :aggregate_identifier, :event
end
