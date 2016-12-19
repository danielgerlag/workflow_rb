require_relative '../spec_helper'
require 'yaml'
require 'workflow_rb/services/memory_persistence_provider'

describe "Basic Workflow" do

  class BasicWorkflow_Stats
    @step1_ticker = 0
    @step2_ticker = 0

    class << self
      attr_accessor :step1_ticker
      attr_accessor :step2_ticker
    end
  end


  class Step1 < WorkflowRb::StepBody
    def run(context)
      BasicWorkflow_Stats.step1_ticker += 1
      WorkflowRb::ExecutionResult.NextStep
    end
  end

  class Step2 < WorkflowRb::StepBody
    def run(context)
      BasicWorkflow_Stats.step2_ticker += 1
      WorkflowRb::ExecutionResult.NextStep
    end
  end

  class BasicWorkflow
    ID = 'basic'
    VERSION = 1
    DATA_CLASS = nil

    def build(builder)
      builder
          .start_with(Step1)
          .then(Step2)
    end
  end

  host = WorkflowRb::WorkflowHost.new
  persistence = WorkflowRb::MemoryPersistenceProvider.new
  host.use_persistence(persistence)
  logger = Logger.new(STDOUT)
  logger.level = Logger::DEBUG
  host.use_logger(logger)
  host.register_workflow(BasicWorkflow)
  host.start

  workflow_id = host.start_workflow('basic', 1)

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

  it 'executed step 1 once' do
    expect(BasicWorkflow_Stats.step1_ticker).to eq(1)
  end

  it 'executed step 2 once' do
    expect(BasicWorkflow_Stats.step1_ticker).to eq(1)
  end

  host.stop

end
