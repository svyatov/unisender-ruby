# frozen_string_literal: true

require "test_helper"
require_relative "support/scripted_transport"

class ExamplesTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  ENVIRONMENT = {
    "UNISENDER_API_KEY" => "test-key", "UNISENDER_LIST_ID" => "42",
    "UNISENDER_CONTACT_EMAIL" => "person@example.test", "UNISENDER_SENDER_EMAIL" => "news@example.test"
  }.freeze

  def setup
    @previous = ENVIRONMENT.to_h { |key, value| [key, ENV.fetch(key, nil)].tap { ENV[key] = value } }
  end

  def teardown
    @previous.each { |key, value| ENV[key] = value }
  end

  def test_quickstart_only_reads_lists
    transport, output, = run_example("quickstart", { "result" => [{ "id" => 42, "title" => "News" }] })

    assert_equal "News\n", output
    assert_equal(["/en/api/getLists"], transport.requests.map { |request| request.fetch(:uri).path })
  end

  def test_subscription_preserves_confirmation_default
    transport, output, = run_example("subscribe", { "result" => { "person_id" => 123 } })
    body = URI.decode_www_form(transport.requests.fetch(0).fetch(:body)).to_h

    assert_equal "123\n", output
    assert_equal "42", body.fetch("list_ids")
    refute body.key?("double_optin")
  end

  def test_campaign_creates_then_sends_the_returned_message
    transport, output, = run_example("campaign", { "result" => { "message_id" => 12 } },
                                     { "result" => { "campaign_id" => 34, "status" => "scheduled" } })

    assert_equal "34\n", output
    assert_equal(%w[/en/api/createEmailMessage /en/api/createCampaign],
                 transport.requests.map { |request| request.fetch(:uri).path })
    assert_equal "12", URI.decode_www_form(transport.requests.last.fetch(:body)).to_h.fetch("message_id")
  end

  def test_export_polls_without_downloading_or_printing_the_private_link
    transport, output, = run_example("export", { "result" => { "task_uuid" => "task", "status" => "new" } },
                                     { "result" => { "status" => "completed",
                                                     "file_to_download" => "https://example.test/secret" } })

    assert_equal "Export ready at host: example.test\n", output
    assert_equal 2, transport.requests.size
    refute_includes output, "/secret"
  end

  def test_import_success_consumes_one_batch
    transport, output, = run_example("import", { "result" => { "invalid" => 0 } })

    assert_equal "Imported batch: HTTP 200\n", output
    assert_equal 1, transport.requests.size
  end

  def test_import_partial_failure_does_not_replay_input
    transport, _, errors = run_example("import", { "result" => { "invalid" => 1 } })

    assert_includes errors, "review rows 0...1"
    assert_includes errors, "Some rows in the failed batch were accepted"
    assert_equal 1, transport.requests.size
  end

  def test_events_success_consumes_one_batch
    transport, output, = run_example("events", { "success" => true })

    assert_equal "Recorded batch: HTTP 200\n", output
    assert_equal 1, transport.requests.size
  end

  def test_event_partial_failure_does_not_replay_input
    transport, _, errors = run_example("events", ScriptedTransport.reply({ "code" => "invalid_params" }, status: 400))

    assert_includes errors, "Valid events may already be accepted"
    assert_equal 1, transport.requests.size
  end

  def test_offline_example_never_opens_an_http_connection
    output, = replace_method(Net::HTTP, :new, ->(*) { raise "Unexpected network access" }) do
      capture_io { load File.join(ROOT, "examples/offline.rb"), true }
    end

    assert_equal "Product news\nRequests: 1\n", output
  end

  def test_readme_snippets_match_executable_examples
    readme = File.read(File.join(ROOT, "README.md"))
    snippets = readme.scan(/<!-- example: ([^ ]+) -->\n```ruby\n(.*?)```/m)

    assert_equal 2, snippets.size
    snippets.each do |path, snippet|
      source = File.read(File.join(ROOT, path))
      executable = source[source.index('require "unisender"')..]

      assert_equal executable, snippet, path
    end
  end

  private

  def run_example(name, *replies)
    transport = ScriptedTransport.new(*replies.map do |reply|
      reply.is_a?(Unisender::HTTPResponse) ? reply : ScriptedTransport.reply(reply)
    end)
    client = Unisender::Client.new(api_key: "test-key", transport:)
    output, errors = replace_method(Unisender::Client, :new, ->(**) { client }) do
      capture_io { load File.join(ROOT, "examples/#{name}.rb"), true }
    end
    [transport, output, errors]
  end

  def replace_method(object, name, replacement)
    singleton = object.singleton_class
    original = object.method(name) if singleton.method_defined?(name, false)
    singleton.remove_method(name) if original
    object.define_singleton_method(name, replacement)
    yield
  ensure
    singleton.remove_method(name)
    object.define_singleton_method(name, original) if original
  end
end
