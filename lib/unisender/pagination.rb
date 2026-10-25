# frozen_string_literal: true

module Unisender
  # Offset pagination is supported only for operations that document it.
  class Pagination
    def initialize(client, method, page_size, max_pages, params)
      @client = client
      @method = method.to_s
      @page_size = page_size
      @max_pages = max_pages
      @params = params.dup
    end

    def each
      Enumerator.new do |pages|
        validate!(PaginatedOperations.page_limit(@method))
        fetch_pages(pages, initial_offset)
      end
    end

    private

    def initial_offset
      offset = @params.fetch(:offset, 0)
      raise ArgumentError, "offset must be nonnegative" unless offset.is_a?(Integer) && offset >= 0

      offset
    end

    def fetch_pages(pages, offset)
      @max_pages.times do
        response = PaginatedOperations.call(@client, @method, @params.merge(limit: @page_size, offset:))
        count = page_length(response)
        pages << response
        return if count < @page_size

        offset += count
      end
      raise PaginationError, "Pagination page limit reached"
    end

    def validate!(maximum)
      validate_limit!(maximum)
      raise ArgumentError, "max_pages must be positive" unless @max_pages.is_a?(Integer) && @max_pages.positive?
      raise ArgumentError, "Use page_size instead of limit" if @params.key?(:limit)
    end

    def validate_limit!(maximum)
      raise ArgumentError, "Invalid page_size" unless @page_size.is_a?(Integer) && @page_size.positive?
      raise ArgumentError, "page_size exceeds the method limit" if maximum && @page_size > maximum
    end

    def page_length(response)
      result = response.result
      raise InvalidResponseError, "Expected paginated result array" unless result.is_a?(Array)
      return result.size unless @method == "get_sender_domain_list"

      result.sum do |group|
        raise InvalidResponseError, "Expected sender domain groups" unless group.is_a?(Hash)

        domains = group["domains"]
        raise InvalidResponseError, "Expected sender domain groups" unless domains.is_a?(Array)

        domains.size
      end
    end
  end
end
