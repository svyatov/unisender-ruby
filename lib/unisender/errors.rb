# frozen_string_literal: true

module Unisender
  # Base class for client and service failures.
  class Error < StandardError
    OPERATIONS = %w[
      createList deleteList exclude async/exportContacts getContactCount getLists getTotalContactsCount
      importContacts subscribe updateList isContactInLists getContact unsubscribe cancelCampaign
      checkEmail checkSms createCampaign createEmailMessage createSmsMessage deleteMessage
      getActualMessageVersion getWebVersion sendEmail sendSms sendTestEmail updateEmailMessage
      updateOptInEmail getSenderDomainList getCampaignCommonStats async/getCampaignDeliveryStats
      getCampaignStatus getMessages getVisitedLinks listMessages getCampaigns getMessage async/getTaskResult
      createEmailTemplate deleteTemplate getTemplate getTemplates listTemplates updateEmailTemplate
      createField deleteField deleteTag getFields getTags updateField getContactFieldValues
      createSubscriberNote updateSubscriberNote deleteSubscriberNote getSubscriberNote getSubscriberNotes
      track_events
    ].freeze
    private_constant :OPERATIONS

    attr_reader :operation, :next_offset, :completed_pages

    def with_pagination(next_offset:, completed_pages:)
      @next_offset = next_offset
      @completed_pages = completed_pages
      self
    end

    def with_operation(operation)
      @operation = OPERATIONS.include?(operation) ? operation.dup.freeze : nil
      self
    end

    def to_s
      "UniSender #{@operation || 'request'} failed: #{super}"
    end

    def inspect
      "#<#{self.class}>"
    end
  end

  # Main API failure, including failures returned with HTTP 200.
  class APIError < Error
    # https://www.unisender.com/ru/support/api/common/api-errors/
    SAFE_CODES = %w[
      unspecified invalid_api_key access_denied unknown_method invalid_arg not_enough_money retry_later
      api_call_limit_exceeded_for_api_key api_call_limit_exceeded_for_ip
    ].freeze
    private_constant :SAFE_CODES

    attr_reader :response, :code, :details

    def initialize(response)
      @response = response
      @code = response.data["code"]
      @details = response.data["error"]
      super(SAFE_CODES.include?(@code) ? @code.to_s : "API error")
    end
  end

  # Non-success HTTP response, including redirects.
  class HTTPError < Error
    attr_reader :response

    def initialize(response)
      @response = response
      super("HTTP #{response.http_status}")
    end
  end

  class InvalidResponseError < Error; end

  # Network or TLS failure with no complete HTTP response.
  class TransportError < Error
    def initialize(message, retryable: false)
      @retryable = retryable
      super(message)
    end

    def retryable?
      @retryable
    end
  end

  class TimeoutError < TransportError; end

  # A failed event request can still have accepted some events (HTTP 400).
  class EventError < HTTPError
    def report
      EventResult.new({ "success" => false, "uncertain" => response.http_status != 401 })
    end

    def code
      response.data["code"]
    end

    def details
      response.data.fetch("details", response.data["error"])
    end

    def possibly_partially_accepted?
      response.http_status == 400
    end
  end

  # Carries the completed batches and the range whose outcome needs inspection.
  class BatchError < Error
    attr_reader :completed_responses, :failed_range, :error, :report

    def initialize(completed_responses:, failed_range:, error:)
      @completed_responses = completed_responses.dup.freeze
      @failed_range = failed_range.freeze
      @error = error
      @report = BatchReport.new(@completed_responses, error:, failed_range:)
      super("UniSender batch failed; inspect the completed responses and failed range")
    end
  end

  # Identifies the next unread offset when the page bound is reached.
  class PaginationError < Error
    def initialize(operation:, next_offset:, completed_pages:)
      @operation = operation
      @next_offset = next_offset
      @completed_pages = completed_pages
      super("Pagination page limit reached")
    end
  end

  class NotFoundError < Error; end

  # The API accepted the import request but rejected some records.
  class PartialFailure < Error
    attr_reader :response

    def initialize(response)
      @response = response
      super("UniSender rejected part of the batch")
    end
  end

  # Includes the last response for an unexpected or failed asynchronous task state.
  class TaskError < Error
    attr_reader :response

    def initialize(response)
      @response = response
      super("UniSender task returned an unexpected state")
    end
  end
end
