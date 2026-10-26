# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class MailConvenienceTest < Minitest::Test
  def setup
    @transport = Unisender::Testing::Transport.new
    @client = Unisender::Client.new(api_key: "test", transport: @transport,
                                    message_defaults: { sender_name: "News", sender_email: "a@example.test" })
  end

  def test_named_headers_and_image_choices
    enqueue([{ "id" => 1 }])
    send_mail(reply_to: "reply@example.test", priority: "normal", images_as: :only_links)

    assert_equal ["reply@example.test", "normal", "only_links"],
                 @transport.requests.first.form.values_at("headers[Reply-To]", "headers[Priority]", "images_as")
  end

  def test_nonconflicting_headers_are_preserved
    enqueue([{ "id" => 1 }])
    send_mail(reply_to: "reply@example.test", headers: { Priority: "normal" })

    assert_equal "normal", @transport.requests.first.form["headers[Priority]"]
  end

  def test_conflicting_headers_fail_before_networking
    [{ "reply-to" => "existing@example.test" }, "Priority: normal"].each do |headers|
      assert_raises(Unisender::ValidationError) { send_mail(reply_to: "reply@example.test", headers:) }
    end
    assert_empty @transport.requests
  end

  def test_header_lines_and_invalid_images_are_rejected
    assert_raises(Unisender::ValidationError) { send_mail(priority: "normal\r\nother") }
    assert_raises(Unisender::ValidationError) { send_mail(images_as: :invalid) }
    assert_raises(Unisender::ValidationError) { Unisender::MailInputs.headers(reply_to: true) }
  end

  def test_recipient_views_keep_unknown_outcomes_separate
    enqueue([{ "id" => 1, "email" => "a@example.test" },
             { "email" => "b@example.test", "errors" => [{ "code" => "invalid_email" }] },
             { "email" => "c@example.test" }])
    response = send_mail

    assert_equal [[1], ["a@example.test"], ["b@example.test"], ["c@example.test"]],
                 [response.accepted_ids, response.accepted_recipients.map(&:email),
                  response.rejected_recipients.map(&:email), response.unknown_recipients.map(&:email)]
    assert_predicate response.accepted_ids, :frozen?
  end

  def test_legacy_ids_do_not_invent_recipient_details
    enqueue({ "email_id" => 123 })
    response = send_mail(error_checking: false)

    assert_equal [123], response.accepted_ids
    assert_empty response.accepted_recipients
  end

  private

  def enqueue(result)
    @transport.enqueue(data: { "result" => result })
  end

  def send_mail(**)
    @client.send_email(email: "a@example.test", subject: "News", body: "News", list_id: 1, **)
  end
end
