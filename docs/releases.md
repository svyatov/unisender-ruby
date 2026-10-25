# Release verification

Version tags trigger `.github/workflows/release.yml`. Tests run before the build. The `release` environment requires maintainer approval before publication.

The workflow publishes through RubyGems trusted publishing. Its signing client is isolated in `.github/release/Gemfile.lock`. Runtime dependencies are defined only by `unisender.gemspec`.

Starting with 0.1.1, GitHub releases include the gem, an SPDX inventory of its packaged files, and SHA-256 checksums. The workflow attests all three assets. The inventory generator stops if runtime dependencies need additional inventory support.

Download and verify a release in your terminal:

```sh
gh release download v0.1.1 --repo svyatov/unisender-ruby --dir release
cd release
gh attestation verify unisender-ruby.gem --repo svyatov/unisender-ruby --signer-workflow svyatov/unisender-ruby/.github/workflows/release.yml --source-ref refs/tags/v0.1.1
gh attestation verify sbom.spdx.json --repo svyatov/unisender-ruby --signer-workflow svyatov/unisender-ruby/.github/workflows/release.yml --source-ref refs/tags/v0.1.1
gh attestation verify SHA256SUMS --repo svyatov/unisender-ruby --signer-workflow svyatov/unisender-ruby/.github/workflows/release.yml --source-ref refs/tags/v0.1.1
shasum -a 256 -c SHA256SUMS
```

RubyGems also serves the signing bundle for each published gem through its [attestation API](https://guides.rubygems.org/rubygems-org-api/#get---apiv1attestationsgem-name-versionjson). Compare the bundle with the exact gem version and the `release.yml` workflow identity.

The 0.1.0 tag and assets predate this workflow and remain unchanged. Its release notes follow the complete 0.1.0 changelog section.
