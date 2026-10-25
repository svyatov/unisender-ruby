# frozen_string_literal: true

require "bundler/gem_tasks"
require "open3"
require "rake/testtask"
require "rubocop/rake_task"
require_relative "scripts/type_coverage"

Rake::TestTask.new(:test) do |task|
  task.libs << "test"
  task.pattern = "test/**/*_test.rb"
end

RuboCop::RakeTask.new(:lint)

desc "Apply safe RuboCop formatting and corrections"
task :format do
  sh "bundle", "exec", "rubocop", "--autocorrect"
end

desc "Require 100% typed calls in every library file"
task :type_coverage do
  report, status = Open3.capture2("bundle", "exec", "steep", "stats", "--format=csv", "--jobs=2", "lib")
  abort "Steep statistics failed" unless status.success?

  files = Dir["lib/**/*.rb"]
  calls = TypeCoverage.verify!(report, files: files)
  puts "Type coverage: 100% (#{calls}/#{calls} calls, #{files.size}/#{files.size} library files)"
rescue TypeCoverage::Error => e
  abort e.message
end

desc "Validate RBS signatures, type-check the library, and require 100% typed calls"
task typecheck: :type_coverage do
  sh "bundle", "exec", "rbs", "-r", "net-http", "-r", "json", "-r", "uri", "-r", "openssl", "-r", "time", "-I", "sig",
     "validate"
  sh "bundle", "exec", "steep", "check", "--jobs=2", "--severity-level=warning"
end

desc "Audit dependencies against the latest vulnerability database"
task :audit do
  sh "bundle", "exec", "bundle-audit", "check", "--update", "--database", "tmp/ruby-advisory-db"
end

desc "Run tests, lint, type checks, security audit, and gem build"
task check: %i[test lint typecheck audit build]

task default: :check
