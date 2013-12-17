Gem::Specification.new do |s|
  # About the gem
  s.name        = 'multilog'
  s.version     = '0.1.0a'
  s.date        = '2013-12-19'
  s.summary     = 'A multiple-output extension of ruby\'s Logger'
  s.description = 'A drop-in replacement for ruby\'s Logger supporting multiple outputs at various levels'
  s.author      = 'Stephen Wattam'
  s.email       = 'stephenwattam@gmail.com'
  s.homepage    = 'http://stephenwattam.com/git/cgit.cgi/multilog/'
  s.required_ruby_version =  ::Gem::Requirement.new(">= 2.0")
  s.license     = 'Beerware' # Creative commons by-nc-sa 3
  
  # Files + Resources
  s.files         = Dir.glob("lib/*")
  s.require_paths = ['lib']
  
  # Documentation
  s.has_rdoc         = false

  # Deps
  # s.add_runtime_dependency 'blat',     '~> 0.1'

end


