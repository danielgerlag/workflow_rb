require_relative '../spec_helper'
require 'yaml'
require 'workflow_rb/services/memory_persistence_provider'

describe "External Events Workflow" do


  class MyData
    attr_accessor :my_value
  end


  class EventWorkflow
    ID = 'events'
    VERSION = 1
    DATA_CLASS = MyData

    def build(builder)
      builder
          .start_step do |context|
            WorkflowRb::ExecutionResult.NextStep
          end
          .wait_for('my-event', '0')
            .output(:my_value) { |step| step.event_data }
    end
  end

  host = WorkflowRb::WorkflowHost.new
  persistence = WorkflowRb::MemoryPersistenceProvider.new
  host.use_persistence(persistence)
  logger = Logger.new(STDOUT)
  logger.level = Logger::DEBUG
  host.use_logger(logger)
  host.register_workflow(EventWorkflow)
  host.start

  workflow_id = host.start_workflow('events', 1)

  counter = 0

  while (persistence.get_subscriptions('my-event', '0').count == 0) && (counter < 60) do
    counter += 1
    sleep(0.5)
  end

  host.publish_event('my-event', '0', 'Pass')

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

  it 'received the correct external data' do
    expect(instance.data.my_value).to eq('Pass')
  end

  host.stop

end
