# frozen_string_literal: true

require "test_helper"

class UnisenderTest < Minitest::Test
  def test_exposes_a_valid_gem_version
    assert Gem::Version.correct?(Unisender::VERSION)
  end
end
