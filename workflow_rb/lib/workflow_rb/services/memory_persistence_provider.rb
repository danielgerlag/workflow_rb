require 'securerandom'
require 'workflow_rb/models/workflow_instance'

module WorkflowRb

  class MemoryPersistenceProvider

    def initialize
      @instances = []
      @subscriptions = []
      @unpublished_events = []
      @semaphore = Mutex.new
    end

    def create_new_workflow(workflow)
      workflow.id = SecureRandom.uuid
      @instances << workflow
      workflow.id
    end

    def persist_workflow(workflow)
      @semaphore.synchronize do
        @instances.delete_if {|item| item.id == workflow.id }
        @instances << workflow
      end
    end

    def get_workflow_instance(id)
      @instances.select {|item| item.id == id}.first
    end

    def get_runnable_instances
      @instances.select {|item| item.next_execution and (item.next_execution <= Time.new) and (item.status == WorkflowStatus::RUNNABLE)}
          .map {|item| item.id}
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
