Gem::Specification.new do |s|
  s.name = 'culturecode-acts_as_taggable'
  s.version = '0.2.3'
  s.email = 'contact@culturecode.ca'
  s.homepage = 'http://github.com/culturecode/acts_as_taggable'
  s.summary = 'Simple record tagging'
  s.authors = ['Nicholas Jakobsen', 'Ryan Wallace']
  
  s.files = Dir['lib/**/*'] + ["README.rdoc"]

  s.add_dependency "activerecord", ">= 4.2"
  s.add_development_dependency('rspec-rails', '~> 3.0.0')
  s.add_development_dependency "sqlite3"
end
