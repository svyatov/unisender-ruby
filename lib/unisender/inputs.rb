# frozen_string_literal: true

module Unisender
  # Local structural failures omit parameter values from diagnostics.
  class ValidationError < ArgumentError
    attr_reader :field, :code, :operation, :index

    def initialize(field:, code:, operation: nil, index: nil)
      @field = field
      @code = code
      @operation = operation
      @index = index
      super("Invalid parameter #{field}: #{code}")
    end
  end

  # Converts convenience values only on the named-operation path.
  module Inputs
    MODES = {
      double_optin: { request_confirmation: 0, already_confirmed: 3, confirm_if_needed: 4 }.freeze,
      overwrite: { preserve: 0, replace: 1, update: 2 }.freeze
    }.freeze
    MINUTES = %w[getMessages listMessages getTemplates listTemplates].freeze
    SECONDS = %w[getCampaigns createCampaign async/getCampaignDeliveryStats].freeze
    DATES = %i[date_from date_to from to start_time changed_since].freeze

    def self.normalize(method, params)
      result = params.dup
      MODES.each { |key, modes| result[key] = mode(result[key], modes, key) } if method == "subscribe"
      format = timestamp_format(method)
      return result unless format

      DATES.each { |key| result[key] = timestamp(result[key], format, key) if result.key?(key) }
      result
    end

    def self.timestamp_format(method)
      return "%Y-%m-%d %H:%M" if MINUTES.include?(method)
      return "%Y-%m-%d %H:%M:%S" if SECONDS.include?(method)

      nil
    end

    def self.mode(value, modes, field)
      return nil if value.nil?
      return modes.fetch(value) if value.is_a?(Symbol) && modes.key?(value)
      return value if value.is_a?(Integer) && modes.value?(value)

      raise ValidationError.new(field: field.to_s, code: :invalid_mode, operation: "subscribe")
    end

    def self.timestamp(value, format, field)
      return value if value.nil? || value.is_a?(String)
      return value.getutc.strftime(format) if value.is_a?(Time)

      raise ValidationError.new(field: field.to_s, code: :invalid_timestamp)
    end

    def self.contact_fields(fields, email)
      # @type var result: params
      result = fields ? fields.dup : {}
      names = result.keys.map(&:to_s)
      raise ValidationError.new(field: "fields", code: :duplicate_key, operation: "subscribe") if names.uniq != names

      merge_email(result, email) if email
      validate_email(result)
      result
    end

    def self.merge_email(result, email)
      existing = result[:email] || result["email"]
      if existing && existing != email
        raise ValidationError.new(field: "fields.email", code: :conflicting_value, operation: "subscribe")
      end

      result.delete(:email)
      result["email"] = email
    end

    def self.validate_email(result)
      address = result[:email] || result["email"]
      return if address.is_a?(String) && !address.empty?

      raise ValidationError.new(field: "fields.email", code: :required, operation: "subscribe")
    end
  end
end
