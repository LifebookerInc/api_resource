# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "api_resource"
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ethan Langevin"]
  s.date = "2012-10-24"
  s.description = "A replacement for ActiveResource for RESTful APIs that handles associated object and multiple data sources"
  s.email = "ejl6266@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rspec",
    ".travis.yml",
    "Gemfile",
    "Gemfile.lock",
    "Guardfile",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "api_resource.gemspec",
    "lib/api_resource.rb",
    "lib/api_resource/association_activation.rb",
    "lib/api_resource/associations.rb",
    "lib/api_resource/associations/association_proxy.rb",
    "lib/api_resource/associations/belongs_to_remote_object_proxy.rb",
    "lib/api_resource/associations/dynamic_resource_scope.rb",
    "lib/api_resource/associations/generic_scope.rb",
    "lib/api_resource/associations/has_many_remote_object_proxy.rb",
    "lib/api_resource/associations/has_many_through_remote_object_proxy.rb",
    "lib/api_resource/associations/has_one_remote_object_proxy.rb",
    "lib/api_resource/associations/multi_argument_resource_scope.rb",
    "lib/api_resource/associations/multi_object_proxy.rb",
    "lib/api_resource/associations/related_object_hash.rb",
    "lib/api_resource/associations/relation_scope.rb",
    "lib/api_resource/associations/resource_scope.rb",
    "lib/api_resource/associations/scope.rb",
    "lib/api_resource/associations/single_object_proxy.rb",
    "lib/api_resource/attributes.rb",
    "lib/api_resource/base.rb",
    "lib/api_resource/callbacks.rb",
    "lib/api_resource/connection.rb",
    "lib/api_resource/core_extensions.rb",
    "lib/api_resource/custom_methods.rb",
    "lib/api_resource/decorators.rb",
    "lib/api_resource/decorators/caching_decorator.rb",
    "lib/api_resource/exceptions.rb",
    "lib/api_resource/formats.rb",
    "lib/api_resource/formats/json_format.rb",
    "lib/api_resource/formats/xml_format.rb",
    "lib/api_resource/local.rb",
    "lib/api_resource/log_subscriber.rb",
    "lib/api_resource/mocks.rb",
    "lib/api_resource/model_errors.rb",
    "lib/api_resource/observing.rb",
    "lib/api_resource/railtie.rb",
    "lib/api_resource/scopes.rb",
    "nohup.out",
    "spec/lib/api_resource_spec.rb",
    "spec/lib/associations_spec.rb",
    "spec/lib/attributes_spec.rb",
    "spec/lib/base_spec.rb",
    "spec/lib/callbacks_spec.rb",
    "spec/lib/connection_spec.rb",
    "spec/lib/local_spec.rb",
    "spec/lib/mocks_spec.rb",
    "spec/lib/model_errors_spec.rb",
    "spec/lib/prefixes_spec.rb",
    "spec/spec_helper.rb",
    "spec/support/mocks/association_mocks.rb",
    "spec/support/mocks/error_resource_mocks.rb",
    "spec/support/mocks/prefix_model_mocks.rb",
    "spec/support/mocks/test_resource_mocks.rb",
    "spec/support/requests/association_requests.rb",
    "spec/support/requests/error_resource_requests.rb",
    "spec/support/requests/prefix_model_requests.rb",
    "spec/support/requests/test_resource_requests.rb",
    "spec/support/test_resource.rb",
    "spec/tmp/DIR"
  ]
  s.homepage = "http://github.com/ejlangev/resource"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.17"
  s.summary = "A replacement for ActiveResource for RESTful APIs that handles associated object and multiple data sources"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, ["~> 3"])
      s.add_runtime_dependency(%q<hash_dealer>, [">= 0"])
      s.add_runtime_dependency(%q<rest-client>, [">= 0"])
      s.add_runtime_dependency(%q<log4r>, [">= 0"])
      s.add_runtime_dependency(%q<differ>, [">= 0"])
      s.add_runtime_dependency(%q<colorize>, [">= 0"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_development_dependency(%q<pry>, [">= 0"])
      s.add_development_dependency(%q<pry-doc>, [">= 0"])
      s.add_development_dependency(%q<pry-nav>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<ruby-debug19>, [">= 0"])
      s.add_development_dependency(%q<growl>, [">= 0"])
      s.add_development_dependency(%q<rspec-rails>, [">= 0"])
      s.add_development_dependency(%q<factory_girl>, [">= 0"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
      s.add_development_dependency(%q<faker>, [">= 0"])
      s.add_development_dependency(%q<guard-bundler>, [">= 0"])
      s.add_development_dependency(%q<guard-rspec>, [">= 0"])
      s.add_development_dependency(%q<guard-spork>, [">= 0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
      s.add_development_dependency(%q<bundler>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<activerecord>, ["~> 3"])
      s.add_development_dependency(%q<sqlite3>, [">= 0"])
    else
      s.add_dependency(%q<rails>, ["~> 3"])
      s.add_dependency(%q<hash_dealer>, [">= 0"])
      s.add_dependency(%q<rest-client>, [">= 0"])
      s.add_dependency(%q<log4r>, [">= 0"])
      s.add_dependency(%q<differ>, [">= 0"])
      s.add_dependency(%q<colorize>, [">= 0"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<pry>, [">= 0"])
      s.add_dependency(%q<pry-doc>, [">= 0"])
      s.add_dependency(%q<pry-nav>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<ruby-debug19>, [">= 0"])
      s.add_dependency(%q<growl>, [">= 0"])
      s.add_dependency(%q<rspec-rails>, [">= 0"])
      s.add_dependency(%q<factory_girl>, [">= 0"])
      s.add_dependency(%q<simplecov>, [">= 0"])
      s.add_dependency(%q<faker>, [">= 0"])
      s.add_dependency(%q<guard-bundler>, [">= 0"])
      s.add_dependency(%q<guard-rspec>, [">= 0"])
      s.add_dependency(%q<guard-spork>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<activerecord>, ["~> 3"])
      s.add_dependency(%q<sqlite3>, [">= 0"])
    end
  else
    s.add_dependency(%q<rails>, ["~> 3"])
    s.add_dependency(%q<hash_dealer>, [">= 0"])
    s.add_dependency(%q<rest-client>, [">= 0"])
    s.add_dependency(%q<log4r>, [">= 0"])
    s.add_dependency(%q<differ>, [">= 0"])
    s.add_dependency(%q<colorize>, [">= 0"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<pry>, [">= 0"])
    s.add_dependency(%q<pry-doc>, [">= 0"])
    s.add_dependency(%q<pry-nav>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<ruby-debug19>, [">= 0"])
    s.add_dependency(%q<growl>, [">= 0"])
    s.add_dependency(%q<rspec-rails>, [">= 0"])
    s.add_dependency(%q<factory_girl>, [">= 0"])
    s.add_dependency(%q<simplecov>, [">= 0"])
    s.add_dependency(%q<faker>, [">= 0"])
    s.add_dependency(%q<guard-bundler>, [">= 0"])
    s.add_dependency(%q<guard-rspec>, [">= 0"])
    s.add_dependency(%q<guard-spork>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<activerecord>, ["~> 3"])
    s.add_dependency(%q<sqlite3>, [">= 0"])
  end
end

