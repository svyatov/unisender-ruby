# frozen_string_literal: true

module Unisender
  # Structural checks only. Account permissions and business rules belong to the API.
  module Validation
    def self.operation!(method, params)
      case method
      when "importContacts" then import!(params)
      when "getTemplate" then template!(params)
      when "createEmailMessage" then email_message!(params)
      when "createCampaign" then campaign!(params)
      end
    end

    def self.email_message!(params)
      required!(params, %w[subject body]) if params[:template_id].nil? && params[:system_template_id].nil?
    end

    def self.campaign!(params)
      return unless params[:contacts] && params[:contacts_url]

      raise ArgumentError,
            "contacts and contacts_url are mutually exclusive"
    end

    def self.template!(params)
      return unless params[:template_id].nil? && params[:system_template_id].nil?

      raise ArgumentError, "Provide template_id or system_template_id"
    end

    def self.import!(params)
      fields = params[:field_names]
      unless fields.is_a?(Array) && fields.all?(String) && fields.include?("email") && fields.uniq == fields
        raise ArgumentError, "field_names must contain unique column names including email"
      end

      rows!(params[:data], fields.size)
    end

    def self.rows!(rows, width)
      unless rows.is_a?(Array) && (1..500).cover?(rows.size) && rows.all? do |row|
        row.is_a?(Array) && row.size == width
      end
        raise ArgumentError, "data must contain 1 to 500 rows matching field_names"
      end
    end

    def self.required!(params, names)
      names.each do |name|
        value = params[name.to_sym]
        raise ArgumentError, "Missing required parameter: #{name}" if missing?(value)
      end
    end

    def self.missing?(value)
      case value
      when nil then true
      when String, Array, Hash then value.empty?
      else false
      end
    end

    def self.comma_list(value)
      unless value.all? { |item| item.is_a?(String) || item.is_a?(Integer) }
        raise ArgumentError, "Comma-separated lists require strings or integers"
      end

      value.join(",")
    end
  end
end
