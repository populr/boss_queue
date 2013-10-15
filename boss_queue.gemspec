# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "boss_queue"
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Nelson"]
  s.date = "2013-10-15"
  s.description = "A fault tolerant job queue built around Amazon SQS & DynamoDB"
  s.email = "daniel@populr.me"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    ".rspec",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.md",
    "Rakefile",
    "VERSION",
    "boss_queue.gemspec",
    "lib/boss_queue.rb",
    "lib/boss_queue/boss_queue.rb",
    "lib/boss_queue/job.rb",
    "spec/boss_queue_spec.rb",
    "spec/job_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "https://github.com/populr/boss_queue"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.25"
  s.summary = "A fault tolerant job queue built around Amazon SQS & DynamoDB"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<aws-sdk>, [">= 1.19.0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<bundler>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
      s.add_development_dependency(%q<pry>, [">= 0"])
      s.add_development_dependency(%q<pry-nav>, [">= 0"])
      s.add_development_dependency(%q<pry-stack_explorer>, [">= 0"])
    else
      s.add_dependency(%q<aws-sdk>, [">= 1.19.0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
      s.add_dependency(%q<pry>, [">= 0"])
      s.add_dependency(%q<pry-nav>, [">= 0"])
      s.add_dependency(%q<pry-stack_explorer>, [">= 0"])
    end
  else
    s.add_dependency(%q<aws-sdk>, [">= 1.19.0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
    s.add_dependency(%q<pry>, [">= 0"])
    s.add_dependency(%q<pry-nav>, [">= 0"])
    s.add_dependency(%q<pry-stack_explorer>, [">= 0"])
  end
end

