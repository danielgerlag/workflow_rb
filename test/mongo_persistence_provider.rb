require 'mongoid'
require 'yaml'
require 'workflow_rb'

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

class PersistedEventSubscription
  include Mongoid::Document
  store_in collection: "subscriptions", client: "workflow_rb"

  field :workflow_id
  field :step_id
  field :event_name
  field :event_key

  def to_object
    result = WorkflowRb::EventSubscription.new
    result.id = self._id
    result.workflow_id = self.workflow_id
    result.step_id = self.step_id
    result.event_name = self.event_name
    result.event_key = self.event_key
    result
  end
end

class PersistedEventPublication
  include Mongoid::Document
  store_in collection: "unpublished_events", client: "workflow_rb"

  field :workflow_id
  field :step_id
  field :event_name
  field :event_key
  field :event_data

  def to_object
    result = WorkflowRb::EventPublication.new
    result.id = self._id
    result.workflow_id = self.workflow_id
    result.step_id = self.step_id
    result.event_name = self.event_name
    result.event_key = self.event_key
    result.event_data = self.event_data
    result
  end
end

module WorkflowRb
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

  class EventSubscription
    def fill_persisted(result)
      result.workflow_id = @workflow_id
      result.step_id = @step_id
      result.event_name = @event_name
      result.event_key = @event_key
      result
    end
  end

  class EventPublication
    def fill_persisted(result)
      result.workflow_id = @workflow_id
      result.step_id = @step_id
      result.event_name = @event_name
      result.event_key = @event_key
      result.event_data = @event_data
      result
    end
  end
end




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
