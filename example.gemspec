# frozen_string_literal: true

require_relative "lib/example/version"

Gem::Specification.new do |spec|
  spec.name = "example"
  spec.version = Example::VERSION
  spec.authors = ["Osman Khwaja"]
  spec.email = ["osman.khwaja@instacart.com"]

  spec.summary = "some example string"
  spec.description = "some example string"
  spec.homepage = "https://example.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "some example string"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://example.com"
  spec.metadata["changelog_uri"] = "https://example.com"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "activesupport"
  spec.add_dependency "opentracing"
  spec.add_dependency "ddtrace", "~> 1.2"
  spec.add_dependency "dogstatsd-ruby", "~> 5.5"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack" # rack/mock
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry-byebug"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
