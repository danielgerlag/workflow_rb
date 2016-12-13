require 'securerandom'
require 'workflow_rb'
require '../test/active_record/entities'


module WorkflowRb
  module Db
    class ActiveRecordPersistenceProvider

      def initialize
        @subscriptions = []
        @unpublished_events = []
        @semaphore = Mutex.new
      end

      def create_new_workflow(workflow)
        rec = WorkflowRb::Db::WorkflowInstance.new
        rec.pack(workflow)
        rec.save!
        rec.id
      end

      def persist_workflow(workflow)
        existing = WorkflowRb::Db::WorkflowInstance.find_by!(workflow.id.to_i)
        existing.pack(workflow)
        existing.save!
      end

      def get_workflow_instance(id)
        rec = WorkflowRb::Db::WorkflowInstance.find_by!(id.to_i)
        rec.unpack
      end

      def get_runnable_instances
        result = []
        WorkflowRb::Db::WorkflowInstance.where(status: WorkflowStatus::RUNNABLE).find_each do |wf|
          result << wf.unpack
        end
        result
      end

      def create_subscription(subscription)
        subscription.id = SecureRandom.uuid
        @subscriptions << subscription
        subscription.id
      end

      def get_subscriptions(event_name, event_key)
        @subscriptions.select { |sub| sub.event_name == event_name and sub.event_key == event_key }
      end

      def terminate_subscription(id)
        @semaphore.synchronize do
          @subscriptions.delete_if { |sub| sub.id == id }
        end
      end

      def create_unpublished_event(pub)
        @unpublished_events << pub
      end

      def remove_unpublished_event(id)
        @unpublished_events.delete_if { |pub| pub.id == id }
      end

      def get_unpublished_events
        @unpublished_events
      end

    end
  end
end
