# frozen_string_literal: true

require_relative "lib/yaparc"

Gem::Specification.new do |spec|
  spec.name = "yaparc"
  spec.version = Yaparc::VERSION
  spec.authors = ["Akimichi Tatsukawa", "gemmaro"]
  spec.email = ["akimichi.tatsukawa@gmail.com", "gemmaro.dev@gmail.com"]

  spec.summary = "Yet another simple parser combinator library"
  spec.homepage = homepage = "https://git.disroot.org/gemmaro/yaparc"
  spec.required_ruby_version = ">= 3.1.6"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end

  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "test-unit"

  spec.metadata = {
    'rubygems_mfa_required' => 'true',
    'bug_tracker_uri'       => "#{homepage}/issues",
    'changelog_uri'         => "#{homepage}/src/branch/main/CHANGELOG.md",
    'documentation_uri'     => "https://rubydoc.info/gems/yaparc",
    'homepage_uri'          => homepage,
    'source_code_uri'       => homepage,
    'wiki_uri'              => "#{homepage}/wiki",
  }
end
