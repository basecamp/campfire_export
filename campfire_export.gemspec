# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "campfire_export/version"

Gem::Specification.new do |s|
  s.name        = "stackbuilders-campfire_export"
  s.version     = CampfireExport::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Marc Hedlund", "Justin Leitgeb"]
  s.email       = ["marc@precipice.org", "justin@stackbuilders.com"]
  s.license     = "Apache 2.0"
  s.homepage    = "https://github.com/stackbuilders/campfire_export"
  s.summary     = "Export transcripts and uploaded files from your 37signals' Campfire account."

  s.description = %{Exports content from all rooms in a
    37signals Campfire account. Creates a directory containing transcripts
    and content uploaded to each one of your rooms. Can be configured to
    recognize start and end date of content export.}

  s.rubyforge_project = "campfire_export"
  s.required_ruby_version = '>= 1.9.3'

  s.add_development_dependency "bundler",  "~> 1"
  s.add_development_dependency "rake", "~> 10"
  s.add_development_dependency "rspec",    "~> 2.6"

  s.add_dependency "tzinfo",   "~> 1.2"
  s.add_dependency "httparty", "~> 0.13"
  s.add_dependency "nokogiri", "~> 1.6"
  s.add_dependency "retryable", "~> 2.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
