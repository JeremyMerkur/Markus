class StoreTestScriptsInFolders < ActiveRecord::Migration

  def up
    TestScript.all.each do |ts|
      file_name = ts.script_name
      test_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, ts.assignment.short_identifier)
      script_dir = File.join(test_dir, ts.id.to_s)
      script_path = File.join(test_dir, ts.script_name)
      new_script_path = File.join(script_dir, ts.script_name)
      Dir.mkdir(script_dir)
      File.rename(script_path, new_script_path)
    end
  end

  def down
    TestScript.all.each do |ts|
      file_name = ts.script_name
      test_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, ts.assignment.short_identifier)
      script_dir = File.join(test_dir, ts.id.to_s)
      script_path = File.join(test_dir, ts.script_name)
      new_script_path = File.join(script_dir, ts.script_name)
      File.rename(new_script_path, script_path)
      Dir.delete(script_dir)
    end
  end
end
