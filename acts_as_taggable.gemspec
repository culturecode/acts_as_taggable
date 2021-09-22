$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "acts_as_taggable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "culturecode-acts_as_taggable"
  s.version     = ActsAsTaggable::VERSION
  s.authors     = ['Nicholas Jakobsen', 'Ryan Wallace']
  s.email       = 'contact@culturecode.ca'
  s.homepage    = 'http://github.com/culturecode/acts_as_taggable'
  s.summary     = 'Simple record tagging'
  s.description = 'Simple record tagging'
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "activerecord", [">= 4.2.0", "< 7"]
  s.add_development_dependency "rspec-rails", "~> 3"
  s.add_development_dependency "sqlite3"
end
