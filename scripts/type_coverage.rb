# frozen_string_literal: true

require "csv"

# Enforces complete library-file and typed-call coverage from Steep statistics.
module TypeCoverage
  class Error < StandardError; end

  HEADERS = ["Target", "File", "Status", "Typed calls", "Untyped calls", "All calls", "Typed %"].freeze

  def self.verify!(report, files:)
    rows = CSV.parse(report, headers: true)
    validate_files!(rows, files)
    rows.sum { |row| typed_calls(row) }
  rescue CSV::MalformedCSVError, ArgumentError, TypeError => e
    raise Error, "Invalid Steep statistics: #{e.message}"
  end

  def self.validate_files!(rows, files)
    raise Error, "Invalid Steep statistics headers" unless rows.headers == HEADERS
    raise Error, "No library files found" if files.empty?

    return if rows.map { |row| row["File"] }.sort == files.sort

    raise Error, "Steep must report every library file exactly once"
  end

  def self.typed_calls(row)
    unless row.values_at("Target", "Status") == %w[unisender success]
      raise Error, "Steep did not successfully check #{row['File']}"
    end

    typed, untyped, total = row.values_at("Typed calls", "Untyped calls", "All calls").map do |value|
      Integer(value, 10)
    end
    unless typed >= 0 && untyped.zero? && typed == total
      raise Error, "#{row['File']}: expected 100% typed calls, got #{typed}/#{total} (#{untyped} untyped)"
    end

    typed
  end

  private_class_method :validate_files!, :typed_calls
end
