Gem::Specification.new do |s|
  s.name        = 'active_outbox'
  s.version     = '0.0.2'
  s.summary     = 'ActiveOutbox'
  s.description = 'A Transactional Outbox implementation for ActiveRecord'
  s.authors     = ['Guillermo Aguirre']
  s.email       = 'guillermoaguirre1@gmail.com'
  s.files       = Dir['LICENSE.txt', 'README.md', 'lib/**/*', 'lib/active_outbox.rb']
  s.executables = ['outbox']
  s.homepage    =
    'https://rubygems.org/gems/active_outbox'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 2.7.0'

  # Dependencies
  s.add_dependency 'rails', '~> 7.0'

  # Development dependencies
  s.add_development_dependency 'byebug', '~> 11.1.3'
  s.add_development_dependency 'pry-rails', '~> 0.3.9'
  s.add_development_dependency 'reek', '~> 6.1.4'
  s.add_development_dependency 'rspec-rails', '~> 6.0.3'
  s.add_development_dependency 'rubocop', '~> 1.56.3'
  s.add_development_dependency 'simplecov', '~> 0.22.0'
  s.add_development_dependency 'sqlite3', '1.4.2'
end
