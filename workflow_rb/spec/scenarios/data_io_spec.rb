require_relative '../spec_helper'
require 'yaml'
require 'workflow_rb/services/memory_persistence_provider'

describe "Data IO Workflow" do

  class AddNumbers < WorkflowRb::StepBody
    attr_accessor :input1
    attr_accessor :input2
    attr_accessor :answer

    def run(context)
      @answer = @input1 + @input2
      WorkflowRb::ExecutionResult.NextStep
    end
  end

  class MyData
    attr_accessor :value1
    attr_accessor :value2
    attr_accessor :value3
  end


  class DataWorkflow
    ID = 'data'
    VERSION = 1
    DATA_CLASS = MyData

    def build(builder)
      builder
          .start_with(AddNumbers)
            .input(:input1) {|data| data.value1}
            .input(:input2) {|data| data.value2}
            .output(:value3) {|step| step.answer}
    end
  end

  host = WorkflowRb::WorkflowHost.new
  persistence = WorkflowRb::MemoryPersistenceProvider.new
  host.use_persistence(persistence)
  logger = Logger.new(STDOUT)
  logger.level = Logger::DEBUG
  host.use_logger(logger)
  host.register_workflow(DataWorkflow)
  host.start

  my_data = MyData.new
  my_data.value1 = 2
  my_data.value2 = 3

  workflow_id = host.start_workflow('data', 1, my_data)

  instance = persistence.get_workflow_instance(workflow_id)
  counter = 0
  while (instance.status == WorkflowRb::WorkflowStatus::RUNNABLE) && (counter < 60) do
    counter += 1
    sleep(0.5)
    instance = persistence.get_workflow_instance(workflow_id)
  end

  it 'has an id' do
    expect(workflow_id).not_to be nil
  end

  it 'is marked as complete' do
    expect(instance.status).to eq(WorkflowRb::WorkflowStatus::COMPLETE)
  end

  it 'has a result of 5' do
    expect(instance.data.value3).to eq(5)
  end

  host.stop

end
