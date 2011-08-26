# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{resource}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Ethan Langevin}]
  s.date = %q{2011-08-26}
  s.description = %q{A replacement for ActiveResource for RESTful APIs that handles associated object and multiple data sources}
  s.email = %q{ejl6266@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rspec",
    "Gemfile",
    "Guardfile",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/api_resource.rb",
    "lib/api_resource/associations.rb",
    "lib/api_resource/attributes.rb",
    "lib/api_resource/base.rb",
    "lib/api_resource/callbacks.rb",
    "lib/api_resource/connection.rb",
    "lib/api_resource/core_extensions.rb",
    "lib/api_resource/custom_methods.rb",
    "lib/api_resource/exceptions.rb",
    "lib/api_resource/formats.rb",
    "lib/api_resource/formats/json_format.rb",
    "lib/api_resource/formats/xml_format.rb",
    "lib/api_resource/log_subscriber.rb",
    "lib/api_resource/mocks.rb",
    "lib/api_resource/model_errors.rb",
    "lib/api_resource/observing.rb",
    "resource.gemspec",
    "spec/lib/associations_spec.rb",
    "spec/lib/attributes_spec.rb",
    "spec/lib/base_spec.rb",
    "spec/lib/callbacks_spec.rb",
    "spec/lib/model_errors_spec.rb",
    "spec/spec_helper.rb",
    "spec/support/mocks/association_mocks.rb",
    "spec/support/mocks/error_resource_mocks.rb",
    "spec/support/mocks/test_resource_mocks.rb",
    "spec/support/requests/association_requests.rb",
    "spec/support/requests/error_resource_requests.rb",
    "spec/support/requests/test_resource_requests.rb",
    "spec/support/test_resource.rb"
  ]
  s.homepage = %q{http://github.com/ejlangev/resource}
  s.licenses = [%q{MIT}]
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.8}
  s.summary = %q{A replacement for ActiveResource for RESTful APIs that handles associated object and multiple data sources}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, ["= 3.0.9"])
      s.add_runtime_dependency(%q<activeresource>, ["= 3.0.9"])
      s.add_runtime_dependency(%q<hash_dealer>, [">= 0"])
      s.add_runtime_dependency(%q<rest-client>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<ruby-debug19>, [">= 0"])
      s.add_development_dependency(%q<growl>, [">= 0"])
      s.add_development_dependency(%q<rspec-rails>, [">= 0"])
      s.add_development_dependency(%q<factory_girl>, [">= 0"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
      s.add_development_dependency(%q<faker>, [">= 0"])
      s.add_development_dependency(%q<guard>, [">= 0"])
      s.add_development_dependency(%q<guard-rspec>, [">= 0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
    else
      s.add_dependency(%q<rails>, ["= 3.0.9"])
      s.add_dependency(%q<activeresource>, ["= 3.0.9"])
      s.add_dependency(%q<hash_dealer>, [">= 0"])
      s.add_dependency(%q<rest-client>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<ruby-debug19>, [">= 0"])
      s.add_dependency(%q<growl>, [">= 0"])
      s.add_dependency(%q<rspec-rails>, [">= 0"])
      s.add_dependency(%q<factory_girl>, [">= 0"])
      s.add_dependency(%q<simplecov>, [">= 0"])
      s.add_dependency(%q<faker>, [">= 0"])
      s.add_dependency(%q<guard>, [">= 0"])
      s.add_dependency(%q<guard-rspec>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<rcov>, [">= 0"])
    end
  else
    s.add_dependency(%q<rails>, ["= 3.0.9"])
    s.add_dependency(%q<activeresource>, ["= 3.0.9"])
    s.add_dependency(%q<hash_dealer>, [">= 0"])
    s.add_dependency(%q<rest-client>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<ruby-debug19>, [">= 0"])
    s.add_dependency(%q<growl>, [">= 0"])
    s.add_dependency(%q<rspec-rails>, [">= 0"])
    s.add_dependency(%q<factory_girl>, [">= 0"])
    s.add_dependency(%q<simplecov>, [">= 0"])
    s.add_dependency(%q<faker>, [">= 0"])
    s.add_dependency(%q<guard>, [">= 0"])
    s.add_dependency(%q<guard-rspec>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<rcov>, [">= 0"])
  end
end

