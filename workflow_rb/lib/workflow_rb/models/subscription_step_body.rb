require 'workflow_rb/models/step_body'
require 'workflow_rb/models/execution_result'

module WorkflowRb
  class SubscriptionStepBody < StepBody
    attr_accessor :event_data
    def run(context)
      WorkflowRb::ExecutionResult.NextStep
    end
  end
end