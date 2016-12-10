require 'workflow_rb'

module WorkflowRb
  class WorkflowBuilder

    attr_accessor :initial_step
    attr_accessor :steps

    def initialize
      @steps = []
    end

    def build(id, version, data_class)
      result = WorkflowDefinition.new
      result.id = id
      result.version = version
      result.data_class = data_class
      result.steps = @steps
      result.initial_step = @initial_step
      result
    end

    def add_step(step)
      step.id = @steps.length
      @steps << step
    end

    def start_with(body, &setup)
      new_step = WorkflowStep.new
      new_step.body = body

      if body.kind_of?(Class)
        new_step.name = body.name
      end

      add_step(new_step)
      @initial_step = new_step.id
      new_builder = StepBuilder.new(self, new_step)
      if setup
        setup.call(new_builder)
      end
      new_builder
    end

    def start_step(&body)
      start_with(body)
    end

  end

  class StepBuilder

    attr_accessor :step

    def initialize(workflow_builder, step)
      @workflow_builder = workflow_builder
      @step = step
    end

    def name(name)
      @step.name = name
    end

    # Adds a new step to the workflow
    #
    # @param body [Class] the step body implementation class
    def then(body, &setup)
      new_step = WorkflowStep.new
      new_step.body = body

      @workflow_builder.add_step(new_step)
      new_builder = StepBuilder.new(@workflow_builder, new_step)

      if body.kind_of?(Class)
        new_step.name = body.name
      end

      if setup
        setup.call(new_builder)
      end

      new_outcome = StepOutcome.new
      new_outcome.next_step = new_step.id
      new_outcome.value = nil
      @step.outcomes << new_outcome

      new_builder
    end

    def then_step(&body)
      self.then(body)
    end

    def when(value)
      new_outcome = StepOutcome.new
      new_outcome.value = value
      @step.outcomes << new_outcome
      new_builder = OutcomeBuilder.new(@workflow_builder, new_outcome)
      new_builder
    end

    # Map workflow instance data to a property on the step
    #
    # @param step_property [Symbol] the attribute on the step body class
    def input(step_property, &value)
      mapping = IOMapping.new
      mapping.property = step_property
      mapping.value = value
      @step.inputs << mapping
      self
    end

    def output(data_property, &value)
      mapping = IOMapping.new
      mapping.property = data_property
      mapping.value = value
      @step.outputs << mapping
      self
    end

    def wait_for(event_name, event_key)
      new_step = SubscriptionStep.new
      new_step.event_name = event_name
      new_step.event_key = event_key

      @workflow_builder.add_step(new_step)
      new_builder = StepBuilder.new(@workflow_builder, new_step)
      new_step.name = 'WaitFor'

      new_outcome = StepOutcome.new
      new_outcome.next_step = new_step.id
      new_outcome.value = nil
      @step.outcomes << new_outcome

      new_builder
    end

  end

  class OutcomeBuilder

    attr_accessor :outcome

    def initialize(workflow_builder, outcome)
      @workflow_builder = workflow_builder
      @outcome = outcome
    end

    def then(body, &setup)
      new_step = WorkflowStep.new
      new_step.body = body

      @workflow_builder.add_step(new_step)
      new_builder = StepBuilder.new(@workflow_builder, new_step)

      if setup
        setup.call(new_builder)
      end

      @outcome.next_step = new_step.id
      new_builder
    end

    def then_step(&body)
      self.then(body)
    end

  end


end

