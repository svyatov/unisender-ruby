# frozen_string_literal: true

require "test_helper"

class SerializationOptionsTest < Minitest::Test
  def setup
    @record = Unisender::Record.new({ "id" => 1, "name" => "News", "nested" => { "id" => 2, "name" => "Child" } })
  end

  def test_only_and_except_apply_in_order
    assert_equal({ "id" => 1 }, @record.as_json(only: %i[id name], except: "name"))
    assert_equal({ "id" => 1 }, JSON.parse(@record.to_json("only" => :id)))
    assert_empty @record.as_json(only: [])
  end

  def test_nested_values_are_not_filtered_or_shared
    value = @record.as_json(only: :nested)
    value["nested"]["name"].replace("Changed")

    assert_equal({ "id" => 2, "name" => "Child" }, @record.to_h["nested"])
    assert_equal @record.to_h, JSON.parse(@record.to_json(JSON::State.new))
  end

  def test_except_without_only
    assert_equal({ "id" => 1 }, @record.as_json(except: %i[name nested]))
  end

  def test_collections_filter_each_record
    response = Unisender::CollectionResponse.new(data: {}, status: 200, headers: {}, result: [@record])

    assert_equal [{ "name" => "News" }], response.as_json(only: :name)
    assert_equal [{ "id" => 1 }], JSON.parse(response.to_json(only: :id))
  end

  def test_invalid_options_raise
    [1, { include: :nested }, { only: 1 }, { 1 => :id }, { only: :id, "only" => :name }].each do |options|
      assert_raises(ArgumentError) { @record.as_json(options) }
    end
  end

  def test_scalar_response_rejects_filters
    response = Unisender::Response.new(data: { "result" => true }, status: 200, headers: {})

    assert response.as_json
    assert_raises(ArgumentError) { response.as_json(only: :id) }
  end
end
