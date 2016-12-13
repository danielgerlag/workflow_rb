require "active_record"

class WorkflowRecord < ActiveRecord::Base
  def self.abstract_class?
    true
  end
end

class Person < WorkflowRecord

  connection.create_table table_name, force: true do |t|
    t.string :name
  end
end