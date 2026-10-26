# frozen_string_literal: true

module Unisender
  # Named mail headers merge without silently replacing caller-supplied values.
  module MailInputs
    def self.normalize(params)
      extra = headers(params)
      result = params.except(:reply_to, :priority)
      result[:headers] = merge(params[:headers], extra) unless extra.empty?
      result
    end

    def self.headers(params)
      { "Reply-To" => header(params[:reply_to]), "Priority" => header(params[:priority]) }.compact
    end

    def self.header(value)
      return nil if value.nil?
      unless value.is_a?(String) && !value.match?(/[\r\n]/)
        raise ValidationError.new(field: "headers", code: :invalid_header)
      end

      value
    end

    def self.merge(original, extra)
      return extra if original.nil?

      names = extra.keys.map(&:downcase)
      unless original.is_a?(Hash) && original.keys.none? { |key| names.include?(key.to_s.downcase) }
        raise ValidationError.new(field: "headers", code: :conflicting_input)
      end

      original.merge(extra)
    end
  end
end
