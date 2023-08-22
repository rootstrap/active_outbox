# Active Outbox
A Transactional Outbox implementation for ActiveRecord

# Goals
This gem aims to implement the event persistance side of the pattern, focusing only on providing a seamless way to store Outbox records whenever a change occurs on a given model.
We do not provide an event publisher, nor a consumer as a part of this gem since the idea is to keep it as light weight as possible.

# Basic Usage
Create an `Outbox` table using the provided generator and corresponding model.
```bash
rails g active_outbox outbox
```
After running the migration, create an initializer under `config/initializers/active_outbox.rb` and setup the default outbox class to the new `Outbox` model you just created.
```ruby
# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  ActiveOutbox.configure do |config|
    config.outbox_mapping = {
      'default' => 'Outbox'
    }
  end
end
```
To allow models to store Outbox records on changes, you will have to include the `Outboxable` concern.
```ruby
# app/models/user.rb

class User < ApplicationRecord
  include ActiveOutbox::Outboxable
end
```
