# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class PageBlocksTest < Minitest::Test
  def test_page_iterators_deliver_pages_to_a_block
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [{ "id" => 1 }] })
    client = Unisender::Client.new(api_key: "test", transport:)
    pages = []
    result = client.each_page(:get_templates) { |page| pages << page }

    assert_equal([1], pages.flat_map { |page| page.map(&:id) })
    assert_instance_of Enumerator, result
  end

  def test_fetched_pages_accept_blocks_without_refetching
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [{ "id" => 1 }] })
    page = Unisender::Client.new(api_key: "test", transport:).get_templates(offset: 4, limit: 10)
    seen = []
    page.each_page { |item| seen << item }
    page.auto_each { |item| seen << item.id }

    assert_equal [page, 1], seen
    assert_equal [4, 10, 5, 1], [page.offset, page.limit, page.next_offset, transport.requests.size]
  end

  def test_grouped_page_offset_counts_domains
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => [
                                                            { "domains" => [{ "Domain" => "example.test" },
                                                                            { "Domain" => "other.test" }] }
                                                          ] })
    page = Unisender::Client.new(api_key: "test", transport:).get_sender_domain_list(username: "test")

    assert_equal [0, 100, 2], [page.offset, page.limit, page.next_offset]
  end

  def test_grouped_page_rejects_an_invalid_manually_supplied_record
    response = Unisender::CollectionResponse.new(data: {}, status: 200, headers: {},
                                                 result: [Unisender::Record.new({})])
    page = Unisender::PageResponse.new(response, client: Unisender::Client.new(api_key: "test"),
                                                 method: "get_sender_domain_list", params: {})

    assert_raises(Unisender::InvalidResponseError) { page.next_offset }
  end
end
