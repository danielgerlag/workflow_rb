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

    class EventSubscription < WorkflowRecord
      def self.abstract_class?
        false
      end

      def pack(sub)
        self.workflow_id = sub.workflow_id
        self.step_id = sub.step_id
        self.event_name = sub.event_name
        self.event_key = sub.event_key
      end

      def unpack
        result = WorkflowRb::EventSubscription.new
        result.id = self.id
        result.workflow_id = self.workflow_id
        result.step_id = self.step_id
        result.event_name = self.event_name
        result.event_key = self.event_key
        result
      end

    end

    class EventPublication < WorkflowRecord
      def self.abstract_class?
        false
      end

      def pack(pub)
        self.workflow_id = pub.workflow_id
        self.step_id = pub.step_id
        self.event_name = pub.event_name
        self.event_key = pub.event_key
        self.event_data = YAML.dump(pub.event_data)
      end

      def unpack
        result = WorkflowRb::EventPublication.new
        result.id = self.id
        result.workflow_id = self.workflow_id
        result.step_id = self.step_id
        result.event_name = self.event_name
        result.event_key = self.event_key
        result.event_data = YAML.load(self.event_data)
        result
      end

    end

  end
end


