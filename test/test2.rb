require 'yaml'
require 'mongo'
require 'bson'
require 'json'
require 'mongoid'


Mongoid.load!("mongoid.yml", :development)

class PersistedWorkflow

  include Mongoid::Document
  store_in collection: "workflow", client: "workflow_rb"

  #field :id
  field :definition_id
  field :version
  field :description
  field :execution_pointers
  field :next_execution
  field :status
  field :data
  field :create_time
  field :complete_time

end


existing = PersistedWorkflow.find('5849ee0d7a6a4f328878bdb7')

puts existing.execution_pointers