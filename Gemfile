# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'codecov', require: false

gem 'rake', '~> 12.0'
gem 'rspec-github', '~> 2.3'

gem 'rubocop', '~> 1.0'
gem 'rubocop-performance', '~> 1.9.2'
gem 'rubocop-rake', '~> 0.5.1'
gem 'rubocop-rspec', '~> 2.1.0'

# webpacker-4.3.0 default webpacker yml config
# incompatible with ruby-3.1 (comes with psych-4)
gem 'psych', '< 4'

group :development do
  gem 'benchmark-ips', require: false
  gem 'pry-byebug', '~> 3.9'
end
