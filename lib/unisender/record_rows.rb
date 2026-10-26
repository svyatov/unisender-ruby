# frozen_string_literal: true

module Unisender
  # Keeps one column order across a streaming import.
  class RecordRows
    include Enumerable

    attr_reader :field_names

    def initialize(records)
      @field_names = []
      @records = records
      @rows = case records
              when Array then records.each_with_index.map { |record, index| row(record, index) }
              end
    end

    def each(&)
      rows = @rows
      if rows
        rows.each(&)
      else
        @records.each_with_index { |record, index| yield row(record, index) }
      end
    end

    private

    def row(record, index)
      object = record_object(record, index)
      names = object.keys.map(&:to_s)
      validate_columns(names, index)
      normalized = object.transform_keys(&:to_s)
      ImportCells.validate_times(normalized, index)
      @field_names.map { |name| ImportCells.convert(name, normalized.fetch(name), index) }
    end

    def record_object(record, index)
      unless record.is_a?(Hash)
        raise ValidationError.new(field: "records[#{index}]", code: :invalid_record, operation: "importContacts",
                                  index:)
      end

      record
    end

    def validate_columns(names, index)
      if names.uniq.size != names.size || !names.include?("email")
        raise ValidationError.new(field: "records[#{index}]", code: :invalid_columns, operation: "importContacts",
                                  index:)
      end

      @field_names = names.freeze if @field_names.empty?
      return if names.sort == @field_names.sort

      raise ValidationError.new(field: "records[#{index}]", code: :inconsistent_columns, operation: "importContacts",
                                index:)
    end
  end
end
