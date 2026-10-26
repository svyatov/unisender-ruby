# frozen_string_literal: true

require "test_helper"
require "rbs"
require "rbs/test"
require_relative "support/scripted_transport"

class ResultTypesTest < Minitest::Test
  def setup
    builder = definition_builder
    @definition = builder.build_instance(RBS::TypeName.parse("::Unisender::Client"))
    @checker = RBS::Test::TypeCheck.new(self_class: Unisender::Client, builder:, sample_size: nil,
                                        unchecked_classes: [])
  end

  def test_operation_fixtures_match_the_published_result_signatures
    examples = JSON.parse(File.read(File.join(__dir__, "fixtures/operations.json")))
    examples.each do |example|
      type = result_type(example.fetch("name"))

      response = invoke(example)

      assert @checker.value(response, type), "#{example.fetch('name')} does not match #{type}"
    end
  end

  def test_invalid_inputs_do_not_satisfy_consumer_types
    flag = parameter_type(:get_contact, :include_lists)
    retention = parameter_type(:each_event_batch, :retention)

    refute @checker.value(2, flag)
    refute @checker.value(:discard, retention)
    assert @checker.value(true, flag)
  end

  def test_signatures_are_discovered_by_the_gem_name
    loader = RBS::EnvironmentLoader.new
    loader.add(library: "unisender-ruby")
    environment = RBS::Environment.from_loader(loader)

    assert environment.class_decls.key?(RBS::TypeName.parse("::Unisender::Client"))
  end

  private

  def parameter_type(method, key)
    @definition.methods.fetch(method).method_types.first.type.optional_keywords.fetch(key).type
  end

  def invoke(example)
    transport = ScriptedTransport.new(ScriptedTransport.reply({ "result" => example.fetch("result") }))
    client = Unisender::Client.new(api_key: "test-key", transport:)
    client.public_send(example.fetch("name"), **example.fetch("args").transform_keys(&:to_sym))
  end

  def result_type(name)
    @definition.methods.fetch(name.to_sym).method_types.first.type.return_type
  end

  def definition_builder
    loader = RBS::EnvironmentLoader.new
    loader.add(path: Pathname.new(File.expand_path("../sig", __dir__)))
    %w[net-http json uri openssl time ipaddr].each { |name| loader.add(library: name) }
    RBS::DefinitionBuilder.new(env: RBS::Environment.from_loader(loader).resolve_type_names)
  end
end
