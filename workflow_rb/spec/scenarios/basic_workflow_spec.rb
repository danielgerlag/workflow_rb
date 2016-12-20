require_relative '../spec_helper'
require 'yaml'
require 'workflow_rb/services/memory_persistence_provider'

describe "Multiple outcomes" do

  class OutcomeWorkflow_Stats
    @task_A_ticker = 0
    @task_B_ticker = 0
    @task_C_ticker = 0

    class << self
      attr_accessor :task_A_ticker
      attr_accessor :task_B_ticker
      attr_accessor :task_C_ticker
    end
  end


  class TaskA < WorkflowRb::StepBody
    def run(context)
      OutcomeWorkflow_Stats.task_A_ticker += 1
      WorkflowRb::ExecutionResult.Outcome(true)
    end
  end

  class TaskB < WorkflowRb::StepBody
    def run(context)
      OutcomeWorkflow_Stats.task_B_ticker += 1
      WorkflowRb::ExecutionResult.NextStep
    end
  end

  class TaskC < WorkflowRb::StepBody
    def run(context)
      OutcomeWorkflow_Stats.task_C_ticker += 1
      WorkflowRb::ExecutionResult.NextStep
    end
  end

  class OutcomesWorkflow
    ID = 'outcomes'
    VERSION = 1
    DATA_CLASS = nil

    def build(builder)
      step1 = builder.start_with(TaskA)

      step1.when(false)
        .then(TaskB)

      step1.when(true)
          .then(TaskC)

    end
  end

  host = WorkflowRb::WorkflowHost.new
  persistence = WorkflowRb::MemoryPersistenceProvider.new
  host.use_persistence(persistence)
  logger = Logger.new(STDOUT)
  logger.level = Logger::DEBUG
  host.use_logger(logger)
  host.register_workflow(OutcomesWorkflow)
  host.start

  workflow_id = host.start_workflow('outcomes', 1)

  instance = persistence.get_workflow_instance(workflow_id)
  counter = 0
  while (instance.status == WorkflowRb::WorkflowStatus::RUNNABLE) && (counter < 60) do
    counter += 1
    sleep(0.5)
    instance = persistence.get_workflow_instance(workflow_id)
  end

  it 'is marked as complete' do
    expect(instance.status).to eq(WorkflowRb::WorkflowStatus::COMPLETE)
  end

  it 'executed task A once' do
    expect(OutcomeWorkflow_Stats.task_A_ticker).to eq(1)
  end

  it 'did not execute task B' do
    expect(OutcomeWorkflow_Stats.task_B_ticker).to eq(0)
  end

  it 'executed task C once' do
    expect(OutcomeWorkflow_Stats.task_C_ticker).to eq(1)
  end

  host.stop

end
