# frozen_string_literal: true

require "test_helper"
require "unisender/testing"
require "stringio"
require "tempfile"

class AttachmentTest < Minitest::Test
  def test_io_is_snapshotted_without_closing_it
    io = StringIO.new("\x00\xFF".b)
    attachment = Unisender::Attachment.from_io(io, filename: "data.bin")
    io.string.replace("changed")

    assert_equal "\x00\xFF".b, attachment.bytes
    refute_predicate io, :closed?
    refute_includes attachment.inspect, "data.bin"
  end

  def test_file_attachment_uses_the_filename
    Tempfile.create("attachment") do |file|
      file.binmode
      file.write("bytes")
      file.flush
      attachment = Unisender::Attachment.from_path(file.path)

      assert_equal File.basename(file.path), attachment.filename
      assert_equal "bytes", attachment.bytes
    end
    assert_raises(ArgumentError) { Unisender::Attachment.from_path("/nonexistent/unisender-test-file") }
  end

  def test_attachment_is_encoded_as_raw_bytes
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => { "message_id" => 1 } })
    client = Unisender::Client.new(api_key: "test-key", transport:)
    attachment = Unisender::Attachment.new(filename: "data.bin", bytes: "\xFF".b)
    client.create_email_message(sender_name: "Sender", sender_email: "a@b.test", list_id: 1,
                                subject: "News", body: "Hello", attachments: attachment)

    assert_includes transport.requests.first.body, "attachments%5Bdata.bin%5D=%FF"
  end

  def test_duplicate_and_invalid_attachments_are_rejected
    item = Unisender::Attachment.new(filename: "data.bin", bytes: "bytes")

    assert_raises(Unisender::ValidationError) { Unisender::Inputs.attachments([item, item]) }
    assert_raises(Unisender::ValidationError) { Unisender::Inputs.attachments(["bad"]) }
    assert_raises(Unisender::ValidationError) { Unisender::Inputs.attachments(1) }
  end

  def test_invalid_filenames_are_rejected
    ["", "bad[name]", "bad\nname"].each do |name|
      assert_raises(ArgumentError) { Unisender::Attachment.new(filename: name, bytes: "data") }
    end
    source = Class.new { def read = nil }.new

    assert_raises(ArgumentError) { Unisender::Attachment.from_io(source, filename: "data.bin") }
  end
end
