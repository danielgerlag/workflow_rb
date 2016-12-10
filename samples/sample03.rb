require 'workflow_rb'


# Define a workflow to put the steps together
class HelloWorld_Workflow
  ID = 'hello world'
  VERSION = 1
  DATA_CLASS = nil

  def build(builder)
    builder
        .start_step do |context|
          puts 'Hello world'
          WorkflowRb::ExecutionResult.NextStep
        end
        .then_step do |context|
          puts 'Goodbye world'
          WorkflowRb::ExecutionResult.NextStep
        end
  end
end

# create host
host = WorkflowRb::WorkflowHost.new

# uncomment this section to get more detailed logs
# logger = Logger.new(STDOUT)
# logger.level = Logger::DEBUG
# host.use_logger(logger)

# register our workflows with the host
host.register_workflow(HelloWorld_Workflow)

# start the host
host.start

# start a new workflow
host.start_workflow('hello world', 1)

gets
host.stop


