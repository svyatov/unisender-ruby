# frozen_string_literal: true

require "test_helper"
require "rbs"
require "rbs/test"

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

      assert @checker.value(example.fetch("result"), type), "#{example.fetch('name')} does not match #{type}"
    end
  end

  private

  def result_type(name)
    @definition.methods.fetch(name.to_sym).method_types.first.type.return_type.args.first
  end

  def definition_builder
    loader = RBS::EnvironmentLoader.new
    loader.add(path: Pathname.new(File.expand_path("../sig", __dir__)))
    %w[net-http json uri openssl time].each { |name| loader.add(library: name) }
    RBS::DefinitionBuilder.new(env: RBS::Environment.from_loader(loader).resolve_type_names)
  end
end
