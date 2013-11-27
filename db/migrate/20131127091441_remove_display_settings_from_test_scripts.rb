class RemoveDisplaySettingsFromTestScripts < ActiveRecord::Migration
  def change
    change_table :test_scripts do |t|
      t.remove :display_description, 
               :display_run_status,
               :display_marks_earned,
               :display_input,
               :display_expected_output,
               :display_actual_output 
    end
  end
end
