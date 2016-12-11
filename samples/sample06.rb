require 'workflow_rb'

# Define some steps
class RandomStep < WorkflowRb::StepBody
  def run(context)
    WorkflowRb::ExecutionResult.Outcome(rand(2))
  end
end

class TaskA < WorkflowRb::StepBody
  def run(context)
    puts 'Task A'
    WorkflowRb::ExecutionResult.NextStep
  end
end

class TaskB < WorkflowRb::StepBody
  def run(context)
    puts 'Task B'
    WorkflowRb::ExecutionResult.NextStep
  end
end

class TaskC < WorkflowRb::StepBody
  def run(context)
    puts 'Task C'
    WorkflowRb::ExecutionResult.NextStep
  end
end

class TaskD < WorkflowRb::StepBody
  def run(context)
    puts 'Task D'
    WorkflowRb::ExecutionResult.NextStep
  end
end

# Define a workflow to put the steps together
class ForkSample_Workflow
  ID = 'fork-sample'
  VERSION = 1
  DATA_CLASS = nil

  def build(builder)
    step1 = builder.start_with(RandomStep)
    step1.when(0)
      .then(TaskA)
      .then(TaskB)

    step1.when(1)
      .then(TaskC)
      .then(TaskD)

  end
end

# create host
host = WorkflowRb::WorkflowHost.new

# uncomment this section to get more detailed logs
# logger = Logger.new(STDOUT)
# logger.level = Logger::DEBUG
# host.use_logger(logger)

# register our workflows with the host
host.register_workflow(ForkSample_Workflow)

# start the host
host.start

# start a new workflow
host.start_workflow('fork-sample', 1)

gets
host.stop



