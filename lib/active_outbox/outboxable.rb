# frozen_string_literal: true

module ActiveOutbox
  module Outboxable
    extend ActiveSupport::Concern

    included do |base|
      base.extend(ClassMethods)
      *namespace, klass = name.underscore.upcase.split('/')
      namespace = namespace.reverse.join('.')

      module_parent.const_set('Events', Module.new) unless module_parent.const_defined?('Events')

      { create: 'CREATED', update: 'UPDATED', destroy: 'DESTROYED' }.each do |key, value|
        const_name = "#{klass}_#{value}"

        unless module_parent::Events.const_defined?(const_name)
          module_parent::Events.const_set(const_name, "#{const_name}#{namespace.blank? ? '' : '.'}#{namespace}")
        end

        event_name = module_parent::Events.const_get(const_name)

        send("after_#{key}") { create_outbox!(key, event_name) }
      end
    end

    def save(**options, &block)
      if options[:outbox_event].present?
        @outbox_event = options[:outbox_event].underscore.upcase
      end

      super(**options, &block)
    end

    def save!(**options, &block)
      if options[:outbox_event].present?
        @outbox_event = options[:outbox_event].underscore.upcase
      end

      super(**options, &block)
    end

    module ClassMethods
      def parent_module_name
        module_parent == Object ? '' : module_parent.name
      end

      def outbox_model
        @outbox_model ||= ActiveOutbox::Base.subclasses.find do |klass|
          klass.name.include?(parent_module_name)
        end
      end
    end

    private

    def create_outbox!(action, event_name)
      outbox = self.class.outbox_model.new(
        aggregate: self.class.name,
        aggregate_identifier: try(:identifier) || id,
        event: @outbox_event || event_name,
        identifier: SecureRandom.uuid,
        payload: payload(action)
      )
      @outbox_event = nil

      if outbox.invalid?
        outbox.errors.each do |error|
          self.errors.import(error, attribute: "outbox.#{error.attribute}")
        end
      end

      outbox.save!
    end

    def payload(action)
      payload = { before: nil, after: nil }
      case action
      when :create
        payload[:after] = as_json
      when :update
        # previous_changes => { 'name' => ['bob', 'robert']  }
        changes = previous_changes.transform_values(&:first)
        payload[:before] = as_json.merge(changes)
        payload[:after] = as_json
      when :destroy
        payload[:before] = as_json
      else
        raise ActiveRecord::RecordNotSaved.new("Failed to create Outbox payload for #{self.class.name}: #{identifier}", self)
      end
      payload
    end
  end
end
