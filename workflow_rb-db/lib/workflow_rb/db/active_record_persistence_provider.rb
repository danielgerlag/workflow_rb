require 'workflow_rb'
require 'workflow_rb/db/entities'

module WorkflowRb
  module Db
    class ActiveRecordPersistenceProvider

      def initialize
      end

      def create_new_workflow(workflow)
        rec = WorkflowRb::Db::WorkflowInstance.new
        rec.pack(workflow)
        rec.save!
        rec.id
      end

      def persist_workflow(workflow)
        existing = WorkflowRb::Db::WorkflowInstance.find(workflow.id)
        existing.pack(workflow)
        existing.save!
      end

      def get_workflow_instance(id)
        rec = WorkflowRb::Db::WorkflowInstance.find(id)
        rec.unpack
      end

      def get_runnable_instances
        result = []
        next_execution = WorkflowRb::Db::WorkflowInstance.arel_table[:next_execution]
        WorkflowRb::Db::WorkflowInstance
            .where(status: WorkflowStatus::RUNNABLE)
            .where(next_execution.lteq(Time.now))
            .find_each do |wf|
              result << wf.unpack.id
            end
        result
      end

      def create_subscription(subscription)
        rec = WorkflowRb::Db::EventSubscription.new
        rec.pack(subscription)
        rec.save!
        rec.id
      end

      def get_subscriptions(event_name, event_key)
        WorkflowRb::Db::EventSubscription
            .where(event_name: event_name)
            .where(event_key: event_key)
      end

      def terminate_subscription(id)
        WorkflowRb::Db::EventSubscription.delete(id)
      end

      def create_unpublished_event(pub)
        rec = WorkflowRb::Db::EventPublication.new
        rec.pack(pub)
        rec.save!
      end

      def remove_unpublished_event(id)
        WorkflowRb::Db::EventPublication.delete(id)
      end

      def get_unpublished_events
        WorkflowRb::Db::EventPublication.all
      end

    end
  end
end
