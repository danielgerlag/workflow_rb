module WorkflowRb

  class ExecutionPointer
    attr_accessor :step_id
    attr_accessor :active
    attr_accessor :persistence_data
    attr_accessor :start_time
    attr_accessor :end_time
    attr_accessor :sleep_until
    attr_accessor :event_name
    attr_accessor :event_key
    attr_accessor :event_published
    attr_accessor :event_data
    attr_accessor :concurrent_fork
    attr_accessor :path_terminator

  end

end