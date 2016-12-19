require 'workflow_rb'

# Define some steps
class HelloWorld < WorkflowRb::StepBody
  def run(context)
    puts 'Hello world'
    WorkflowRb::ExecutionResult.NextStep
  end
end

class CustomMessage < WorkflowRb::StepBody
  attr_accessor :message
  def run(context)
    puts @message
    WorkflowRb::ExecutionResult.NextStep
  end
end

# Define a class to hold workflow data
class MyData
  attr_accessor :my_value
end


# Define a workflow to put the steps together
class EventSample_Workflow
  ID = 'event-sample'
  VERSION = 1
  DATA_CLASS = MyData

  def build(builder)
    builder
        .start_with(HelloWorld)
        .wait_for('my-event', '0')
          .output(:my_value) { |step| step.event_data }
        .then(CustomMessage)
          .input(:message) {|data| "The event data is #{data.my_value}"}
  end
end

# create host
host = WorkflowRb::WorkflowHost.new

# uncomment this section to get more detailed logs
# logger = Logger.new(STDOUT)
# logger.level = Logger::DEBUG
# host.use_logger(logger)

# register our workflows with the host
host.register_workflow(EventSample_Workflow)

# start the host
host.start

# start a new workflow
host.start_workflow('event-sample', 1)

puts 'Enter value to publish:'
event_data = gets

host.publish_event('my-event', '0', event_data)

gets
host.stop


