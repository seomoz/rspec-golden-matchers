source 'https://rubygems.org'

# Specify your gem's dependencies in rspec-golden-matchers.gemspec
gemspec

gem 'rake', '>= 10'

# This group is excluded from both deployments and travis,
# so it's an ideal place for gems that only get used
# locally by developers for one-off tasks.
group :development do
  gem 'byebug'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'
end
