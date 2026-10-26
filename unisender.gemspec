# frozen_string_literal: true

# Read the version without loading library code before test coverage starts.
version = File.read(File.expand_path("lib/unisender/version.rb", __dir__))[/VERSION = "([^"]+)"/, 1]

Gem::Specification.new do |spec|
  spec.name = "unisender-ruby"
  spec.version = version
  spec.authors = ["Leonid Svyatov"]
  spec.email = ["leonid@svyatov.com"]

  spec.summary = "Ruby client for the UniSender API."
  spec.description = "A Ruby library for integrating with the UniSender API."
  spec.homepage = "https://github.com/svyatov/unisender-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["documentation_uri"] = "#{spec.homepage}/blob/main/README.md"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir["lib/**/*.rb", "sig/**/*.{rbs,yaml}", "examples/*.rb",
                   "docs/{api,releases,migration-0.2,testing,rails}.md", "LICENSE.txt", "README.md",
                   "CONTRIBUTING.md", "CHANGELOG.md",
                   "CODE_OF_CONDUCT.md", "SECURITY.md"]
  spec.require_paths = ["lib"]
end
