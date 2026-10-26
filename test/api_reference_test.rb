# frozen_string_literal: true

require "test_helper"
require_relative "../scripts/api_reference"

class APIReferenceTest < Minitest::Test
  def test_hook_defaults_are_explicit
    reference = APIReference.new(File.expand_path("..", __dir__)).render

    assert_includes reference, "Optional, defaults to json_post_gzip"
    assert_includes reference, "Optional, defaults to false (0 on the wire)"
    assert_includes reference, "Optional, defaults to active"
  end

  KEYWORD_KINDS = %i[key keyreq].freeze

  def test_reference_matches_public_signatures
    root = File.expand_path("..", __dir__)
    reference = APIReference.new(root)

    assert_equal File.read(File.join(root, "docs/api.md")), reference.render
  end

  def test_conditional_inputs_and_typed_results_are_visible
    reference = APIReference.new(File.expand_path("..", __dir__)).render

    assert_includes reference, "`records` or `field_names` with `data`"
    assert_includes reference, "`email` or `fields`"
    assert_includes reference, "`CollectionResponse[List]`"
  end

  def test_documented_operation_keywords_match_ruby
    reference = APIReference.new(File.expand_path("..", __dir__))
    reference.operations.each do |operation|
      name = operation.fetch("name")

      assert_equal ruby_keywords(name), documented_keywords(reference, name), name
    end
  end

  def test_union_types_do_not_add_markdown_columns
    rows = APIReference.new(File.expand_path("..", __dir__)).operation_table.lines

    assert(rows.all? { |row| row.scan(/(?<!\\)\|/).size == 6 })
  end

  private

  def documented_keywords(reference, name)
    signature = reference.methods.fetch(name.to_sym)
    (signature.required_keywords.keys + signature.optional_keywords.keys).sort
  end

  def ruby_keywords(name)
    Unisender::Client.instance_method(name).parameters.filter_map do |kind, key|
      key if KEYWORD_KINDS.include?(kind)
    end.sort
  end
end
