class CreateTestRunResultTestScriptResultAssociation < ActiveRecord::Migration
  def change
    change_table :test_script_results do |t|
      t.belongs_to :test_run_result
    end
  end
end
