# frozen_string_literal: true

module ActiveOutbox
  module Outboxable
    extend ActiveSupport::Concern

    included do
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
      assign_outbox_event(options)
      super(**options, &block)
    end

    def save!(**options, &block)
      assign_outbox_event(options)
      super(**options, &block)
    end

    private

    def assign_outbox_event(options)
      @outbox_event = options[:outbox_event].underscore.upcase if options[:outbox_event].present?
    end

    def create_outbox!(action, event_name)
      outbox = outbox_model.new(
        aggregate: self.class.name,
        aggregate_identifier: try(:identifier) || id,
        event: @outbox_event || event_name,
        identifier: SecureRandom.uuid,
        payload: formatted_payload(action)
      )
      @outbox_event = nil

      handle_outbox_errors(outbox) if outbox.invalid?
      outbox.save!
    end

    def outbox_model
      module_parent = self.class.module_parent

      unless module_parent.const_defined?('OUTBOX_MODEL')
        outbox_model = outbox_model_name!.safe_constantize
        module_parent.const_set('OUTBOX_MODEL', outbox_model)
      end

      module_parent.const_get('OUTBOX_MODEL')
    end

    def outbox_model_name!
      namespace_outbox_mapping || default_outbox_mapping || raise(OutboxClassNotFoundError)
    end

    def namespace_outbox_mapping
      namespace = self.class.name.split('/').first

      ActiveOutbox.config.outbox_mapping[namespace&.underscore]
    end

    def default_outbox_mapping
      ActiveOutbox.config.outbox_mapping['default']
    end

    def handle_outbox_errors(outbox)
      outbox.errors.each do |error|
        errors.import(error, attribute: "outbox.#{error.attribute}")
      end
    end

    def formatted_payload(action)
      payload = construct_payload(action)
      AdapterHelper.postgres? ? payload : payload.to_json
    end

    def construct_payload(action)
      case action
      when :create
        { before: nil, after: as_json }
      when :update
        changes = previous_changes.transform_values(&:first)
        { before: as_json.merge(changes), after: as_json }
      when :destroy
        { before: as_json, after: nil }
      else
        raise ActiveRecord::RecordNotSaved.new("Failed to create Outbox payload for #{self.class.name}: #{identifier}",
                                               self)
      end
    end
  end
end
