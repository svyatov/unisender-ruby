# frozen_string_literal: true

module Unisender
  AcceptanceEvent = Data.define(:operation, :outcome, :input_count, :accepted_count, :rejected_count,
                                :unknown_count, :row_warning_count, :request_id)

  # Acceptance accounting is separate from HTTP and request-attempt outcomes.
  module Acceptance
    def self.input_count(operation, params)
      case operation
      when "sendEmail" then params[:cc] ? 2 : 1
      when "sendSms"
        phone = params[:phone]
        phone.split(",").size if phone.is_a?(String)
      when "importContacts"
        data = params[:data]
        data.size if data.is_a?(Array)
      end
    end

    def self.event(operation, count, response, error)
      accepted, rejected, unknown = counts(count, response, error)
      request_id = response&.headers&.[]("x-request-id") || (error.is_a?(Error) ? error.request_id : nil)
      AcceptanceEvent.new(operation: Error.safe_operation(operation) || "request",
                          outcome: state(response, error, unknown), input_count: count,
                          accepted_count: accepted, rejected_count: rejected, unknown_count: unknown,
                          row_warning_count: warning_count(response), request_id:)
    end

    def self.warning_count(response)
      return response.row_warnings.size if response.is_a?(ImportResponse)

      response ? 0 : nil
    end

    def self.counts(count, response, error)
      case response
      when SendResponse then send_counts(count, response)
      when ImportResponse then import_counts(count, response)
      when EventResponse then [count, 0, 0]
      when CollectionResponse then [response.size, 0, [count - response.size, 0].max]
      else
        error.is_a?(EventError) && error.http_status == 401 ? [0, count, 0] : [nil, nil, nil]
      end
    end

    def self.send_counts(count, response)
      accepted = response.email_id ? count : response.accepted_recipients.size
      rejected = response.rejected_recipients.size
      [accepted, rejected, [count - accepted - rejected, response.unknown_recipients.size, 0].max]
    end

    def self.import_counts(count, response)
      total = response.total
      accepted = total && total >= response.invalid ? total - response.invalid : nil
      [accepted, response.invalid, total ? [count - total, 0].max : nil]
    end

    def self.state(response, error, unknown)
      return error.is_a?(EventError) && error.http_status == 401 ? :rejected : :uncertain if error
      return result_state(response) if response.is_a?(OutcomeResponse)

      case unknown
      when 0 then :complete
      else :uncertain
      end
    end

    def self.result_state(response)
      return :complete if response.complete?
      return :uncertain if response.uncertain?
      return :partial if response.partial?

      :rejected
    end

    def self.emit(callback, event)
      callback.call(event)
    rescue StandardError
      nil
    end
  end

  # Optional callbacks expose acceptance independently of request attempts.
  class Client
    private

    def observe_acceptance(operation, count, response, error)
      callback = @configuration.acceptance_instrumentation
      return unless callback && count

      Acceptance.emit(callback, Acceptance.event(operation, count, response, error))
    end
  end
end
