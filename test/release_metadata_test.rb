# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../scripts/release_metadata"

class ReleaseMetadataTest < Minitest::Test
  def setup
    @directory = Dir.mktmpdir("release-metadata")
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def test_inventory_describes_the_built_gem_and_its_files
    metadata = inventory

    assert_equal "fixture", metadata.dig("packages", 0, "name")
    assert_equal "1.2.3", metadata.dig("packages", 0, "versionInfo")
    assert_equal "MIT", metadata.dig("packages", 0, "licenseDeclared")
  end

  def test_inventory_uses_the_schema_and_supplied_creation_time
    metadata = inventory

    assert_equal "SPDX-2.3", metadata["spdxVersion"]
    assert_equal "2026-10-25T00:00:00Z", metadata.dig("creationInfo", "created")
  end

  def test_inventory_lists_each_packaged_file
    expected = ["./.hidden", "./lib/empty.rb", "./payload.txt"]

    assert_equal(expected, inventory.fetch("files").map { |file| file.fetch("fileName") })
  end

  def test_inventory_hashes_packaged_content
    expected = { "algorithm" => "SHA1", "checksumValue" => "f572d396fae9206628714fb2ce00f72e94f2258f" }

    assert_includes inventory.fetch("files").last.fetch("checksums"), expected
  end

  def test_inventory_links_files_to_the_package
    assert_equal 4, inventory.fetch("relationships").size
  end

  def test_inventory_refuses_to_omit_runtime_dependencies
    path = build_gem(dependency: true)

    error = assert_raises(ArgumentError) { ReleaseMetadata.for_gem(path) }

    assert_match(/runtime dependencies/, error.message)
  end

  def test_release_notes_keep_only_the_exact_version_section
    changelog = "# Changelog\n\n## 1.2.30\n\nWrong\n\n## 1.2.3\n\n- Complete entry\n\n## Older\n\nOld entry\n"

    assert_equal "- Complete entry\n", ReleaseMetadata.notes(changelog, "v1.2.3")
  end

  def test_release_notes_reject_a_missing_version
    assert_raises(ArgumentError) { ReleaseMetadata.notes("## 1.2.30\n\nOther release\n", "v1.2.3") }
  end

  def test_release_notes_reject_an_empty_section
    assert_raises(ArgumentError) { ReleaseMetadata.notes("## 1.2.3\n\n## 1.2.2\nPrevious\n", "1.2.3") }
  end

  private

  def inventory
    ReleaseMetadata.for_gem(build_gem, created_at: Time.utc(2026, 10, 25))
  end

  def build_gem(dependency: false)
    FileUtils.mkdir_p(File.join(@directory, "lib"))
    File.write(File.join(@directory, "payload.txt"), "hello\n")
    File.write(File.join(@directory, "lib/empty.rb"), "")
    File.write(File.join(@directory, ".hidden"), "hidden")
    spec = gem_spec
    spec.add_runtime_dependency "other", "= 1.0" if dependency
    capture_io { Dir.chdir(@directory) { Gem::Package.build(spec) } }
    File.join(@directory, "fixture-1.2.3.gem")
  end

  def gem_spec
    Gem::Specification.new do |gem|
      gem.name = "fixture"
      gem.version = "1.2.3"
      gem.authors = ["Test"]
      gem.summary = "Release metadata fixture"
      gem.license = "MIT"
      gem.files = ["payload.txt", "lib/empty.rb", ".hidden"]
    end
  end
end
