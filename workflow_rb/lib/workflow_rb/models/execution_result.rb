module WorkflowRb

  class ExecutionResult
    attr_accessor :proceed
    attr_accessor :outcome_value
    attr_accessor :persistence_data
    attr_accessor :sleep_for

    def self.NextStep
      result = ExecutionResult.new
      result.proceed = true
      result.outcome_value = nil
      result
    end

    def self.Outcome(value)
      result = ExecutionResult.new
      result.proceed = true
      result.outcome_value = value
      result
    end

  end

end