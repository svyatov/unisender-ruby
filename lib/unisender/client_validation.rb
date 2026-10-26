# frozen_string_literal: true

module Unisender
  # The same named preparation is available without crossing the transport seam.
  class Client
    def validate!(operation, records: nil, **params)
      if records
        raise ArgumentError, "Records require import_contacts" unless operation == :import_contacts

        params = validation_import(params, records)
      end
      validation_dispatch(operation, params)
    end

    private

    def validation_dispatch(operation, params)
      case operation
      when :send_campaign then validate_campaign(params)
      when :track_events then validate_events(params)
      else validate_named(operation, params)
      end
    end

    def validate_named(operation, params)
      wire = OperationContracts.wire_name(operation)
      OperationContracts.validate_keys!(wire, params)
      params = validation_page(operation, params) if PaginatedOperations.supports?(operation)
      Form.encode(prepare(wire, validation_parameters(wire, params), comma: OperationContracts.comma_fields(wire)))
      true
    rescue ValidationError => e
      raise e.with_operation(wire || operation.to_s), cause: nil
    end

    def validation_page(operation, params)
      params = params.compact.merge(limit: params[:limit] || 100)
      PaginatedOperations.validate_controls(operation, params)
      params
    end

    # rubocop:disable-next Naming/PredicateMethod -- Validation returns true or raises.
    def validate_campaign(params)
      raise ValidationError.new(field: "parameters", code: :unknown_keyword) unless (params.keys - %i[message
                                                                                                      campaign]).empty?

      # @type var empty: params
      empty = {}
      message = validation_keywords(params[:message], "message")
      campaign = validation_keywords(params.fetch(:campaign, empty), "campaign")
      campaign_parameters(message, campaign)
      true
    end

    def validation_keywords(value, field)
      raise ValidationError.new(field:, code: :invalid_type) unless value.is_a?(Hash)

      value.to_h do |key, item|
        raise ValidationError.new(field:, code: :unknown_keyword) unless key.is_a?(Symbol)

        [key, item]
      end
    end

    def validate_events(params)
      unless params.keys == [:events] && params[:events].is_a?(Array)
        raise ValidationError.new(field: "events", code: :invalid_type)
      end

      events = params.fetch(:events) # : Array[params]
      EventPayload.encode(events)
      true
    rescue ValidationError => e
      raise e.with_operation("track_events"), cause: nil
    end

    def validation_import(params, records)
      raise ValidationError.new(field: "records", code: :conflicting_input) if params[:field_names] || params[:data]

      rows = RecordRows.bounded(records)
      data = rows.to_a
      params.merge(field_names: rows.field_names, data:)
    end

    def validation_parameters(wire, params)
      case wire
      when "subscribe"
        params.except(:email).merge(fields: Inputs.contact_fields(params[:fields], params[:email]))
      when "exclude", "unsubscribe" then ContactInputs.contact_selector(params, wire)
      when "getContactCount" then validation_count(params)
      when "setHook"
        params.merge(events: hook_events(params[:events], params[:max_parallel]))
      else params
      end
    end

    def validation_count(params)
      filters = ContactInputs.count_filters(params[:params], params[:tag_id], params[:contact_type], params[:search])
      params.except(:tag_id, :contact_type, :search).merge(params: filters)
    end
  end
end
