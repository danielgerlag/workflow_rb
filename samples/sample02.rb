require 'workflow_rb'

# Define some steps
class AddNumbers < WorkflowRb::StepBody
  attr_accessor :input1
  attr_accessor :input2
  attr_accessor :answer

  def run(context)
    @answer = @input1 + @input2
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
  attr_accessor :value1
  attr_accessor :value2
  attr_accessor :value3
end


# Define a workflow to put the steps together
class DataSample_Workflow
  ID = 'data-sample'
  VERSION = 1
  DATA_CLASS = MyData

  def build(builder)
    builder
        .start_with(AddNumbers)
          .input(:input1) {|data| data.value1}
          .input(:input2) {|data| data.value2}
          .output(:value3) {|step| step.answer}
        .then(CustomMessage)
          .input(:message) {|data| "The answer is #{data.value3}"}
  end
end

# create host
host = WorkflowRb::WorkflowHost.new

# uncomment this section to get more detailed logs
# logger = Logger.new(STDOUT)
# logger.level = Logger::DEBUG
# host.use_logger(logger)

# register our workflows with the host
host.register_workflow(DataSample_Workflow)

# start the host
host.start

# start a new workflow
my_data = MyData.new
my_data.value1 = 2
my_data.value2 = 3
host.start_workflow('data-sample', 1, my_data)

gets
host.stop



