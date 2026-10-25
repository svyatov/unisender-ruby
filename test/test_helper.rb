# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  root File.expand_path("..", __dir__)
  cover "{lib,scripts}/**/*.rb"
  merging false
  coverage :line, minimum: 100, maximum_missed: 0
  coverage :branch, minimum: 100, maximum_missed: 0
end

require "minitest/autorun"
require "unisender"
