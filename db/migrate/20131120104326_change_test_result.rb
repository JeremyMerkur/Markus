class ChangeTestResult < ActiveRecord::Migration
  def change
    change_table :test_results do |t|
      t.remove :completion_status, :input_description, :actual_output, :expected_output
      t.integer :marks_available
      t.string :description
      t.string :feedback
    end
  end
end
