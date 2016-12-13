# WorkflowRb::Db

Provides support to persist workflows running on WorkflowRb to a database supported by Active Record.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'workflow_rb-db'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install workflow_rb-db

## Usage

Setup a database.yml config file with a "workflow" section

```yaml
workflow:
  adapter: postgresql
  encoding: unicode
  database: workflow_rb
  pool: 12
  username: postgres
  password: password
  host: localhost
  port: 5432
```

Add the tables to your database

```ruby
db_config = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection(db_config['workflow'])
schema = WorkflowRb::Db::Schema.new
schema.up
```

Use the *.use_persistence* method on the *WorkflowHost* to configure it to use the ActiveRecord provider

```ruby
require 'workflow_rb/db'
require 'yaml'

db_config = YAML.load_file('database.yml')
WorkflowRb::Db::WorkflowRecord.establish_connection(db_config['workflow'])

# create host
host = WorkflowRb::WorkflowHost.new
host.use_persistence(WorkflowRb::Db::ActiveRecordPersistenceProvider.new)
```
