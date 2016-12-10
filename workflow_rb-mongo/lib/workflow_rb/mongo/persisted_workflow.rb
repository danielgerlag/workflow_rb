require 'mongoid'
require 'yaml'
require 'workflow_rb'

module WorkflowRb
  module Mongo
    class PersistedWorkflow
      include Mongoid::Document
      store_in collection: "workflows", client: "workflow_rb"

      field :definition_id
      field :version
      field :description
      field :execution_pointers
      field :next_execution
      field :status
      field :data
      field :create_time
      field :complete_time

      def to_object
        result = WorkflowRb::WorkflowInstance.new
        result.id = self._id
        result.definition_id = self.definition_id
        result.version = self.version
        result.description = self.description
        result.execution_pointers = YAML.load(self.execution_pointers)
        result.next_execution = self.next_execution
        result.status = self.status
        result.data = YAML.load(self.data)
        result.create_time = self.create_time
        result.complete_time = self.complete_time
        result
      end

    end
  end

  class WorkflowInstance

    def fill_persisted(result)
      #result._id = @id
      result.definition_id = @definition_id
      result.version = @version
      result.description = @description
      result.execution_pointers = YAML.dump(@execution_pointers)
      result.next_execution = @next_execution
      result.status = @status
      result.data = YAML.dump(@data)
      result.create_time = @create_time
      result.complete_time = @complete_time
      result
    end
  end
end

