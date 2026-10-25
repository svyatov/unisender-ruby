# frozen_string_literal: true

require_relative "lib/unisender/version"

Gem::Specification.new do |spec|
  spec.name = "unisender"
  spec.version = Unisender::VERSION
  spec.authors = ["Leonid Svyatov"]
  spec.email = ["leonid@svyatov.com"]

  spec.summary = "Ruby client for the UniSender API."
  spec.description = "A Ruby library for integrating with the UniSender API."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.files = Dir["lib/**/*.rb", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]
end
