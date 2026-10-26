# frozen_string_literal: true

require "test_helper"
require "unisender/testing"
require_relative "../scripts/api_reference"

class OfflineValidationTest < Minitest::Test
  def setup
    @transport = Unisender::Testing::Transport.new
    @client = Unisender::Client.new(api_key: "test", transport: @transport,
                                    message_defaults: { sender_name: "News", sender_email: "a@example.test" })
  end

  def test_named_validation_uses_defaults_without_requests
    assert @client.validate!(:create_list, title: "News")
    assert @client.validate!(:send_email, email: "b@example.test", list_id: 1, subject: "News", body: "Hello")
    assert_empty @transport.requests
  end

  def test_types_missing_keywords_and_unknown_operations
    assert_raises(Unisender::ValidationError) { @client.create_list(title: false) }
    assert_raises(Unisender::ValidationError) { @client.validate!(:create_list, title: "News", typo: true) }
    assert_raises(Unisender::ValidationError) { @client.validate!(:create_list) }
  end

  def test_unknown_operations_and_misplaced_records
    assert_raises(ArgumentError) { @client.validate!(:request) }
    assert_raises(ArgumentError) { @client.validate!(:create_list, records: []) }
  end

  def test_contacts_and_imports_share_normalization
    assert @client.validate!(:subscribe, email: "a@example.test", list_ids: [1])
    assert @client.validate!(:exclude, email: "a@example.test", list_ids: [1])
    assert @client.validate!(:get_contact_count, list_id: 1, contact_type: :email)
  end

  def test_import_normalization
    assert @client.validate!(:import_contacts, records: [{ email: "a@example.test" }])
    assert_raises(Unisender::ValidationError) do
      @client.validate!(:import_contacts, records: [], data: [])
    end
  end

  def test_pages_and_hooks_validate_without_requests
    assert @client.validate!(:get_messages, date_from: Time.utc(2026), date_to: Time.utc(2026))
    assert @client.validate!(:set_hook, hook_url: "https://example.test", events: { email: [1] })
    assert_raises(Unisender::ValidationError) do
      @client.validate!(:get_messages, date_from: "a", date_to: "b", limit: 101)
    end
  end

  def test_event_validation
    assert @client.validate!(:track_events, events: [{ name: "sale", email: "a@example.test" }])
    assert_raises(Unisender::ValidationError) { @client.validate!(:track_events, events: false) }
    assert_raises(Unisender::ValidationError) { @client.validate!(:track_events, events: []) }
  end

  def test_campaign_validation
    assert @client.validate!(:send_campaign, message: { list_id: 1, subject: "News", body: "Hello" })
    assert_raises(Unisender::ValidationError) { @client.validate!(:send_campaign) }
    assert_raises(Unisender::ValidationError) { @client.validate!(:send_campaign, message: {}, campaign: false) }
  end

  def test_nested_array_type_error_has_position
    error = assert_raises(Unisender::ValidationError) do
      @client.validate!(:subscribe, email: "a@example.test", list_ids: [[1]])
    end
    assert_equal "list_ids[0]", error.field
  end

  def test_type_alternatives
    samples = { "string" => "a", "integer" => 1, "float" => 1.5, "boolean" => true,
                "symbol" => :a, "hash" => {}, "time" => Time.utc(2026),
                "attachment" => Unisender::Attachment.new(filename: "a", bytes: "a"),
                "enumerable" => [], "parameter" => nil }
    samples.each do |type, value|
      assert Unisender::InputTypes.accepts?(value, type)
      refute Unisender::InputTypes.accepts?(Object.new, type) unless type == "parameter"
    end
  end

  def test_boolean_and_unknown_types
    assert Unisender::InputTypes.accepts?(false, "boolean")
    refute Unisender::InputTypes.accepts?(1, "unknown")
  end

  def test_every_documented_operation_validates_its_examples
    reference = APIReference.new(File.expand_path("..", __dir__))
    kinds = %w[args options]
    reference.operations.each do |operation|
      kinds.each do |kind|
        next unless operation.key?(kind)

        params = operation.fetch(kind).transform_keys(&:to_sym)

        assert @client.validate!(operation.fetch("name").to_sym, **params)
      end
    end

    assert_empty @transport.requests
  end

  def test_contract_keywords_match_signatures
    reference = APIReference.new(File.expand_path("..", __dir__))

    Unisender::OperationContracts::DEFINITIONS.each_value do |name, _required, fields|
      assert_equal keyword_names(reference.methods.fetch(name.to_sym)), fields.keys.sort, name
    end
  end

  def test_invalid_normalization_inputs
    assert_raises(Unisender::ValidationError) { @client.validate!(:get_contact_count, list_id: 1, params: false) }
    assert_raises(Unisender::ValidationError) { @client.validate!(:send_campaign, message: {}, typo: true) }
    assert_raises(Unisender::ValidationError) { @client.validate!(:send_campaign, message: { "list_id" => 1 }) }
  end

  def test_invalid_nested_hook_filter
    assert_raises(Unisender::ValidationError) do
      @client.validate!(:set_hook, hook_url: "https://example.test", events: { email: [nil] })
    end
  end

  private

  def keyword_names(signature)
    (signature.required_keywords.keys + signature.optional_keywords.keys).map(&:to_s).sort
  end
end
