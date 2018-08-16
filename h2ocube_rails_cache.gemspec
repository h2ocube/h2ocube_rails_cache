# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = 'h2ocube_rails_cache'
  gem.version       = '0.4.0'
  gem.authors       = ['Ben']
  gem.email         = ['ben@h2ocube.com']
  gem.description   = 'Just an redis cache.'
  gem.summary       = 'Just an redis cache.'
  gem.homepage      = 'https://github.com/h2ocube/h2ocube_rails_cache'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'redis'
  gem.add_dependency 'hiredis'

  %w[rails minitest-rails].each { |g| gem.add_development_dependency g }
end
