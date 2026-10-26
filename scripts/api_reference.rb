# frozen_string_literal: true

require "json"
require "rbs"
require "yaml"

# Builds the Ruby-facing portions of the reference from the shipped signatures.
class APIReference
  EVENT_ROW = "| `track_events` | [Event Tracking](https://www.unisender.com/ru/support/api/event-tracking-api/) | " \
              "`events` | None | `EventResponse` |"

  def initialize(root)
    @root = root
  end

  def render
    text = File.read(File.join(@root, "docs/api.md"))
    text = text.sub(/\| Ruby method \|.*?(?=## Reading the contracts)/m, "#{operation_table}\n\n")
    text = render_keywords(text)
    text.sub(/\| Result \| Readers \|.*?(?=Report responses)/m, "#{reader_table}\n\n")
  end

  def render_keywords(text)
    operations.reduce(text) do |content, operation|
      name = operation.fetch("name")
      content.sub(%r{(<a id="#{name}"></a>.*?)(\| Keyword \|.*?\n\n|No operation arguments\.\n\n)}m) do
        "#{Regexp.last_match(1)}#{keyword_table(name, methods.fetch(name.to_sym))}\n\n"
      end
    end
  end

  def operations
    JSON.parse(File.read(File.join(@root, "test/fixtures/operations.json")))
  end

  def declarations
    Dir[File.join(@root, "sig/*.rbs")].flat_map do |path|
      RBS::Parser.parse_signature(File.read(path)).last.flat_map(&:members)
    end.grep(RBS::AST::Declarations::Class)
  end

  def methods
    declarations.select { |item| item.name.name == :Client }.flat_map(&:members)
                .grep(RBS::AST::Members::MethodDefinition)
                .to_h { |item| [item.name, item.overloads.first.method_type.type] }
  end

  def annotations
    YAML.safe_load_file(File.join(@root, "docs/api_annotations.yml"), aliases: true)
  end

  def operation_table
    header = ["| Ruby method | Wire method and documentation | Required inputs | Optional keywords | Typed result |",
              "| --- | --- | --- | --- | --- |"]
    (header + operations.map { |operation| operation_row(operation) } + [EVENT_ROW]).join("\n")
  end

  def operation_row(operation)
    name = operation.fetch("name")
    signature = methods.fetch(name.to_sym)
    ["", "[`#{name}`](##{name})", "[`#{operation.fetch('wire')}`](#{operation.fetch('url')})", required_inputs(name),
     names(signature.optional_keywords.keys), "`#{signature.return_type}`", ""].join(" | ").strip
  end

  def required_inputs(name)
    annotations.fetch(name, {}).fetch("requires") { names(methods.fetch(name.to_sym).required_keywords.keys) }
  end

  def keyword_table(name, signature)
    keywords = signature.required_keywords.merge(signature.optional_keywords)
    return "No operation arguments." if keywords.empty?

    rows = keywords.map do |key, parameter|
      presence = presence(name, key, signature)
      "| `#{key}` | `#{parameter.type.to_s.gsub('|', '\\|')}` | #{presence} |"
    end
    (["| Keyword | Ruby type | Presence |", "| --- | --- | --- |"] + rows).join("\n")
  end

  def presence(name, key, signature)
    annotations.fetch(name, {}).fetch(key.to_s) do
      signature.required_keywords.key?(key) ? "Required" : "Optional, omitted"
    end
  end

  def reader_table
    classes = declarations.to_h { |item| [item.name.name, item] }
    rows = classes.keys.sort.filter_map do |name|
      chain = ancestors(name, classes)
      next unless name != :Record && chain.include?(:Record)

      "| `#{name}` | #{names(readers(chain, classes))} |"
    end
    (["| Result | Readers |", "| --- | --- |"] + rows).join("\n")
  end

  def readers(chain, classes)
    result = chain.take_while { |parent| parent != :Record }.flat_map do |parent|
      classes.fetch(parent).members.grep(RBS::AST::Members::MethodDefinition).map(&:name)
    end
    result.reject { |reader| reader == :normalize }.uniq
  end

  def ancestors(name, classes)
    item = classes[name]
    return [] unless item

    [name] + ancestors(item.super_class&.name&.name, classes)
  end

  def names(values)
    values.empty? ? "None" : values.map { |value| "`#{value}`" }.join(", ")
  end
end
