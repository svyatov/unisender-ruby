# frozen_string_literal: true

module Unisender
  # Named input types are structural; account rules remain server decisions.
  module InputTypes
    # @type var kinds: Hash[String, Module]
    kinds = { "string" => String, "integer" => Integer, "float" => Float, "symbol" => Symbol,
              "hash" => Hash, "time" => Time, "attachment" => Attachment, "enumerable" => Enumerable }
    KINDS = kinds.freeze

    def self.validate!(value, types, field)
      arrays = types.grep(/\Aarray:/)
      if value.is_a?(Array) && !arrays.empty?
        elements = arrays.map { |type| type.delete_prefix("array:") }
        value.each_with_index { |item, index| validate!(item, elements, "#{field}[#{index}]") }
      elsif types.none? { |type| accepts?(value, type) }
        raise ValidationError.new(field:, code: :invalid_type)
      end
    end

    def self.accepts?(value, type)
      return true if type == "parameter"
      return [true, false].include?(value) if type == "boolean"

      kind = KINDS[type]
      kind ? value.is_a?(kind) : false
    end
  end
end
