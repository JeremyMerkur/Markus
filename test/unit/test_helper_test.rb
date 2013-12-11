require 'test_helper'

class TestHelperTest < ActiveSupport::TestCase
  should belong_to :test_script
  
  should validate_presence_of :test_script
  should validate_presence_of :file_name


  # create
  context "A valid test helper" do
    should "return true when a valid file is created" do
      @helper = TestHelper.make(:file_name => 'input.txt')
      assert @helper.valid?
      assert @helper.save
    end
  end

  # update
  context "An invalid test helper" do
    
    setup do
      @validhelper = TestHelper.make(:file_name => 'valid')
      @invalidhelper = TestHelper.make(:file_name => 'invalid')
    end
    
    should "return false when the file_name is blank" do
      @invalidhelper.file_name = '   '
      assert !@invalidhelper.valid?, "helper expected to be invalid when the file name is blank"
    end

    should "return false when the file_name already exists" do
      @validhelper.test_script_id = 1
      @invalidhelper.test_script_id = 1
      @invalidhelper.file_name = 'valid'
      assert !@invalidhelper.valid?, "helper expected to be invalid when the file name already exists in the same test"
    end

  end

  # delete
  context "MarkUs" do
    should "be able to delete a test support file" do
      @helper = TestHelper.make(:file_name => 'input.txt')
      assert @helper.valid?
      assert @helper.destroy
    end
  end

# test "the truth" do
  #   assert true
  # end
end
