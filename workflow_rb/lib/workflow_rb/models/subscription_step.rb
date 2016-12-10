require 'workflow_rb/models/workflow_step'
require 'workflow_rb/models/subscription_step_body'

module WorkflowRb
  class SubscriptionStep < WorkflowStep
    attr_accessor :event_name
    attr_accessor :event_key

    def initialize
      super
      @body = SubscriptionStepBody
    end

  end
end