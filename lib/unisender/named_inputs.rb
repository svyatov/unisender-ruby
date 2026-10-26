# frozen_string_literal: true

module Unisender
  # Closed choices are validated only for named operations.
  module NamedInputs
    # @type var empty: Hash[Symbol, Array[String]]
    empty = {}
    EMPTY_ENUMS = empty.freeze
    FLAGS = {
      "setHook" => %i[single_event],
      "getContact" => %i[include_lists include_fields include_details],
      "createCampaign" => %i[track_read track_links track_ga],
      "createEmailMessage" => %i[generate_text], "sendEmail" => %i[track_read track_links error_checking],
      "importContacts" => %i[overwrite_tags overwrite_lists], "getVisitedLinks" => %i[group],
      "getSubscriberNotes" => %i[is_pinned]
    }.transform_values(&:freeze).freeze
    ENUMS = {
      "setHook" => { event_format: %w[json_post json_post_gzip http_get], status: %w[active disabled] },
      "getTemplates" => { type: %w[user system].freeze }.freeze,
      "listTemplates" => { type: %w[user system].freeze }.freeze,
      "exclude" => { contact_type: %w[email phone].freeze }.freeze,
      "unsubscribe" => { contact_type: %w[email phone].freeze }.freeze,
      "getSubscriberNotes" => { order_type: %w[ASC DESC].freeze,
                                order_by: %w[created_at updated_at pinned_at].freeze }.freeze
    }.freeze

    def self.normalize(method, params)
      FLAGS.fetch(method, []).each { |key| flag!(key, params[key], method) }
      ENUMS.fetch(method, EMPTY_ENUMS).each do |key, choices|
        value = params[key]
        params[key] = choice(value, key, choices, method) unless value.nil?
      end
      params
    end

    def self.flag!(key, value, operation)
      return if value.nil? || value == true || value == false
      return if value.is_a?(Integer) && (0..1).cover?(value)

      raise ValidationError.new(field: key.to_s, code: :invalid_flag, operation:)
    end

    def self.choice(value, key, choices, operation)
      text = value.to_s
      text = text.upcase if key == :order_type
      return text if (value.is_a?(String) || value.is_a?(Symbol)) && choices.include?(text)

      raise ValidationError.new(field: key.to_s, code: :invalid_choice, operation:)
    end
  end
end
