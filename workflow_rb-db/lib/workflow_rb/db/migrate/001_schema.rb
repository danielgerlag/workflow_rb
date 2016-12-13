require "active_record"

module WorkflowRb
  module Db
    class Schema < ActiveRecord::Migration
      def up
        create_table :workflow_instances, force: true do |t|
          t.string :definition_id, :limit => 100
          t.integer :version
          t.string :description
          t.string :execution_pointers
          t.datetime :next_execution
          t.integer :status
          t.string :data
          t.datetime :create_time
          t.datetime :complete_time
          t.integer :lock_version

          t.index :next_execution
          t.index :status
        end


        create_table :event_subscriptions, force: true do |t|
          t.integer :workflow_id
          t.integer :step_id
          t.string :event_name, :limit => 100
          t.string :event_key, :limit => 100

          t.index :event_name
          t.index :event_key
        end

        create_table :event_publications, force: true do |t|
          t.integer :workflow_id
          t.integer :step_id
          t.string :event_name, :limit => 100
          t.string :event_key, :limit => 100
          t.string :event_data

          t.index :event_name
          t.index :event_key
        end

      end
    end

  end
end

