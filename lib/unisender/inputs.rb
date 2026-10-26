# frozen_string_literal: true

module Unisender
  # Local structural failures omit parameter values from diagnostics.
  class ValidationError < ArgumentError
    attr_reader :field, :code, :operation, :index, :expected_type, :actual_type

    # rubocop:disable-next Metrics/ParameterLists -- Structured diagnostic fields remain explicit.
    def initialize(field:, code:, operation: nil, index: nil, expected_type: nil, actual_type: nil)
      @field = Diagnostics.input_path(field)
      @code = code
      @operation = operation
      @index = index
      @expected_type = expected_type
      @actual_type = actual_type
      super("Invalid parameter #{@field}: #{code}")
    end

    alias path field

    def diagnostics
      Diagnostics.for_error(self)
    end

    def documentation_url
      Diagnostics::URLS[@operation.to_s]
    end

    def with_operation(operation)
      @operation = Error.safe_operation(operation)
      self
    end

    def category
      :invalid_argument
    end

    def recovery_hint
      "Check the operation parameters."
    end

    def transient?
      false
    end

    def safe_to_retry?
      false
    end
  end

  # Converts convenience values only on the named-operation path.
  module Inputs
    MODES = {
      double_optin: { request_confirmation: 0, already_confirmed: 3, confirm_if_needed: 4 }.freeze,
      overwrite: { preserve: 0, replace: 1, update: 2 }.freeze
    }.freeze
    MINUTES = %w[getMessages listMessages getTemplates listTemplates createCampaign].freeze
    SECONDS = %w[getCampaigns async/getCampaignDeliveryStats].freeze
    DATES = %i[date_from date_to from to start_time changed_since].freeze

    def self.normalize(method, params)
      result = operation_values(method, NamedInputs.normalize(method, attachment_parameters(params)))
      format = timestamp_format(method)
      return result unless format

      DATES.each { |key| result[key] = timestamp(result[key], format, key) if result.key?(key) }
      result
    end

    def self.operation_values(method, result)
      case method
      when "sendSms" then result[:phone] = SmsInputs.phone(result[:phone])
      when "sendEmail" then result = MailInputs.normalize(result)
      when "createCampaign" then schedule_timezone!(result)
      when "subscribe" then MODES.each { |key, modes| result[key] = mode(result[key], modes, key) }
      end
      result
    end

    def self.schedule_timezone!(params)
      return unless params[:start_time].is_a?(Time)

      unless params[:timezone].nil? || params[:timezone] == "UTC"
        raise ValidationError.new(field: "timezone", code: :conflicting_input)
      end

      params[:timezone] = "UTC"
    end

    def self.attachment_parameters(params)
      result = params.dup
      result[:attachments] = attachments(result[:attachments]) if result.key?(:attachments)
      result
    end

    def self.attachments(value)
      return value if value.nil? || value.is_a?(Hash)

      output = {} # : Hash[String, parameter]
      attachment_items(value).each do |item|
        raise ValidationError.new(field: "attachments", code: :duplicate_filename) if output.key?(item.filename)

        output[item.filename] = item.bytes
      end
      output
    end

    def self.attachment_items(value)
      items = value.is_a?(Attachment) ? [value] : value
      raise ValidationError.new(field: "attachments", code: :invalid_type) unless items.is_a?(Array)

      items.map do |item|
        raise ValidationError.new(field: "attachments", code: :invalid_type) unless item.is_a?(Attachment)

        item
      end
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
      validate_email_alias(email)
      unless fields.nil? || fields.is_a?(Hash)
        raise ValidationError.new(field: "fields", code: :invalid_type, operation: "subscribe")
      end

      # @type var result: params
      result = fields ? fields.dup : {}
      names = result.keys.map(&:to_s)
      raise ValidationError.new(field: "fields", code: :duplicate_key, operation: "subscribe") if names.uniq != names

      merge_email(result, email) if email
      validate_email(result)
      result
    end

    def self.validate_email_alias(email)
      return if email.nil? || email.is_a?(String)

      raise ValidationError.new(field: "email", code: :invalid_type, operation: "subscribe",
                                expected_type: "String", actual_type: Diagnostics.type_name(email))
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

  # SMS numbers remain strings and share one bounded recipient list.
  module SmsInputs
    def self.phone(value)
      text = case value
             when Array then Validation.comma_list(value, field: "phone")
             when String then value
             else raise ValidationError.new(field: "phone", code: :invalid_type)
             end
      phones = text.split(",", -1)
      unless (1..150).cover?(phones.size) && phones.none? { |phone| phone.strip.empty? }
        raise ValidationError.new(field: "phone", code: :invalid_count)
      end

      text
    end
  end

  # Contact selectors and filters keep their wire forms behind named inputs.
  module ContactInputs
    def self.contact_selector(params, operation)
      selected = params.slice(:email, :phone).compact
      return params.slice(:contact_type, :contact, :list_ids) if selected.empty?

      validate_selector(params, selected, operation)
      kind = selected.key?(:email) ? :email : :phone
      { contact_type: kind.to_s, contact: selected.fetch(kind), list_ids: params[:list_ids] }
    rescue ValidationError => e
      raise e.with_operation(operation), cause: nil
    end

    def self.validate_selector(params, selected, operation)
      if selected.size != 1 || params[:contact_type] || params[:contact]
        raise ValidationError.new(field: "contact", code: :conflicting_input, operation:)
      end

      value = selected.values.fetch(0)
      unless value.is_a?(String) && !value.empty?
        raise ValidationError.new(field: "contact", code: :invalid_contact, operation:)
      end

      Validation.required!(params, %w[list_ids])
    end

    def self.count_filters(params, tag_id, contact_type, search)
      params = filter_container(params)
      validate_filters(tag_id, search)
      if params && [tag_id, contact_type, search].any?
        raise ValidationError.new(field: "params", code: :conflicting_input, operation: "getContactCount")
      end
      return params if params

      type = count_contact_type(contact_type)
      raise ValidationError.new(field: "contact_type", code: :required, operation: "getContactCount") if search && !type

      { tagId: tag_id, type:, search: }.compact
    end

    def self.filter_container(value)
      return value if value.nil? || value.is_a?(Hash)

      raise ValidationError.new(field: "params", code: :invalid_type, operation: "getContactCount")
    end

    def self.validate_filters(tag_id, search)
      if !tag_id.nil? && !tag_id.is_a?(String) && !tag_id.is_a?(Integer)
        raise ValidationError.new(field: "tag_id", code: :invalid_type, operation: "getContactCount")
      end
      return if search.nil? || search.is_a?(String)

      raise ValidationError.new(field: "search", code: :invalid_type, operation: "getContactCount")
    end

    def self.count_contact_type(value)
      return nil if value.nil?
      return "address" if %w[email address].include?(value.to_s)
      return "phone" if value.to_s == "phone"

      raise ValidationError.new(field: "contact_type", code: :invalid_choice, operation: "getContactCount")
    end
  end
end
