# frozen_string_literal: true

# Read the version without loading library code before test coverage starts.
version = File.read(File.expand_path("lib/unisender/version.rb", __dir__))[/VERSION = "([^"]+)"/, 1]

Gem::Specification.new do |spec|
  spec.name = "unisender"
  spec.version = version
  spec.authors = ["Leonid Svyatov"]
  spec.email = ["leonid@svyatov.com"]

  spec.summary = "Ruby client for the UniSender API."
  spec.description = "A Ruby library for integrating with the UniSender API."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "sig/**/*.rbs", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]
end
