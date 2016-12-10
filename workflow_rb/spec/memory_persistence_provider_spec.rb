require 'spec_helper'
require 'yaml'
require 'workflow_rb/services/memory_persistence_provider'

describe WorkflowRb::MemoryPersistenceProvider do

  persistence = WorkflowRb::MemoryPersistenceProvider.new
  workflow = WorkflowRb::WorkflowInstance.new

  context 'when creating a new workflow'  do
    workflow.version = 1
    workflow.definition_id = 'test'
    workflow.status = WorkflowRb::WorkflowStatus::RUNNABLE
    workflow.next_execution = Time.new
    ep = WorkflowRb::ExecutionPointer.new
    ep.active = true
    ep.concurrent_fork = 1
    ep.step_id = 0
    workflow.execution_pointers << ep
    workflow_id = persistence.create_new_workflow(workflow)

    it 'returns a unique id' do
      expect(workflow_id).not_to be nil
    end

  end

  context 'when retrieving a workflow' do
    workflow_str = YAML::dump(workflow)
    retrieved_workflow = persistence.get_workflow_instance(workflow.id)

    it 'should match what was persisted' do
      expect(YAML::dump(retrieved_workflow)).to eq workflow_str
    end

  end

end
