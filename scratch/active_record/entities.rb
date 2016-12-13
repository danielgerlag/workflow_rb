require "active_record"
require "yaml"
require "workflow_rb"

module WorkflowRb
  module Db
    class WorkflowRecord < ActiveRecord::Base
      def self.abstract_class?
        true
      end
    end

    class WorkflowInstance < WorkflowRecord
      def self.abstract_class?
        false
      end

      def pack(workflow)
        # self.id = workflow.id
        self.definition_id = workflow.definition_id
        self.version = workflow.version
        self.description = workflow.description
        self.next_execution = workflow.next_execution
        self.status = workflow.status
        self.create_time = workflow.create_time
        self.complete_time = workflow.complete_time
        self.data = YAML.dump(workflow.data)
        self.execution_pointers = YAML.dump(workflow.execution_pointers)
      end

      def unpack
        result = WorkflowRb::WorkflowInstance.new
        result.id = self.id
        result.definition_id = self.definition_id
        result.version = self.version
        result.description = self.description
        result.next_execution = self.next_execution
        result.status = self.status
        result.create_time = self.create_time
        result.complete_time = self.complete_time
        result.data = YAML.load(self.data)
        result.execution_pointers = YAML.load(self.execution_pointers)

        result
      end

    end
  end
end


