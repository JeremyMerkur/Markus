class CreateTestRunResults < ActiveRecord::Migration
  def change
    create_table :test_run_results do |t|
      t.references :submission
      t.references :grouping
      t.integer :repo_revision

      t.timestamps
    end
    add_index :test_run_results, :submission_id
    add_index :test_run_results, :grouping_id
  end
end
