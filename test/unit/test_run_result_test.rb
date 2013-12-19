require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class TestRunResultTest < ActiveSupport::TestCase
  should belong_to :submission
  should belong_to :grouping
  
  should validate_presence_of :repo_revision

  # create
  context "A valid test run result" do
  
    setup do
      @sub = Submission.make
      @testrunresult = TestRunResult.make(:submission    => @sub,
                                          :grouping      => @sub.grouping,
                                          :repo_revision => @sub.grouping.group.repo.get_latest_revision)
    end

    should 'return true when a valid test run result is created' do
      assert @testrunresult.valid?
      assert @testrunresult.save
    end

  end

  # update
  context "An invalid test run result" do

    setup do
      @sub = Submission.make
      @testrunresult = TestRunResult.make(:submission    => @sub,
                                          :grouping      => @sub.grouping,
                                          :repo_revision => @sub.grouping.group.repo.get_latest_revision)
    end

    should 'return false when repo revision is nil' do
      @testrunresult.repo_revision = nil
      @testrunresult.save
      assert !@testrunresult.valid?, 'test run result expected to be invalid when repo revision is nil'
    end  

  end

  # delete
  context "A valid test run result" do

    setup do
      @sub = Submission.make
      @testrunresult = TestRunResult.make(:submission    => @sub,
                                          :grouping      => @sub.grouping,
                                          :repo_revision => @sub.grouping.group.repo.get_latest_revision)
    end

    should 'be able to delete a test run result' do
      assert @testrunresult.valid?
      assert @testrunresult.destroy
    end

  end
end
