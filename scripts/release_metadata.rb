# frozen_string_literal: true

require "rubygems/package"
require "digest"
require "time"
require "tmpdir"

# Metadata for the exact gem built by the release workflow.
module ReleaseMetadata
  def self.for_gem(path, created_at: Time.now.utc)
    package = Gem::Package.new(path)
    spec = package.spec
    unless spec.runtime_dependencies.empty?
      raise ArgumentError, "Inventory support is required for runtime dependencies"
    end

    files = files_in(package)
    checksum = Digest::SHA256.file(path).hexdigest
    document_header(spec, checksum, created_at).merge(
      "packages" => [package_info(spec, checksum, files)], "files" => files, "relationships" => relationships(files)
    )
  end

  def self.document_header(spec, checksum, created_at)
    {
      "spdxVersion" => "SPDX-2.3", "dataLicense" => "CC0-1.0", "SPDXID" => "SPDXRef-DOCUMENT",
      "name" => spec.full_name,
      "documentNamespace" => "https://rubygems.org/gems/#{spec.name}/versions/#{spec.version}/#{checksum}",
      "creationInfo" => { "created" => created_at.iso8601, "creators" => ["Tool: RubyGems-#{Gem::VERSION}"] }
    }
  end

  def self.package_info(spec, checksum, files)
    hashes = files.map { |file| file.fetch("checksums").first.fetch("checksumValue") }
    {
      "SPDXID" => "SPDXRef-Package", "name" => spec.name, "versionInfo" => spec.version.to_s,
      "downloadLocation" => "https://rubygems.org/downloads/#{spec.full_name}.gem",
      "filesAnalyzed" => true, "licenseDeclared" => spec.license, "licenseConcluded" => "NOASSERTION",
      "copyrightText" => "NOASSERTION", "checksums" => [{ "algorithm" => "SHA256", "checksumValue" => checksum }],
      "packageVerificationCode" => { "packageVerificationCodeValue" => Digest::SHA1.hexdigest(hashes.sort.join) }
    }
  end

  def self.relationships(files)
    [relation("SPDXRef-DOCUMENT", "DESCRIBES", "SPDXRef-Package")] +
      files.map { |file| relation("SPDXRef-Package", "CONTAINS", file.fetch("SPDXID")) }
  end

  def self.relation(from, type, to)
    { "spdxElementId" => from, "relationshipType" => type, "relatedSpdxElement" => to }
  end

  def self.files_in(package)
    Dir.mktmpdir("gem-inventory") do |directory|
      package.extract_files(directory)
      names = package.contents.select { |name| File.file?(File.join(directory, name)) }
      names.sort.map.with_index do |name, index|
        file_info(name, index, File.binread(File.join(directory, name)))
      end
    end
  end

  def self.file_info(name, index, content)
    {
      "SPDXID" => "SPDXRef-File-#{index}", "fileName" => "./#{name}",
      "checksums" => [{ "algorithm" => "SHA1", "checksumValue" => Digest::SHA1.hexdigest(content) },
                      { "algorithm" => "SHA256", "checksumValue" => Digest::SHA256.hexdigest(content) }],
      "licenseConcluded" => "NOASSERTION", "licenseInfoInFiles" => ["NOASSERTION"], "copyrightText" => "NOASSERTION"
    }
  end
  private_class_method :document_header, :package_info, :relationships, :relation, :files_in, :file_info

  def self.notes(changelog, tag)
    version = Regexp.escape(tag.delete_prefix("v"))
    lines = changelog.lines
    start = lines.index { |line| line.match?(/^## \[?#{version}(?:\]|\s|$)/) }
    raise ArgumentError, "No changelog section for #{tag}" unless start

    body = lines.drop(start + 1).take_while { |line| !line.start_with?("## ") }.join.strip
    raise ArgumentError, "Empty changelog section for #{tag}" if body.empty?

    "#{body}\n"
  end
end
