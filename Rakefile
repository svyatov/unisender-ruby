# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"

Rake::TestTask.new(:test) do |task|
  task.libs << "test"
  task.pattern = "test/**/*_test.rb"
end

RuboCop::RakeTask.new(:lint)

desc "Apply safe RuboCop formatting and corrections"
task :format do
  sh "bundle", "exec", "rubocop", "--autocorrect"
end

desc "Validate RBS signatures and type-check the library"
task :typecheck do
  sh "bundle", "exec", "rbs", "-I", "sig", "validate"
  sh "bundle", "exec", "steep", "check", "--jobs=2", "--severity-level=warning"
end

desc "Audit dependencies against the latest vulnerability database"
task :audit do
  sh "bundle", "exec", "bundle-audit", "check", "--update", "--database", "tmp/ruby-advisory-db"
end

desc "Run tests, lint, type checks, security audit, and gem build"
task check: %i[test lint typecheck audit build]

task default: :check
