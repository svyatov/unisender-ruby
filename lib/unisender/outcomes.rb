# frozen_string_literal: true

module Unisender
  # Shared decoding for error records inside successful envelopes.
  module Outcomes
    def self.records(value, path)
      return [] if value.nil?
      unless value.is_a?(Array)
        raise InvalidResponseError.new("Expected result records", path:, expected_type: "Array",
                                                                  actual_type: Diagnostics.type_name(value))
      end

      value.each_with_index.map { |item, index| record(item, "#{path}[#{index}]") }
    end

    def self.record(item, path)
      return item if item.is_a?(Record)

      raise InvalidResponseError.new("Expected result record", path:, expected_type: "Hash",
                                                               actual_type: Diagnostics.type_name(item))
    end

    def self.failures(value, path, overrides = {})
      records(value, path).each_with_index.map { |item, index| failure(item, "#{path}[#{index}]", overrides) }
    end

    def self.failure(item, path, overrides)
      Failure.new(item.to_h.merge(overrides))
    rescue InvalidResponseError => e
      raise e.prepend_path(path), cause: nil
    end
  end

  # A record position and its upstream diagnostic, kept out of inspection output.
  class Failure < Record
    def index
      self["index"].nil? ? nil : integer!("index")
    end

    def code
      text("code")
    end

    def message
      text("message")
    end

    def warning?
      value = code
      value.is_a?(String) && value.start_with?("w_")
    end

    def with_offset(offset)
      position = index
      return self unless position

      Failure.new(to_h.merge("index" => position + offset))
    end

    protected

    def normalize
      @values["index"] = index if @values.key?("index")
      code
      message
    end
  end

  # Import acceptance is distinct from recipient delivery.
  class ImportResult < Record
    OPTIONAL_COUNTERS = %w[inserted updated deleted new_emails].freeze

    def inserted
      integer("inserted")
    end

    def updated
      integer("updated")
    end

    def deleted
      integer("deleted")
    end

    def new_emails
      integer("new_emails")
    end

    def invalid
      integer!("invalid")
    end

    def total
      self["total"].nil? ? nil : integer!("total")
    end

    def failures
      Outcomes.failures(self["log"], "log").reject(&:warning?)
    end

    def row_warnings
      Outcomes.failures(self["log"], "log").select(&:warning?)
    end

    def complete?
      invalid.zero?
    end

    def uncertain?
      invalid.positive? && total.nil?
    end

    def partial?
      count = total
      count.is_a?(Integer) && invalid.positive? && invalid < count
    end

    protected

    def normalize
      @values["invalid"] = invalid
      @values["total"] = total if @values.key?("total")
      OPTIONAL_COUNTERS.each { |name| @values[name] = integer(name) if @values.key?(name) }
      failures
    end
  end

  # Per-recipient acceptance from sendEmail with error_checking enabled.
  class RecipientResult < Record
    def id
      self["id"].nil? ? nil : identifier!("id")
    end

    def index
      self["index"].nil? ? nil : integer!("index")
    end

    def email
      text("email")
    end

    def failures
      Outcomes.failures(self["errors"], "errors", { "index" => index })
    end

    def accepted?
      !id.nil? && failures.empty?
    end

    protected

    def normalize
      id
      index
      email
      failures
    end
  end

  # Handles both documented sendEmail result formats.
  class SendResult < Record
    def accepted_recipients
      recipients.select(&:accepted?).freeze
    end

    def rejected_recipients
      recipients.reject { |recipient| recipient.failures.empty? }.freeze
    end

    def unknown_recipients
      recipients.reject { |recipient| recipient.accepted? || !recipient.failures.empty? }.freeze
    end

    def accepted_ids
      legacy = email_id
      (legacy ? [legacy] : accepted_recipients.filter_map(&:id)).freeze
    end

    def recipients
      Outcomes.records(self["recipients"], "recipients").each_with_index.map do |item, index|
        child(RecipientResult, item.to_h, "recipients[#{index}]")
      end
    end

    def email_id
      self["email_id"].nil? ? nil : identifier!("email_id")
    end

    def failures
      recipients.flat_map(&:failures)
    end

    def complete?
      return true if email_id

      !recipients.empty? && recipients.all?(&:accepted?)
    end

    def uncertain?
      return false if email_id

      recipients.empty? || recipients.any? { |item| !item.accepted? && item.failures.empty? }
    end

    def partial?
      !complete? && recipients.any?(&:accepted?)
    end

    protected

    def normalize
      email_id
      recipients
    end
  end

  # Event failures can have an unknown number of accepted events.
  class EventResult < Record
    def complete?
      self["success"] == true
    end

    def partial?
      false
    end

    def uncertain?
      self["uncertain"] == true
    end

    def failures
      []
    end
  end

  # Uniform acceptance inspection for supported report responses.
  class OutcomeResponse < ObjectResponse
    def complete?
      result.complete?
    end

    def partial?
      result.partial?
    end

    def uncertain?
      result.uncertain?
    end

    def failures
      result.failures
    end

    def raise_for_partial_failure!
      raise PartialFailure, self unless complete?

      self
    end
  end

  # Import counters and acceptance state.
  class ImportResponse < OutcomeResponse
    def row_warnings
      result.row_warnings
    end

    def inserted
      result.inserted
    end

    def updated
      result.updated
    end

    def deleted
      result.deleted
    end

    def new_emails
      result.new_emails
    end

    def total
      result.total
    end

    def invalid
      result.invalid
    end
  end

  # Per-recipient send acceptance.
  class SendResponse < OutcomeResponse
    def accepted_recipients
      result.accepted_recipients
    end

    def rejected_recipients
      result.rejected_recipients
    end

    def unknown_recipients
      result.unknown_recipients
    end

    def accepted_ids
      result.accepted_ids
    end

    def recipients
      result.recipients
    end

    def email_id
      result.email_id
    end
  end

  class EventResponse < OutcomeResponse; end
end
