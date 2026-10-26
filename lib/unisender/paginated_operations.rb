# frozen_string_literal: true

module Unisender
  # Shared contracts for the operations that support offset pagination.
  module PaginatedOperations
    # @type var empty: Array[Symbol]
    empty = []
    empty.freeze
    # @type var definitions: Hash[String, [String, Array[Symbol], Array[Symbol], Integer?]]
    definitions = {
      "get_campaigns" => ["getCampaigns", %i[from].freeze, %i[from to limit offset].freeze, 10_000],
      "get_messages" => ["getMessages", %i[date_from date_to].freeze, %i[date_from date_to limit offset].freeze, 100],
      "list_messages" => ["listMessages", %i[date_from date_to].freeze, %i[date_from date_to limit offset].freeze, 100],
      "get_templates" => ["getTemplates", empty, %i[type date_from date_to limit offset].freeze, 100],
      "list_templates" => ["listTemplates", empty, %i[type date_from date_to limit offset].freeze, 100],
      "get_sender_domain_list" => ["getSenderDomainList", %i[username].freeze,
                                   %i[username domain limit offset].freeze, 100],
      "get_subscriber_notes" => ["getSubscriberNotes", %i[subscriber_id].freeze,
                                 %i[subscriber_id limit offset order_type order_by is_pinned].freeze, nil]
    }
    DEFINITIONS = definitions.transform_values(&:freeze).freeze
    private_constant :DEFINITIONS

    def self.call(client, method, params)
      params = params.compact
      params = params.merge(limit: params.fetch(:limit, 100))
      wire = validate(method, params)
      params = Inputs.normalize(wire, params)
      validate_controls(method, params)
      response = client.invoke(wire, params) # : CollectionResponse[Record]
      PageResponse.new(response, client:, method: method.to_s, params:)
    rescue ValidationError => e
      raise e.with_operation(wire_name(method)), cause: nil
    end

    def self.validate(method, params)
      wire, required, allowed, = definition(method)
      unless params.keys.all? do |key|
        allowed.include?(key)
      end
        raise ValidationError.new(field: "parameters", code: :unknown_keyword,
                                  operation: wire)
      end

      Validation.required!(params, required.map(&:to_s))
      Validation.operation!(wire, params)
      wire
    end

    def self.page_limit(method)
      definition(method).last
    end

    def self.wire_name(method)
      definition(method).first
    end

    def self.validate_controls(method, params)
      limit = params.fetch(:limit, 100)
      maximum = page_limit(method)
      unless limit.is_a?(Integer) && limit.positive? && (!maximum || limit <= maximum)
        raise ValidationError.new(field: "limit", code: :out_of_range)
      end

      offset = params.fetch(:offset, 0)
      raise ValidationError.new(field: "offset", code: :out_of_range) unless offset.is_a?(Integer) && offset >= 0
    end

    def self.definition(method)
      DEFINITIONS.fetch(method.to_s) { raise ArgumentError, "Unsupported paginated method" }
    end
    private_class_method :definition
  end
end
