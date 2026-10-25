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
      wire, required, allowed, = definition(method)
      raise ArgumentError, "Unknown operation parameter" unless params.keys.all? { |key| allowed.include?(key) }

      Validation.required!(params, required.map(&:to_s))
      Validation.operation!(wire, params)
      client.request(wire, params:)
    end

    def self.page_limit(method)
      definition(method).last
    end

    def self.definition(method)
      DEFINITIONS.fetch(method.to_s) { raise ArgumentError, "Unsupported paginated method" }
    end
    private_class_method :definition
  end
end
