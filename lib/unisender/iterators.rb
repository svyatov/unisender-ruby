# frozen_string_literal: true

module Unisender
  # Lazy typed iteration over every page of a supported operation.
  class Client
    def each_campaign(from:, to: nil, page_size: 100, max_pages: 1000, offset: 0, &)
      pages = each_page(
        :get_campaigns, from:, to:, page_size:, max_pages:, offset:
      ) # : Enumerator[PageResponse[Campaign], void]
      Iteration.call(Iteration.items(pages), &)
    end

    def each_message(date_from:, date_to:, page_size: 100, max_pages: 1000, offset: 0, &)
      pages = each_page(
        :get_messages, date_from:, date_to:, page_size:, max_pages:, offset:
      ) # : Enumerator[PageResponse[Message], void]
      Iteration.call(Iteration.items(pages), &)
    end

    def each_message_summary(date_from:, date_to:, page_size: 100, max_pages: 1000, offset: 0, &)
      pages = each_page(
        :list_messages, date_from:, date_to:, page_size:, max_pages:, offset:
      ) # : Enumerator[PageResponse[Message], void]
      Iteration.call(Iteration.items(pages), &)
    end

    # rubocop:disable-next Metrics/ParameterLists -- Includes the operation keywords and pagination controls.
    def each_template(type: nil, date_from: nil, date_to: nil, page_size: 100, max_pages: 1000, offset: 0, &)
      pages = each_page(
        :get_templates, type:, date_from:, date_to:, page_size:, max_pages:, offset:
      ) # : Enumerator[PageResponse[Template], void]
      Iteration.call(Iteration.items(pages), &)
    end

    # rubocop:disable-next Metrics/ParameterLists -- Includes the operation keywords and pagination controls.
    def each_template_summary(type: nil, date_from: nil, date_to: nil, page_size: 100, max_pages: 1000, offset: 0,
                              &)
      pages = each_page(
        :list_templates, type:, date_from:, date_to:, page_size:, max_pages:, offset:
      ) # : Enumerator[PageResponse[Template], void]
      Iteration.call(Iteration.items(pages), &)
    end

    def each_sender_domain_group(username:, domain: nil, page_size: 100, max_pages: 1000, offset: 0, &)
      pages = each_page(
        :get_sender_domain_list, username:, domain:, page_size:, max_pages:, offset:
      ) # : Enumerator[PageResponse[SenderDomainGroup], void]
      Iteration.call(Iteration.items(pages), &)
    end

    # rubocop:disable-next Metrics/ParameterLists -- Includes the operation keywords and pagination controls.
    def each_subscriber_note(subscriber_id:, order_type: nil, order_by: nil,
                             is_pinned: nil, page_size: 100, max_pages: 1000, offset: 0, &)
      pages = each_page(
        :get_subscriber_notes, subscriber_id:, order_type:, order_by:, is_pinned:, page_size:, max_pages:, offset:
      ) # : Enumerator[PageResponse[Note], void]
      Iteration.call(Iteration.items(pages), &)
    end
  end
end
