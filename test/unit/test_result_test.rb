require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class TestResultTest < ActiveSupport::TestCase
  should belong_to :submission
  should belong_to :test_script

  should validate_presence_of :test_script
  should validate_presence_of :name
  should validate_presence_of :marks_earned
  should validate_presence_of :marks_available
  should validate_presence_of :description

  should validate_numericality_of :marks_earned
  should validate_numericality_of :marks_available

  # create
  context 'A valid test result' do

    setup do
      @sub = Submission.make
      @script = TestScript.make
      @testresult = TestResult.make(:submission        => @sub,
                                    :grouping          => @sub.grouping,
                                    :repo_revision     => @sub.grouping.group.repo.get_latest_revision,
                                    :test_script       => @script,
                                    :name              => 'unit test 1',
                                    :marks_earned      => 5,
                                    :marks_available => 5,
                                    :description     => 'This is a test result',
                                    :feedback   => 'This is feedback')
    end

    should 'return true when a valid test result is created' do
      assert @testresult.valid?
      assert @testresult.save
    end

    should 'return true when a valid test result is created even if the marks_earned is zero' do
      @testresult.marks_earned = 0
      assert @testresult.valid?
      assert @testresult.save
    end

    should 'return true when a valid test result is created even if the marks_available is zero' do
      @testresult.marks_available = 0
      assert @testresult.valid?
      assert @testresult.save
    end

    should 'return true when a valid test result is created even if the feedback is empty' do
      @testresult.feedback = ''
      assert @testresult.valid?
      assert @testresult.save
    end

  end

  # update
  context 'An invalid test result' do

    setup do
      @sub = Submission.make
      @script = TestScript.make
      @testresult = TestResult.make(:submission        => @sub,
                                    :grouping          => @sub.grouping,
                                    :repo_revision     => @sub.grouping.group.repo.get_latest_revision,
                                    :test_script       => @script,
                                    :name              => 'unit test 1',
                                    :marks_available => 5,
                                    :marks_earned      => 5,
                                    :description => 'Description',
                                    :feedback => '')
    end

    should 'return false when test script is nil' do
      @testresult.test_script = nil
      @testresult.save
      assert !@testresult.valid?, 'test result expected to be invalid when test script is nil'
    end

    should 'return false when the marks_earned is negative' do
      @testresult.marks_earned = -1
      assert !@testresult.valid?, 'test result expected to be invalid when the marks_earned is negative'
    end

    should 'return false when the marks_available is negative' do
      @testresult.marks_available = -1
      assert !@testresult.valid?, 'test result expected to be invalid when the marks_available is negative'
    end

    should 'return false when the marks_earned is not an integer' do
      @testresult.marks_earned = 0.5
      assert !@testresult.valid?, 'test result expected to be invalid when the marks_earned is not an integer'
    end

    should 'return false when the marks_available is not an integer' do
      @testresult.marks_available = 0.5
      assert !@testresult.valid?, 'test result expected to be invalid when the marks_available is not an integer'
    end

    should 'return false when the description is nil' do
      @testresult.description = nil
      assert !@testresult.valid?, 'test result expected to be invalid when the description is nil'
    end

  end

  #delete
  context 'MarkUs' do
    setup do
      @sub = Submission.make
      @script = TestScript.make
      @testresult = TestResult.make(:submission        => @sub,
                                    :grouping          => @sub.grouping,
                                    :repo_revision     => @sub.grouping.group.repo.get_latest_revision,
                                    :test_script       => @script,
                                    :name              => 'unit test 1',
                                    :marks_available => 5,
                                    :marks_earned      => 5,
                                    :description => 'Description')
    end

    should 'be able to delete a test result' do
      assert @testresult.valid?
      assert @testresult.destroy
    end

  end

end
