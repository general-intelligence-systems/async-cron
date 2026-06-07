# frozen_string_literal: true

require_relative "lib/async/cron/version"

Gem::Specification.new do |spec|
  spec.name = "async-cron"
  spec.version = Async::Cron::VERSION
  spec.authors = ["Nathan K"]
  spec.email = ["nathankidd@hey.com"]

  spec.summary = "Async-native cron/interval scheduler for Ruby"

  spec.description = <<~DESC
    A fibre-based scheduler built on the Socketry async ecosystem. Schedule work
    with at/in/every/cron using fugit, bounded by an Async::Semaphore.
  DESC

  spec.homepage = "https://github.com/general-intelligence-systems/async-cron"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["documentation_uri"] = "https://general-intelligence-systems.github.io/async-cron/"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|data)/}) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "async", "~> 2.0"
  spec.add_dependency "fugit", "~> 1.12"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
end
