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

    # @type method each_page: (?max_pages: Integer) -> Enumerator[PageResponse[Record], void]
    def each_page(max_pages: 1000)
      size = @params.fetch(:limit, 100) # : Integer
      pager = Pagination.new(@client, @method, size, max_pages, @params.except(:limit), first_page: self)
      pager.each # : Enumerator[PageResponse[Record], void]
    end

    # @type method auto_each: (?max_pages: Integer) -> Enumerator[Record, void]
    def auto_each(max_pages: 1000)
      pages = each_page(max_pages:)
      Enumerator.new { |items| pages.each { |page| page.each { |item| items << item } } }
    end
  end
end
