class CreateTestHelpers < ActiveRecord::Migration
  def change
    create_table :test_helpers do |t|
      t.string :file_name
      t.references :test_script

      t.timestamps
    end
    add_index :test_helpers, :test_script_id
  end
end
