require 'spec_helper'
require 'yaml'
require 'active_record'
require 'workflow_rb'
require 'workflow_rb/db'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
schema = WorkflowRb::Db::Schema.new
schema.up

describe WorkflowRb::Db::ActiveRecordPersistenceProvider do

  persistence = WorkflowRb::Db::ActiveRecordPersistenceProvider.new
  workflow = WorkflowRb::WorkflowInstance.new

  context 'when creating a new workflow'  do
    workflow.version = 1
    workflow.definition_id = 'test'
    workflow.status = WorkflowRb::WorkflowStatus::RUNNABLE
    workflow.next_execution = Time.now.utc.change(:usec => 0)
    workflow.create_time = Time.now.utc.change(:usec => 0)
    workflow.complete_time = nil
    workflow.data = nil
    workflow.description = nil
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
    retrieved_workflow = persistence.get_workflow_instance(workflow.id)
    it 'should match what was persisted' do
      expect(YAML.dump(retrieved_workflow)).to eq YAML.dump(workflow)
    end

  end

end
