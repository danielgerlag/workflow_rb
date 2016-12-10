module WorkflowRb

  class WorkflowInstance
    attr_accessor :id
    attr_accessor :definition_id
    attr_accessor :version
    attr_accessor :description
    attr_accessor :execution_pointers
    attr_accessor :next_execution
    attr_accessor :status
    attr_accessor :data
    attr_accessor :create_time
    attr_accessor :complete_time

    def initialize
      @execution_pointers = []

    end

  end

  class WorkflowStatus
    RUNNABLE = 0
    SUSPENDED = 1
    COMPLETE = 2
    TERMINATED = 3
  end


end