# frozen_string_literal: true

require "test_helper"
require_relative "../scripts/type_coverage"

class TypeCoverageTest < Minitest::Test
  def test_accepts_fully_typed_calls_and_files_without_calls
    assert_equal 1, TypeCoverage.verify!(report, files: files)
  end

  def test_rejects_an_untyped_call
    assert_raises(TypeCoverage::Error) do
      TypeCoverage.verify!(report.sub("success,1,0,1,100", "success,1,1,2,50"), files: files)
    end
  end

  def test_rejects_an_error_call_even_when_untyped_count_is_zero
    assert_raises(TypeCoverage::Error) do
      TypeCoverage.verify!(report.sub("success,1,0,1,100", "success,1,0,2,50"), files: files)
    end
  end

  def test_rejects_failed_analysis_of_a_file_without_calls
    assert_raises(TypeCoverage::Error) do
      TypeCoverage.verify!(report.sub("success,0,0,0,100", "error,0,0,0,0"), files: files)
    end
  end

  def test_rejects_an_omitted_library_file
    assert_raises(TypeCoverage::Error) do
      TypeCoverage.verify!(report, files: [*files, "lib/unisender/client.rb"])
    end
  end

  def test_rejects_missing_stats
    assert_raises(TypeCoverage::Error) { TypeCoverage.verify!("", files: files) }
  end

  def test_rejects_a_duplicate_file_report
    duplicate = "#{report}unisender,lib/unisender.rb,success,1,0,1,100\n"
    assert_raises(TypeCoverage::Error) { TypeCoverage.verify!(duplicate, files: files) }
  end

  def test_rejects_malformed_csv
    assert_raises(TypeCoverage::Error) { TypeCoverage.verify!("\"unclosed", files: files) }
  end

  def test_rejects_invalid_counts
    assert_raises(TypeCoverage::Error) do
      TypeCoverage.verify!(report.sub("success,1,0,1,100", "success,unknown,0,1,100"), files: files)
    end
  end

  def test_rejects_an_empty_project
    assert_raises(TypeCoverage::Error) { TypeCoverage.verify!(report.lines.first, files: []) }
  end

  private

  def files
    ["lib/unisender.rb", "lib/unisender/version.rb"]
  end

  def report
    <<~CSV
      Target,File,Status,Typed calls,Untyped calls,All calls,Typed %
      unisender,lib/unisender.rb,success,1,0,1,100
      unisender,lib/unisender/version.rb,success,0,0,0,100
    CSV
  end
end
