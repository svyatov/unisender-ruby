# frozen_string_literal: true

require "test_helper"
require "unisender/testing"

class APINavigationTest < Minitest::Test
  def test_common_reference_calls_use_the_documented_request_sequence
    transport = reference_transport
    context = binding
    context.local_variable_set(:client, Unisender::Client.new(api_key: "test", transport:))
    guide = File.read(File.expand_path("../docs/api.md", __dir__))
    code = guide.split("### Common Ruby calls", 2).last[/```ruby\n(.*?)```/m, 1]
    # The documentation is repository-owned executable example code.
    eval(code, context, "docs/api.md") # rubocop:disable Security/Eval

    assert_equal 8, transport.requests.size
    assert_same transport, transport.verify!
  end

  private

  def reference_transport
    names = %w[get_lists get_contact subscribe import_contacts send_sms get_message get_campaign_status]
    fixtures = JSON.parse(File.read(File.join(__dir__, "fixtures/operations.json")))
    transport = Unisender::Testing::Transport.new
    names.each do |name|
      fixture = fixtures.find { |item| item.fetch("name") == name }
      transport.enqueue(operation: fixture.fetch("wire"), data: { "result" => fixture.fetch("result") })
    end
    transport.enqueue(operation: "async/getTaskResult", data: { "result" => { "status" => "completed" } })
    transport
  end
end
