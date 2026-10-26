# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class PaginatedOperationsTest < Minitest::Test
  names = %w[get_campaigns get_messages list_messages get_templates list_templates
             get_sender_domain_list get_subscriber_notes]
  examples = JSON.parse(File.read(File.join(__dir__, "fixtures/operations.json")))
  bad_keys = [:unexpected, "unexpected", "offset", 1]
  empty_values = [nil, "", [], {}]
  # A literal added to a contract is loaded before this snapshot, including a new keyword with no fixture.
  keyword_candidates = Symbol.all_symbols - %i[page_size max_pages]
  examples.select { |example| names.include?(example.fetch("name")) }.each do |example|
    name = example.fetch("name")
    params = example.fetch("options").transform_keys(&:to_sym).except(:limit)
    keywords = Unisender::Client.instance_method(name).parameters.map(&:last)

    define_method("test_#{name}_preserves_all_options_and_the_response") do
      assert_equal keywords.sort, (params.keys + [:limit]).sort
      direct, paginated = paired_requests(name, params)

      assert_equal direct, paginated
    end

    define_method("test_#{name}_rejects_every_loaded_keyword_outside_its_signature") do
      assert_keywords_rejected(name, params, keyword_candidates - keywords)
    end

    define_method("test_#{name}_rejects_unknown_or_non_symbol_keys") do
      bad_keys.each do |key|
        assert_rejected(name, params.merge(key => "private-value"))
      end
    end

    required = Unisender::Client.instance_method(name).parameters.filter_map { |kind, key| key if kind == :keyreq }
    next if required.empty?

    define_method("test_#{name}_shares_required_parameter_validation") do
      required.each do |key|
        assert_rejected(name, params.except(key))
        empty_values.each { |value| assert_rejected(name, params.merge(key => value)) }
      end
    end
  end

  def test_unknown_keywords_fail_immediately_before_a_request
    transport = ScriptedTransport.new(ScriptedTransport.reply)
    client = Unisender::Client.new(api_key: "test-key", transport:)
    assert_raises(ArgumentError) { client.each_page(:get_templates, unexpected: true) }
    assert_empty transport.requests
  end

  def test_rejects_non_timestamp_values_before_requests
    [false, 0, ["value"], { value: "example" }].each do |value|
      assert_rejected(:get_campaigns, { from: value })
    end
  end

  def test_direct_calls_preserve_valid_limit_and_offset
    transport = ScriptedTransport.new(ScriptedTransport.reply)
    client = Unisender::Client.new(api_key: "test-key", transport:)
    client.get_templates(limit: 100, offset: 10)

    assert_equal "100", URI.decode_www_form(transport.requests.first.fetch(:body)).to_h.fetch("limit")
  end

  def test_method_page_limit_prevents_requests
    transport = ScriptedTransport.new(ScriptedTransport.reply)
    client = Unisender::Client.new(api_key: "test-key", transport:)

    assert_raises(ArgumentError) { client.each_page(:get_templates, page_size: 101).first }
    assert_empty transport.requests
  end

  private

  def assert_keywords_rejected(name, params, keywords)
    transport = ScriptedTransport.new(ScriptedTransport.reply)
    client = Unisender::Client.new(api_key: "test-key", transport:)

    keywords.each do |key|
      assert_raises(ArgumentError, "#{name} accepted #{key.inspect}") do
        client.each_page(name, **params, **{ key => nil }).first
      end
    end
    assert_empty transport.requests
  end

  def paired_requests(name, params)
    data = { "result" => [], "warnings" => [{ "warning" => "notice" }] }
    transport = ScriptedTransport.new(ScriptedTransport.reply(data), ScriptedTransport.reply(data))
    client = Unisender::Client.new(api_key: "test-key", transport:)
    direct = client.public_send(name, **params, limit: 2, offset: params.fetch(:offset, 0))
    paginated = client.each_page(name, **params, page_size: 2).first

    assert_response_equal(direct, paginated)
    transport.requests.map { |request| request.merge(body: URI.decode_www_form(request.fetch(:body)).sort) }
  end

  def assert_response_equal(direct, paginated)
    assert_equal [direct.data, direct.http_status, direct.headers],
                 [paginated.data, paginated.http_status, paginated.headers]
  end

  def assert_rejected(name, params)
    transport = ScriptedTransport.new(ScriptedTransport.reply)
    client = Unisender::Client.new(api_key: "test-key", transport:)

    assert_raises(ArgumentError) { client.public_send(name, **params, limit: 2) }
    error = assert_raises(ArgumentError) { client.each_page(name, **params, page_size: 2) }
    refute_includes error.message, "private-value"
    assert_empty transport.requests
  end
end
