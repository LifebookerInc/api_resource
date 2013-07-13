# -*- encoding: utf-8 -*-
require File.expand_path('../lib/api_resource/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ethan Langevin", "Dan Langevin", "Brian Howald"]
  gem.email         = ["developers@lifebooker.com"]
  gem.description   = %q{A replacement for ActiveResource for RESTful APIs that handles associated object and multiple data sources}
  gem.summary       = %q{ActiveRecord for restful APIs}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "api_resource"
  gem.require_paths = ["lib"]
  gem.version       = ApiResource::VERSION

  # Development Dependencies
  gem.add_development_dependency "rake"
  gem.add_development_dependency "yarjuf"
  # this latest version of mocha is not compatible with the rails
  # 3.2.9
  gem.add_development_dependency "mocha", ["=0.12.7"]
  gem.add_development_dependency "faker"
  gem.add_development_dependency "guard-bundler"
  gem.add_development_dependency "guard-rspec"
  gem.add_development_dependency "guard-spork"
  gem.add_development_dependency "growl"
  gem.add_development_dependency "flay"
  gem.add_development_dependency "flog"
  gem.add_development_dependency "hash_dealer"
  gem.add_development_dependency "rb-fsevent"
  gem.add_development_dependency "byebug"
  gem.add_development_dependency "simplecov"

  gem.add_dependency "rails"
  gem.add_dependency 'activemodel'
  gem.add_dependency "json"
  gem.add_dependency "rest-client"
  gem.add_dependency "log4r"
  gem.add_dependency "differ"
  gem.add_dependency "colorize"
end
