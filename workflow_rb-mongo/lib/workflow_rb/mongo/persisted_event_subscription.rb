require 'mongoid'
require 'yaml'
require 'workflow_rb'

module WorkflowRb
  module Mongo
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
end

