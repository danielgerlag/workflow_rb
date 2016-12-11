# WorkflowRb::Mongo

Provides support to persist workflows running on WorkflowRb to a MongoDB database.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'workflow_rb-mongo'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install workflow_rb-mongo

## Usage

Setup a mongoid.yml config file with the *workflow_rb* client

```yaml
development:
  clients:
    default:
      database: mongoid
      hosts:
        - localhost:27017
    workflow_rb:
      database: workflow-ruby
      hosts:
        - localhost:27017
```

Use the *.use_persistence* method on the *WorkflowHost* to configure it to use the Mongo provider

```ruby
require 'workflow_rb/mongo'
require 'mongoid'

Mongoid.load!("mongoid.yml", :development)
# create host
host = WorkflowRb::WorkflowHost.new
host.use_persistence(WorkflowRb::Mongo::MongoPersistenceProvider.new)
```
