module WorkflowRb

  class WorkflowStep
    attr_accessor :id
    attr_accessor :name

    attr_accessor :body
    attr_accessor :outcomes
    attr_accessor :inputs
    attr_accessor :outputs

    def initialize
      @outcomes = []
      @inputs = []
      @outputs = []
    end


  end

end