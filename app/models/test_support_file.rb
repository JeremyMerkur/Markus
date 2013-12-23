##############################################################
# This is the model for the database table test_support_files,
# which each instance of this model represents a test support
# file submitted by the admin. It can be an input description
# of a test, an expected output of a test, a code library for
# testing, or any other file to support the test scripts for
# testing. MarkUs does not interpret a test support file.
#
# The attributes of test_support_files are:
#   file_name:      name of the support file. 
#   assignment_id:  id of the assignment
#   description:    a brief description of the purpose of the
#                   file.
#############################################################

class TestSupportFile < ActiveRecord::Base
  belongs_to :assignment
  
  # Run sanitize_filename before saving to the database
  before_save :sanitize_filename
  
  # Upon update, if replacing a file with a different name, delete the old file first
  before_update :delete_old_file
  
  # Run write_file after saving to the database
  after_save :write_file
  
  # Run delete_file method after removal from db
  after_destroy :delete_file
  
  validates_presence_of :assignment
  validates_associated :assignment
  
  validates_presence_of :file_name
  validates_presence_of :description, :if => "description.nil?"
  
  # validates the uniqueness of file_name for the same assignment
  validates_each :file_name do |record, attr, value|
    # Extract file_name
    name = value
    if value.respond_to?(:original_filename)
      name = value.original_filename
    end

    dup_file = TestSupportFile.find_by_assignment_id_and_file_name(record.assignment_id, name)
    if dup_file && dup_file.id != record.id
      record.errors.add attr, ' ' + name + ' ' + I18n.t("automated_tests.filename_exists")
    end
  end
  
  # Address of the test support file
  def file_path
    test_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, assignment.short_identifier)
    test_support = File.join(test_dir, self.file_name)
    return test_support
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
      # replace spaces with underscores
      self.file_name.gsub!(/[\s]/, "_")
      # replace non non-word characters with underscores
      self.file_name.gsub!(/[\W]+/, '_')
    end
  end

  # If replacing a file with a different name, delete the old file from MarkUs
  # before writing the new file
  def delete_old_file
    # Execute if the full file path exists (indicating a new File object)
    if @file_path
      # If the filenames are different, delete the old file
      if self.file_name_changed?
        path = File.join(File.dirname(self.file_path), self.file_name_was)
        File.delete(path) if File.exist?(path)
      end
    end
  end

  # Uploads the new file to the Automated Tests repository
  def write_file
    # Execute if the full file path exists (indicating a new File object)
    if @file_path
      File.open(self.file_path, "w+") { |f| f.write(@file_path.read) }
    end
  end

  def delete_file
    if File.exist?(self.file_path)
      File.delete(self.file_path)
    end
  end

end
