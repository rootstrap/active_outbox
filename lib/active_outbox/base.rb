require 'active_record'

module ActiveOutbox
  class Base < ActiveRecord::Base
    self.abstract_class = true
  end
end
