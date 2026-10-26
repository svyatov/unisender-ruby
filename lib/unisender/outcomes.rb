# frozen_string_literal: true

module Unisender
  # Shared decoding for error records inside successful envelopes.
  module Outcomes
    def self.records(value)
      return [] if value.nil?
      raise InvalidResponseError, "Expected result records" unless value.is_a?(Array)

      value.map do |item|
        raise InvalidResponseError, "Expected result record" unless item.is_a?(Record)

        item
      end
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
    def invalid
      integer!("invalid")
    end

    def total
      self["total"].nil? ? nil : integer!("total")
    end

    def failures
      Outcomes.records(self["log"]).map { |item| Failure.new(item.to_h) }.reject(&:warning?)
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
      Outcomes.records(self["errors"]).map { |item| Failure.new(item.to_h.merge("index" => index)) }
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
    def recipients
      Outcomes.records(self["recipients"]).map { |item| RecipientResult.new(item.to_h) }
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
    def total
      result.total
    end

    def invalid
      result.invalid
    end
  end

  # Per-recipient send acceptance.
  class SendResponse < OutcomeResponse
    def recipients
      result.recipients
    end

    def email_id
      result.email_id
    end
  end

  class EventResponse < OutcomeResponse; end
end
