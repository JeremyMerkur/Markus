##############################################################
# This is the model for the database table test_helper,
# which consists of additional files used in automated testing
# associated with individual tests.
#
# The attributes of test_support_files are:
#   file_name:      name of the helpert file
#   test_script_id:  id of the test script
#############################################################

class TestHelper < ActiveRecord::Base
  belongs_to :test_script

  # Run sanitize_filename before saving to the database
  before_save :sanitize_filename
  
  # Upon update, if replacing a file with a different name, delete the old file first
  before_update :delete_old_file
  
  # Run write_file after saving to the database
  after_save :write_file
  
  # Run delete_file method after removal from db
  after_destroy :delete_file
  
  validates_presence_of :test_script
  validates_associated :test_script
  
  validates_presence_of :file_name

  # validates the uniqueness of file_name for the same assignment
  validates_each :file_name do |record, attr, value|
    # Extract file_name
    name = value
    if value.respond_to?(:original_filename)
      name = value.original_filename
    end

    dup_file = TestHelper.find_by_test_script_id_and_file_name(record.test_script_id, name)
    if  record.test_script
      script_name = record.test_script.script_name
    else
      script_name = ""
    end
    if dup_file && dup_file.id != record.id || name == script_name
      record.errors.add attr, ' ' + name + ' ' + I18n.t("automated_tests.filename_exists")
    end

  end

  # Address of the test helper file
  def file_path
    test_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, test_script.assignment.short_identifier)
    test_helper = File.join(test_dir, self.test_script_id.to_s, self.file_name)
    return test_helper
  end

  # All callback methods are protected methods
  protected
  
  # Save the full test file path and sanitize the filename for the database
  def sanitize_filename
    # Execute only when full file path exists (indicating a new File object)
    if self.file_name.respond_to?(:original_filename)
      @file_path = self.file_name
      self.file_name = self.file_name.original_filename

      # Sanitize filename:
      self.file_name.strip!
      self.file_name.gsub(/^(..)+/, ".")
      # replace spaces with
      self.file_name.gsub(/[^\s]/, "")
      # replace all non alphanumeric, underscore or periods with underscore
      self.file_name.gsub(/^[\W]+$/, '_')
    end
  end

  # If replacing a file with a different name, delete the old file from MarkUs
  # before writing the new file
  def delete_old_file
    # Execute if the full file path exists (indicating a new File object)
    if @file_path
      # If the filenames are different, delete the old file
      if self.file_name_changed?
        # Delete old file
        test_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, test_script.assignment.short_identifier)
        path = File.join(test_dir, self.test_script_id.to_s, self.file_name_was)
        File.delete(path) if File.exist?(path)
      end
    end
  end

  # Uploads the new file to the Automated Tests repository
  def write_file
    # Execute if the full file path exists (indicating a new File object)
    if @file_path
      name = self.file_name
      test_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, test_script.assignment.short_identifier)

      # Create the file path
      path = File.join(test_dir, self.test_script_id.to_s, name)

      # Read and write the file (overwrite if it exists)
      File.open(path, "w+") { |f| f.write(@file_path.read) }
    end
  end

  def delete_file
    if File.exist?(self.file_path)
      File.delete(self.file_path)
    end
  end

end
