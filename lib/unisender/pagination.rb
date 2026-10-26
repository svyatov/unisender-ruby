# frozen_string_literal: true

module Unisender
  # Offset pagination is supported only for operations that document it.
  class Pagination
    # rubocop:disable-next Metrics/ParameterLists -- Adds a fetched seed page to the pagination controls.
    def initialize(client, method, page_size, max_pages, params, first_page: nil)
      @client = client
      @method = method.to_s
      @page_size = page_size
      @max_pages = max_pages
      @params = self.class.snapshot(params)
      @first_page = first_page
      validate!(PaginatedOperations.page_limit(@method))
      wire = PaginatedOperations.validate(@method, @params)
      @params = self.class.snapshot(Inputs.normalize(wire, @params))
      initial_offset
    end

    def each
      Enumerator.new do |pages|
        fetch_pages(pages, initial_offset)
      end
    end

    def self.snapshot(params)
      params.transform_values { |value| copy(value) }.freeze
    end

    def self.copy(value)
      case value
      when Hash then value.transform_values { |item| copy(item) }.freeze
      when Array then value.map { |item| copy(item) }.freeze
      else value.dup.freeze
      end
    end

    private

    def initial_offset
      offset = @params.fetch(:offset, 0)
      raise ArgumentError, "offset must be nonnegative" unless offset.is_a?(Integer) && offset >= 0

      offset
    end

    def fetch_pages(pages, offset)
      @max_pages.times do |index|
        response = fetch_page(index, offset)
        count = page_length(response)
        pages << response
        return nil if count < @page_size

        offset += count
      end
      raise PaginationError.new(operation: @method, next_offset: offset, completed_pages: @max_pages)
    end

    def fetch_page(index, offset)
      first = @first_page
      return first if index.zero? && first

      PaginatedOperations.call(@client, @method, @params.merge(limit: @page_size, offset:))
    rescue Error => e
      raise e.with_pagination(next_offset: offset, completed_pages: index), cause: nil
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
        record = group # : Record
        domains = record["domains"]
        raise InvalidResponseError, "Expected sender domain groups" unless domains.is_a?(Array)

        domains.size
      end
    end
  end
end
