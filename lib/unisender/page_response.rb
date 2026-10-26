# frozen_string_literal: true

module Unisender
  # Pagination is explicit; ordinary Enumerable methods only visit this page.
  class PageResponse < CollectionResponse
    def initialize(response, client:, method:, params:)
      @client = client
      @method = method
      @params = Pagination.snapshot(params)
      super(data: response.data, status: response.http_status, headers: response.headers, result: response.result)
    end

    # rubocop:disable Layout/LineLength
    # @type method each_page: (?max_pages: Integer) ?{ (PageResponse[Record]) -> void } -> Enumerator[PageResponse[Record], void]
    # rubocop:enable Layout/LineLength
    def each_page(max_pages: 1000, &)
      size = @params.fetch(:limit, 100) # : Integer
      pager = Pagination.new(@client, @method, size, max_pages, @params.except(:limit), first_page: self)
      Iteration.call(pager.each, &) # : Enumerator[PageResponse[Record], void]
    end

    # @type method auto_each: (?max_pages: Integer) ?{ (Record) -> void } -> Enumerator[Record, void]
    def auto_each(max_pages: 1000, &)
      Iteration.call(Iteration.items(each_page(max_pages:)), &)
    end

    def offset
      @params.fetch(:offset, 0) # : Integer
    end

    def limit
      @params.fetch(:limit, 100) # : Integer
    end

    def next_offset
      count = if @method == "get_sender_domain_list"
                result.sum do |item|
                  raise InvalidResponseError, "Expected a sender-domain group" unless item.is_a?(SenderDomainGroup)

                  item.domains.size
                end
              else
                size
              end
      offset + count
    end
  end
end
