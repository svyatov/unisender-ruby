# frozen_string_literal: true

require "test_helper"
require "open3"

class ConnectionExampleTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def test_reports_counts_without_private_account_data
    [[], [{ "id" => 42, "title" => "Private" }]].each do |lists|
      output, errors, status = run_check(data: { "result" => lists })

      assert_predicate status, :success?
      assert_equal "Connected to UniSender: HTTP 200, #{lists.size} list(s).\n", output
      assert_empty errors
    end
  end

  def test_missing_or_empty_credentials_explain_how_to_proceed
    [nil, "", " \t"].each do |key|
      output, errors, status = run_check(key:)

      assert_equal 1, status.exitstatus
      assert_empty output
      assert_equal "Set UNISENDER_API_KEY before running this example.\n", errors
    end
  end

  def test_invalid_local_credentials_do_not_produce_a_backtrace
    output, errors, status = run_check(key: "invalid\nkey")

    assert_equal 1, status.exitstatus
    assert_empty output
    assert_equal "api_key must be a nonempty string without line breaks\n", errors
  end

  def test_api_failure_does_not_print_private_details_or_a_backtrace
    output, errors, status = run_check(data: { "error" => "Private", "code" => "invalid_api_key" })

    assert_equal 1, status.exitstatus
    assert_empty output
    assert_equal "UniSender getLists failed: invalid_api_key\n", errors
  end

  private

  def run_check(key: "test-key", data: { "result" => [] })
    environment = { "UNISENDER_API_KEY" => key, "API_KEY" => nil }
    script = fake_transport(data) + "\nload #{File.join(ROOT, 'examples/check_connection.rb').inspect}"
    Open3.capture3(environment, RbConfig.ruby, "-I#{File.join(ROOT, 'lib')}", "-e", script, chdir: ROOT)
  end

  def fake_transport(data)
    <<~RUBY
      require "unisender"
      response = Unisender::HTTPResponse.new(status: 200, headers: {}, body: #{JSON.generate(data).inspect})
      transport = Object.new
      transport.define_singleton_method(:post) do |uri, **|
        abort "Unexpected API operation" unless uri.path == "/en/api/getLists"
        response
      end
      Unisender::Client.prepend(Module.new do
        define_method(:initialize) { |**options| super(**options, transport:) }
      end)
    RUBY
  end
end
