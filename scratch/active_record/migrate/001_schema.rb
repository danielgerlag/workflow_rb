class Schema < ActiveRecord::Migration
  def up
    create_table :workflow_instances, force: true do |t|
      t.string :definition_id
      t.integer :version
      t.string :description
      t.string :execution_pointers
      t.datetime :next_execution
      t.integer :status
      t.string :data
      t.datetime :create_time
      t.datetime :complete_time
      t.integer :lock_version
    end
  end
end

