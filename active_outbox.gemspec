# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.authors               = ['Guillermo Aguirre']
  spec.files                 = Dir['LICENSE.txt', 'README.md', 'lib/**/*', 'lib/active_outbox.rb']
  spec.name                  = 'active_outbox'
  spec.summary               = 'A Transactional Outbox implementation for ActiveRecord'
  spec.version               = '0.1.4'

  spec.email                 = 'guillermoaguirre1@gmail.com'
  spec.executables           = ['outbox']
  spec.homepage              = 'https://rubygems.org/gems/active_outbox'
  spec.license               = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.add_dependency 'dry-configurable', '~> 1.0'
  spec.add_dependency 'rails', '>= 6.1'
end
