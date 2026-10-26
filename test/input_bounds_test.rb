# frozen_string_literal: true

require "test_helper"
require "unisender/testing"
require "stringio"
require "tempfile"

class InputBoundsTest < Minitest::Test
  # rubocop:disable-next Metrics/MethodLength -- Observe consumption and transport in one regression.
  def test_direct_import_stops_at_first_excess_record
    consumed = 0
    records = Enumerator.new do |output|
      1000.times do
        consumed += 1
        output << { email: "a@example.test" }
      end
    end
    transport = Unisender::Testing::Transport.new
    error = assert_raises(Unisender::ValidationError) do
      Unisender::Client.new(api_key: "test", transport:).import_contacts(records:)
    end

    assert_equal [501, "records", :too_many_records, []], [consumed, error.field, error.code, transport.requests]
  end

  def test_attachment_limit_accepts_boundary_and_leaves_io_open
    io = StringIO.new("abc")
    attachment = Unisender::Attachment.from_io(io, filename: "data", max_bytes: 3)

    assert_equal "abc", attachment.bytes
    refute_predicate io, :closed?
  end

  def test_attachment_limit_reads_only_one_excess_byte
    io = StringIO.new("abcdef")
    error = assert_raises(Unisender::ValidationError) do
      Unisender::Attachment.from_io(io, filename: "data", max_bytes: 3)
    end

    assert_equal [4, "attachments", :too_large, false], [io.pos, error.field, error.code, io.closed?]
  end

  def test_path_limit
    Tempfile.create("attachment") do |file|
      file.write("abc")
      file.flush
      assert_raises(Unisender::ValidationError) do
        Unisender::Attachment.from_path(file.path, max_bytes: 2)
      end
    end
  end

  def test_invalid_limits
    [0, -1, 1.5].each do |limit|
      assert_raises(Unisender::ValidationError) do
        Unisender::Attachment.from_io(StringIO.new("a"), filename: "data", max_bytes: limit)
      end
    end
  end
end
