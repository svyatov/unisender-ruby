# frozen_string_literal: true

module Unisender
  # Notes operations from the official UniSender API.
  class Client
    # https://www.unisender.com/ru/support/api/notes/createsubscibernote/
    def create_subscriber_note(subscriber_id:, content:)
      params = { subscriber_id:, content: }
      invoke("createSubscriberNote", params, required: %w[subscriber_id content])
    end

    # https://www.unisender.com/ru/support/api/notes/updatesubcribernote/
    def update_subscriber_note(id:, content:)
      params = { id:, content: }
      invoke("updateSubscriberNote", params, required: %w[id content])
    end

    # https://www.unisender.com/ru/support/api/notes/deletesubscribernote/
    def delete_subscriber_note(id:)
      params = { id: }
      invoke("deleteSubscriberNote", params, required: %w[id])
    end

    # https://www.unisender.com/ru/support/api/notes/getsubscribernote/
    def get_subscriber_note(id:)
      params = { id: }
      invoke("getSubscriberNote", params, required: %w[id])
    end

    # https://www.unisender.com/ru/support/api/notes/getsubscribernotes/
    # rubocop:disable-next Metrics/ParameterLists -- Mirrors the documented operation.
    def get_subscriber_notes(subscriber_id:, limit: nil, offset: nil, order_type: nil, order_by: nil,
                             is_pinned: nil)
      params = { subscriber_id:, limit:, offset:, order_type:, order_by:, is_pinned: }
      PaginatedOperations.call(self, :get_subscriber_notes, params) # : CollectionResponse[Note]
    end
  end
end
