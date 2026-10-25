# frozen_string_literal: true

require "test_helper"

class UnisenderTest < Minitest::Test
  def test_exposes_a_valid_gem_version
    assert Gem::Version.correct?(Unisender::VERSION)
  end

  def test_gemspec_uses_the_library_version
    spec = Gem::Specification.load(File.expand_path("../unisender.gemspec", __dir__))

    assert_equal Unisender::VERSION, spec.version.to_s
  end
end
