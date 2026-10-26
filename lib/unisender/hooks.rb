# frozen_string_literal: true

module Unisender
  # The documented hook record, with unknown fields retained through Record.
  class Hook < IdentifierRecord
    def url
      text!("url")
    end

    def event_format
      text!("event_format")
    end

    def max_parallel
      integer!("max_parallel")
    end

    def single_event
      integer!("single_event")
    end

    def status
      text!("status")
    end

    def events
      value = self["events"]
      raise InvalidResponseError, "Expected hook event filters" unless value.is_a?(Record)

      value
    end

    protected

    def normalize
      super
      url
      event_format
      max_parallel
      single_event
      status
      events
    end
  end

  # Hook mutation result shapes are not specified by the upstream reference.
  class Client
    # https://www.unisender.com/ru/support/api/common/sistema-uvedomlenij-o-sobytiyah-webhooks/
    # rubocop:disable-next Metrics/ParameterLists -- Mirrors the documented operation.
    def set_hook(hook_url:, events:, event_format: :json_post_gzip, max_parallel: nil, single_event: false,
                 status: :active)
      events = hook_events(events, max_parallel)
      params = { hook_url:, events:, event_format:, max_parallel:, single_event:, status: }
      request("setHook", params: prepare("setHook", params, required: %w[hook_url events]))
    rescue ValidationError => e
      raise e.with_operation("setHook"), cause: nil
    end

    def hook_events(events, max_parallel)
      if !max_parallel.nil? && !(max_parallel.is_a?(Integer) && max_parallel.positive?)
        raise ValidationError.new(field: "max_parallel", code: :invalid_range, operation: "setHook")
      end
      raise ValidationError.new(field: "events", code: :invalid_type, operation: "setHook") unless events.is_a?(Hash)

      events.to_h do |name, filters|
        [name, filters.is_a?(Array) ? Validation.comma_list(filters) : filters]
      end
    end
    private :hook_events

    def list_hooks
      invoke("listHooks", {})
    end

    def remove_hook(hook_url:)
      request("removeHook", params: prepare("removeHook", { hook_url: }, required: %w[hook_url]))
    end
  end
end
