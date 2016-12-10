lib = File.expand_path('../../lib', __FILE__)
#puts lib
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'workflow_rb'
require './mongo_persistence_provider'
require 'mongoid'

Mongoid.load!("mongoid.yml", :development)

class MyData
  attr_accessor :value1
  attr_accessor :value2
  attr_accessor :value3
end

class HelloWorld < WorkflowRb::StepBody
  def run(context)
    puts 'Hello world'
    WorkflowRb::ExecutionResult.NextStep
  end
end

class GoodbyeWorld < WorkflowRb::StepBody
  def run(context)
    puts "Good bye world - #{context.step.name}"
    WorkflowRb::ExecutionResult.NextStep
  end
end

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


class HelloWorld_Workflow
  ID = 'hello world'
  VERSION = 1
  DATA_CLASS = MyData

  def build(builder)
    builder
        .start_with(HelloWorld)
        .then(AddNumbers)
          .input(:input1) {|data| data.value1}
          .input(:input2) {|data| data.value2}
          .output(:value3) {|step| step.answer}
        .then(CustomMessage)
        .input(:message) {|data| "The answer is #{data.value3}"}
        .then_step do |context|
      puts "middle 3"
      WorkflowRb::ExecutionResult.NextStep
    end
        .then(GoodbyeWorld)
        .name("your step")

  end
end

class EventSample_Workflow
  ID = 'event-sample'
  VERSION = 1
  DATA_CLASS = MyData

  def build(builder)
    builder
        .start_with(HelloWorld)
          .wait_for('my-event', '0')
          .output(:value1) { |step| step.event_data }
        .then(CustomMessage)
          .input(:message) {|data| "The event data is #{data.value1}"}

  end
end


logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

host = WorkflowRb::WorkflowHost.new
#host.use_logger(logger)
host.use_persistence(MongoPersistenceProvider.new)
host.register_workflow(HelloWorld_Workflow)
host.register_workflow(EventSample_Workflow)
host.start

data = MyData.new
data.value1 = 2
data.value2 = 3

#host.start_workflow('hello world', 1, data)

host.start_workflow('event-sample', 1)

puts 'Enter value to publish:'
event_data = gets

host.publish_event('my-event', '0', event_data)

gets
host.stop
puts 'done'

