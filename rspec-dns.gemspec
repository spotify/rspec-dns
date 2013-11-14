Gem::Specification.new do |s|
  s.version       = '0.0.3'
  s.name          = 'rspec-dns'
  s.author        = 'Seth Vargo'
  s.email         = 'sethvargo@gmail.com'
  s.description   = 'Easily test your DNS entries with RSpec'
  s.summary       = 'rspec-dns provides an easy-to-use DSL for testing your DNS records are responding as they should.'
  s.homepage      = 'https://github.com/customink/rspec-dns'
  s.license       = 'Apache 2.0'

  s.files         = `git ls-files`.split($\)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_dependency 'rake'
  s.add_dependency 'rspec', '>= 2.9'
end
