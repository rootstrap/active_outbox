# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.authors               = ['Guillermo Aguirre']
  spec.files                 = Dir['LICENSE.txt', 'README.md', 'lib/**/*', 'lib/active_outbox.rb']
  spec.name                  = 'active_outbox'
  spec.summary               = 'A Transactional Outbox implementation for ActiveRecord'
  spec.version               = '0.0.2'

  spec.email                 = 'guillermoaguirre1@gmail.com'
  spec.executables           = ['outbox']
  spec.homepage              = 'https://rubygems.org/gems/active_outbox'
  spec.license               = 'MIT'
  spec.required_ruby_version = '>= 2.7.8'

  spec.add_dependency 'rails', '~> 7.0.8'
end
