module WorkflowRb

  class WorkflowDefinition
    attr_accessor :id
    attr_accessor :version
    attr_accessor :data_class
    attr_accessor :initial_step
    attr_accessor :steps

    def initialize
      @steps = []
    end


  end

end