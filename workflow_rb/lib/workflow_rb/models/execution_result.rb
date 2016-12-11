module WorkflowRb

  class ExecutionResult
    attr_accessor :proceed
    attr_accessor :outcome_value
    attr_accessor :persistence_data
    attr_accessor :sleep_until

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

    def self.Persist(data)
      result = ExecutionResult.new
      result.proceed = false
      result.persistence_data = data
      result
    end

    def self.Sleep(sleep_until, data)
      result = ExecutionResult.new
      result.proceed = false
      result.persistence_data = data
      result.sleep_until = sleep_until
      result
    end

  end

end