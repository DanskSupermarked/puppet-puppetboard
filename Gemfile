source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gem 'metadata-json-lint'
gem 'puppet', ENV['PUPPET_GEM_VERSION']
gem 'puppetlabs_spec_helper', '>= 1.0.0'
gem 'puppet-lint', '>= 1.0.0'
gem 'facter', ENV['FACTER_GEM_VERSION']
gem 'hiera'
gem 'rspec-puppet'
gem 'rspec-puppet-facts', :require => false

# rspec must be v2 for ruby 1.8.7
if RUBY_VERSION >= '1.8.7' && RUBY_VERSION < '1.9'
  gem 'rspec', '~> 2.0'
  gem 'rake', '~> 10.0'
else
  # rubocop requires ruby >= 1.9
  gem 'rubocop'
end
