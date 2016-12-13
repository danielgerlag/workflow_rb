require 'workflow_rb'
require '../test/active_record/active_record_persistence_provider'

db_config = YAML.load_file('database.yml')
WorkflowRb::Db::WorkflowRecord.establish_connection(db_config['workflow'])


# Define some steps
class HelloWorld < WorkflowRb::StepBody
  def run(context)
    puts 'Hello world'
    WorkflowRb::ExecutionResult.NextStep
  end
end

class GoodbyeWorld < WorkflowRb::StepBody
  def run(context)
    puts 'Goodbye world'
    WorkflowRb::ExecutionResult.NextStep
  end
end

# Define a workflow to put the steps together
class HelloWorld_Workflow
  ID = 'hello world'
  VERSION = 1
  DATA_CLASS = nil

  def build(builder)
    builder
        .start_with(HelloWorld)
        .then(GoodbyeWorld)
  end
end

# create host
host = WorkflowRb::WorkflowHost.new
host.use_persistence(WorkflowRb::Db::ActiveRecordPersistenceProvider.new)
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


