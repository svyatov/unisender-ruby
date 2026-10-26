# frozen_string_literal: true

module Unisender
  # Converts only documented system columns on the records input path.
  module ImportCells
    LISTS = %w[tags email_list_ids email_unsubscribed_list_ids email_excluded_list_ids
               phone_list_ids phone_unsubscribed_list_ids phone_excluded_list_ids].freeze
    TIMES = %w[email_subscribe_times phone_subscribe_times].freeze

    def self.convert(name, value, index)
      case value
      when Array then array(name, value, index)
      when Time then TIMES.include?(name) ? times(value, index) : invalid!(index)
      when Hash then invalid!(index)
      else value
      end
    rescue ValidationError => e
      raise ValidationError.new(field: "records[#{index}].#{name}", code: e.code, operation: "importContacts", index:),
            cause: nil
    end

    def self.array(name, value, index)
      return list(value, index) if LISTS.include?(name)
      return times(value, index) if TIMES.include?(name)

      invalid!(index)
    end

    def self.list(values, index)
      values.map do |value|
        invalid!(index) unless (value.is_a?(String) || value.is_a?(Integer)) && !value.to_s.include?(",")
        value.to_s
      end.join(",")
    end

    def self.times(value, index)
      values = value.is_a?(Array) ? value : [value]
      values.map do |item|
        case item
        when Time then item.getutc.strftime("%Y-%m-%d %H:%M:%S")
        when String then item
        else invalid!(index)
        end
      end.join(",")
    end

    def self.validate_times(record, index)
      TIMES.each do |name|
        times = record[name]
        lists = record[name.sub("subscribe_times", "list_ids")]
        next unless times.is_a?(Array) && lists.is_a?(Array) && times.size != lists.size

        raise ValidationError.new(field: "records[#{index}].#{name}", code: :invalid_cell,
                                  operation: "importContacts", index:)
      end
    end

    def self.invalid!(index)
      raise ValidationError.new(field: "records[#{index}]", code: :invalid_cell, operation: "importContacts", index:)
    end
  end
end
