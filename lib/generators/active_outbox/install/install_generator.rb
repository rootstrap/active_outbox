require 'rails/generators/base'

module ActiveOutbox
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __dir__)

      desc 'Creates an initializer file at config/initializers/active_outbox.rb'

      def create_initializer_file
        copy_file('initializer.rb', 'config/initializers/active_outbox.rb')
      end
    end
  end
end
