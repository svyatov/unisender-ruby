# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class CollectionAccessTest < Minitest::Test
  def setup
    data = { "result" => [{ "id" => 1, "title" => "One" }, { "id" => 2, "title" => "Two" }] }
    @transport = Unisender::Testing::Transport.new.enqueue(data:)
    @list = Unisender::Client.new(api_key: "test", transport: @transport).get_lists
    @record = Unisender::Record.new({ "name" => "News", "nil" => nil })
  end

  def test_length_and_positions_are_local
    assert_equal [2, 2, 1], [@list.length, @list.at(-1).id, @list[0].id]
    assert_equal 1, @transport.requests.size
  end

  def test_collection_slices
    assert_equal [1, 2], @list[0, 2].map(&:id)
    assert_equal [2], @list[1..].map(&:id)
    assert_raises(TypeError) { @list[0..1, 2] }
  end

  def test_collection_fetch_defaults
    assert_equal :missing, @list.fetch(9, :missing)
    assert_equal "missing 9", @list.fetch(9) { |index| "missing #{index}" }
    assert_equal 1, @list.fetch(0).id
  end

  def test_collection_fetch_errors
    assert_raises(IndexError) { @list.fetch(9) }
    assert_raises(ArgumentError) { @list.fetch(9, 1, 2) }
  end

  def test_record_lookup_distinguishes_missing_and_nil
    assert @record.key?(:nil)
    refute @record.key?(:missing)
    assert_equal [%w[name nil], ["News", nil]], [@record.keys, @record.values]
  end

  def test_record_fetch_defaults
    assert_nil @record.fetch(:nil, :fallback)
    assert_equal :fallback, @record.fetch(:missing, :fallback)
    assert_equal :missing, @record.fetch(:missing) { |key| key }
  end

  def test_record_fetch_errors_and_existing_values
    assert_equal "News", @record.fetch(:name) { raise "Must not run" }
    assert_raises(KeyError) { @record.fetch(:missing) }
    assert_raises(ArgumentError) { @record.fetch(:missing, 1, 2) }
  end

  def test_object_response_forwards_lookup
    response = Unisender::ObjectResponse.new(data: {}, status: 200, headers: {}, result: @record)

    assert_equal "News", response.fetch(:name)
    assert_equal :fallback, response.fetch(:missing, :fallback)
    assert_equal :missing, response.fetch(:missing) { |key| key }
  end

  def test_object_response_conversion_is_detached
    response = Unisender::ObjectResponse.new(data: {}, status: 200, headers: {}, result: @record)
    response.to_h["name"].replace("Changed")

    assert_equal({ "name" => "News", "nil" => nil }, response.to_h)
  end
end
