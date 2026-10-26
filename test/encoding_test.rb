# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class EncodingTest < Minitest::Test
  def test_email_categories_use_the_documented_comma_separated_field
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => { "message_id" => 1 } }))
    client = Unisender::Client.new(api_key: "key", transport:)
    client.create_email_message(sender_name: "Sender", sender_email: "a@b.test", list_id: 1,
                                template_id: 1, categories: %w[one two])

    assert_equal "one,two", URI.decode_www_form(transport.requests.first[:body]).to_h["categories"]
  end

  PARAMETERS = {
    field_names: %w[email Name], data: [["user@example.test", "Иван"], [nil, ""]], fields: { Name: "A & B" },
    overwrite: false, count: 0, score: 1.25, absent: nil, sub_user_rights: { 12 => { send_email: true } }
  }.freeze
  EXPECTED = {
    "field_names[0]" => "email", "field_names[1]" => "Name", "data[0][0]" => "user@example.test",
    "data[0][1]" => "Иван", "data[1][0]" => "", "data[1][1]" => "", "fields[Name]" => "A & B",
    "overwrite" => "0", "count" => "0", "score" => "1.25", "sub_user_rights[12][send_email]" => "1",
    "api_key" => "test key", "format" => "json"
  }.freeze

  def test_encodes_nested_arrays_flags_and_unicode_without_mutating_parameters
    transport = ScriptedTransport.new(ScriptedTransport.reply)
    client = Unisender::Client.new(api_key: "test key", language: :ru, transport:)
    client.request("importContacts", params: PARAMETERS)
    request = transport.requests.first

    assert_equal "/ru/api/importContacts", request[:uri].path
    assert_equal EXPECTED, URI.decode_www_form(request[:body]).to_h
    refute PARAMETERS.key?(:api_key)
  end

  def test_raw_attachment_bytes_are_not_transcoded_or_base64_encoded
    transport = ScriptedTransport.new(ScriptedTransport.reply)
    client = Unisender::Client.new(api_key: "key", transport:)
    client.request("sendEmail", params: { attachments: { "test.bin" => "\x00\xFF\x80".b } })

    assert_includes transport.requests.first[:body], "attachments%5Btest.bin%5D=%00%FF%80"
    assert_equal "application/x-www-form-urlencoded; charset=UTF-8", transport.requests.first[:headers]["Content-Type"]
  end
end
