# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fastlane/plugin/write_changelog_from_commits/version"

Gem::Specification.new do |spec|
  spec.name = "fastlane-plugin-write_changelog_from_commits"
  spec.version = Fastlane::WriteChangelogFromCommits::VERSION
  spec.author = "Lewis Bright"
  spec.email = "lewis_bright@yahoo.com"

  spec.summary = "Writes a changelog by pattern matching on git commits since the last tag. Organises these into sections and creates a changelog with the same name as the current version code"
  spec.homepage = "https://github.com/Lewis-Bright/fastlane-plugin-write-changelog-from-commits"
  spec.license = "MIT"

  spec.files = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  # spec.add_dependency 'your-dependency', '~> 1.0.0'

  spec.add_development_dependency("pry")
  spec.add_development_dependency("bundler")
  spec.add_development_dependency("rspec")
  spec.add_development_dependency("rspec_junit_formatter")
  spec.add_development_dependency("rake")
  spec.add_development_dependency("rubocop")
  spec.add_development_dependency("rubocop-require_tools")
  spec.add_development_dependency("rubocop-rake")
  spec.add_development_dependency("rubocop-rspec")
  spec.add_development_dependency("simplecov")
  spec.add_development_dependency("fastlane")
end
