# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name             = 'rspec-golden-matchers'
  gem.authors          = ['vadim-moz']
  gem.email            = ['vadim@moz.com']
  gem.description      = %q{RSpec Golden Matcher}
  gem.summary          = %q{RSpec Golden Matcher}
  gem.license          = 'MIT'
  gem.version          = '0.1'
  gem.homepage          = 'https://github.com/seomoz/rspec-golden-matchers'

  gem.files            = %w(README.md) + Dir['lib/**/*.rb']
  gem.test_files       = Dir['spec/**/*.rb']
  gem.require_path     = 'lib'
  gem.extra_rdoc_files = ['README.md', 'LICENSE']
  gem.require_paths    = ['lib']

  gem.add_runtime_dependency 'rspec',    '~> 3'
end

