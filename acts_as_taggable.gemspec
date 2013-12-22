Gem::Specification.new do |s|
  s.name = 'acts_as_taggable'
  s.version = '0.3.1'
  s.email = 'contact@culturecode.ca'
  s.homepage = 'http://github.com/culturecode/acts_as_taggable'
  s.summary = 'Simple record tagging'
  s.authors = ['Nicholas Jakobsen', 'Ryan Wallace']

  s.files = Dir['lib/**/*'] + ["README.rdoc"]

  s.add_dependency('rails', '~> 4.0')
end
