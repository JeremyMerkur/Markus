##############################################################
# This is the model for the database table test_results,
# which each instance of this model represents the test result
# of a unit test. It contains all the information of a unit
# test.
#
# The attributes of test_results are:
#   submission_id:      id of the submission
#   test_script_id:     id of the corresponding test script
#   name:               name of the unit test
#   marks_earned:       number of points earned for this unit
#                       test. A non-negative integer.
#   marks_available:    number of points earned for this unit
#                       test. A non-negative integer.
#   description:        a string describing the unit test.
#   feedback:           optional string describing the execution 
#                       of the unit test. For example, a compilation
#                       failure dump or runtime error.
#############################################################

class TestResult < ActiveRecord::Base
  belongs_to :submission
  belongs_to :test_script
  belongs_to :grouping
  belongs_to :test_script_result

  validates_presence_of :grouping # we require an associated grouping
  validates_associated  :grouping  # grouping need to be valid

  validates_presence_of :test_script
  validates_presence_of :name
  validates_presence_of :marks_earned
  validates_presence_of :marks_available
  validates_presence_of :description
  validates_presence_of :repo_revision

  validates_numericality_of :marks_earned, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :marks_available, :only_integer => true, :greater_than_or_equal_to => 0
end
