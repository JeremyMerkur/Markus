##############################################################
# This is the model for the database table test_script_results,
# which each instance of this model represents the test result
# of a test script. It contains information of a test
# run, but not all the information is shown to the student.
# (Configurable for each test script) Also, the admin decides
# whether or not and when to show the result to the student.
#
# The attributes of test_support_files are:
#   submission_id:      id of the submission assocaited with test run
#   grouping_id:        id of grouping that ran the test run
#   repo_revision:      revision number of repo used in the test run
##############################################################

class TestRunResult < ActiveRecord::Base
  belongs_to :submission
  belongs_to :grouping

  validates_presence_of :grouping   # we require an associated grouping
  validates_associated  :grouping   # grouping need to be valid

  validates_presence_of :repo_revision

end
