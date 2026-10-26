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

      raise ValidationError.new(field: "contacts", code: :conflicting_input)
    end

    def self.template!(params)
      return unless params[:template_id].nil? && params[:system_template_id].nil?

      raise ValidationError.new(field: "template_id", code: :required_alternative)
    end

    def self.import!(params)
      fields = params[:field_names]
      unless fields.is_a?(Array) && fields.all?(String) && fields.include?("email") && fields.uniq == fields
        raise ValidationError.new(field: "field_names", code: :invalid_columns)
      end

      rows!(params[:data], fields.size)
    end

    def self.rows!(rows, width)
      unless rows.is_a?(Array) && (1..500).cover?(rows.size) && rows.all? do |row|
        row.is_a?(Array) && row.size == width
      end
        raise ValidationError.new(field: "data", code: :invalid_rows)
      end
    end

    def self.required!(params, names)
      names.each do |name|
        value = params[name.to_sym]
        raise ValidationError.new(field: name, code: :required) if missing?(value)
      end
    end

    def self.missing?(value)
      case value
      when nil then true
      when String, Array, Hash then value.empty?
      else false
      end
    end

    def self.comma_list(value, field: "parameters")
      value.each_with_index do |item, index|
        next if item.is_a?(String) || item.is_a?(Integer)

        raise ValidationError.new(field: "#{field}[#{index}]", code: :invalid_list,
                                  expected_type: "String or Integer", actual_type: Diagnostics.type_name(item))
      end

      value.join(",")
    end
  end
end
