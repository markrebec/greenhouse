$:.push File.expand_path("../lib", __FILE__)
require "greenhouse/version"

Gem::Specification.new do |s|
  s.name        = "greenhouse"
  s.version     = Greenhouse::VERSION
  s.summary     = "Suite of tools for working on an entire 'ecosystem' of ruby gems and applications."
  s.description = "Greenhouse provides a suite of tools that make working with multiple ruby projects easier, such as in an ecosystem of applications and gems, particularly when there are inter-dependencies."
  s.homepage    = "http://github.com/markrebec/greenhouse"
  s.authors     = ["Mark Rebec"]
  s.email       = ["mark@markrebec.com"]
  
  s.files       = Dir["lib/**/*", "bin/**/*"]
  s.test_files  = Dir["spec/**/*"]

  s.executables = "greenhouse"

  s.add_dependency "bundler"
  s.add_dependency "git"
  s.add_dependency "foreman"
  s.add_dependency "activesupport"

  s.add_development_dependency "rspec"
end
