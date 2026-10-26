# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

# Run the documented service against an application-model double; full Rails is checked separately.
class RailsGuideTest < Minitest::Test
  code = File.read(File.expand_path("../docs/rails.md", __dir__))
             .split("<!-- file: app/services/import_processor.rb -->", 2).last[/```ruby\n(.*?)```/m, 1]
  module_eval(code, "docs/rails.md")

  ImportRunDouble = Struct.new(:source, :next_index, :in_flight, :status, :diagnostics, keyword_init: true) do
    def with_lock
      yield
    end

    def update!(**values)
      values.each { |key, value| self[key] = value }
    end
  end

  def test_verified_accounting_advances_checkpoint_once
    run, transport, service = integration(total: 2)
    2.times { service.call }

    assert_equal [2, nil, "completed"], [run.next_index, run.in_flight, run.status]
    assert_equal 1, transport.requests.size
  end

  def test_uncertain_accounting_keeps_ids_and_refuses_restart
    run, transport, service = integration(total: 1)

    assert_raises(Unisender::PartialFailure) { service.call }
    assert_equal [0, %w[c1 c2], "needs_review", 1], [run.next_index, run.in_flight, run.status, transport.requests.size]
    assert_raises(RuntimeError) { service.call }
  end

  private

  def integration(total:)
    transport = Unisender::Testing::Transport.new.enqueue(data: { "result" => { "total" => total, "invalid" => 0 } })
    client = Unisender::Client.new(api_key: "test", transport:)
    run = ImportRunDouble.new(source: [{ "id" => "c1", "fields" => { "email" => "a@example.test" } },
                                       { "id" => "c2", "fields" => { "email" => "b@example.test" } }], next_index: 0)
    [run, transport, ImportProcessor.new(run, client:)]
  end
end
