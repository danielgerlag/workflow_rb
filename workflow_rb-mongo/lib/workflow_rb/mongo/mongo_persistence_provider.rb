require 'mongoid'
require 'yaml'
require 'workflow_rb'
require 'workflow_rb/mongo/persisted_workflow'
require 'workflow_rb/mongo/persisted_event_subscription'
require 'workflow_rb/mongo/persisted_event_publication'

module WorkflowRb
  module Mongo
    class MongoPersistenceProvider

      def initialize
      end

      def create_new_workflow(workflow)
        p = PersistedWorkflow.new
        workflow.fill_persisted(p)
        p.save
        workflow.id = p._id
        p._id
      end

      def persist_workflow(workflow)
        existing = PersistedWorkflow.find(workflow.id)
        workflow.fill_persisted(existing)
        existing.save
      end

      def get_workflow_instance(id)
        existing = PersistedWorkflow.find(id)
        existing.to_object
      end

      def get_runnable_instances
        PersistedWorkflow
            .where(status: WorkflowRb::WorkflowStatus::RUNNABLE)
            .and(:next_execution.lte => Time.new)
      end

      def create_subscription(subscription)
        p = PersistedEventSubscription.new
        subscription.fill_persisted(p)
        p.save
        subscription.id = p._id
        p._id
      end

      def get_subscriptions(event_name, event_key)
        PersistedEventSubscription
            .where(event_name: event_name)
            .and(event_key: event_key)
      end

      def terminate_subscription(id)
        existing = PersistedEventSubscription.find(id)
        existing.delete
      end

      def create_unpublished_event(pub)
        p = PersistedEventPublication.new
        pub.fill_persisted(p)
        p.save
        pub.id = p._id
        p._id
      end

      def remove_unpublished_event(id)
        existing = PersistedEventPublication.find(id)
        existing.delete
      end

      def get_unpublished_events
        PersistedEventPublication.all
      end
    end
  end
end


