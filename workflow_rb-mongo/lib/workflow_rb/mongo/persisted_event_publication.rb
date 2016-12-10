require 'mongoid'
require 'yaml'
require 'workflow_rb'

module WorkflowRb
  module Mongo
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

