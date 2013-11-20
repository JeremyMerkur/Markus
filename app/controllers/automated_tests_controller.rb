# The actions necessary for managing the Testing Framework form
require 'helpers/ensure_config_helper.rb'

class AutomatedTestsController < ApplicationController
  include AutomatedTestsHelper
  include PaginationHelper

  before_filter      :authorize_only_for_admin,
                     :only => [:manage, :update, :download]
  before_filter      :authorize_for_user,
                     :only => [:index]


  # This is not being used right now. It was the calling interface to
  S_TABLE_PARAMS = {
    :model => Grouping,
    :per_pages => [15, 30, 50, 100, 150, 500, 1000],
    :filters => {
      'none' => {
        :display => I18n.t("browse_submissions.show_all"),
        :proc => lambda { |params, to_include|
          return params[:assignment].groupings.all(:include => to_include)}},
          'unmarked' => {
            :display => I18n.t("browse_submissions.show_unmarked"),
            :proc => lambda { |params, to_include| return params[:assignment].groupings.all(:include => [to_include]).select{|g| !g.has_submission? || (g.has_submission? && g.current_submission_used.result.marking_state == Result::MARKING_STATES[:unmarked]) } }},
            'partial' => {
              :display => I18n.t("browse_submissions.show_partial"),
              :proc => lambda { |params, to_include| return params[:assignment].groupings.all(:include => [to_include]).select{|g| g.has_submission? && g.current_submission_used.result.marking_state == Result::MARKING_STATES[:partial] } }},
              'complete' => {
                :display => I18n.t("browse_submissions.show_complete"),
                :proc => lambda { |params, to_include| return params[:assignment].groupings.all(:include => [to_include]).select{|g| g.has_submission? && g.current_submission_used.result.marking_state == Result::MARKING_STATES[:complete] } }},
                'released' => {
                  :display => I18n.t("browse_submissions.show_released"),
                  :proc => lambda { |params, to_include| return params[:assignment].groupings.all(:include => [to_include]).select{|g| g.has_submission? && g.current_submission_used.result.released_to_students} }},
                  'assigned' => {
                    :display => I18n.t("browse_submissions.show_assigned_to_me"),
                    :proc => lambda { |params, to_include| return params[:assignment].ta_memberships.find_all_by_user_id(params[:user_id], :include => [:grouping => to_include]).collect{|m| m.grouping} }}
                    },
                    :sorts => {
                      'group_name' => lambda { |a,b| a.group.group_name.downcase <=> b.group.group_name.downcase},
                      'repo_name' => lambda { |a,b| a.group.repo_name.downcase <=> b.group.repo_name.downcase },
                      'revision_timestamp' => lambda { |a,b|
                        return -1 if !a.has_submission?
                        return 1 if !b.has_submission?
                        return a.current_submission_used.revision_timestamp <=> b.current_submission_used.revision_timestamp
                        },
                        'marking_state' => lambda { |a,b|
                          return -1 if !a.has_submission?
                          return 1 if !b.has_submission?
                          return a.current_submission_used.result.marking_state <=> b.current_submission_used.result.marking_state
                          },
                          'total_mark' => lambda { |a,b|
                            return -1 if !a.has_submission?
                            return 1 if !b.has_submission?
                            return a.current_submission_used.result.total_mark <=> b.current_submission_used.result.total_mark
                            },
                            'grace_credits_used' => lambda { |a,b|
                              return a.grace_period_deduction_single <=> b.grace_period_deduction_single
                              },
                              'section' => lambda { |a,b|
                                return -1 if !a.section
                                return 1 if !b.section
                                return a.section <=> b.section
                              }
                            }
                          }
                     
  # This is not being used right now. It was the calling interface to 
  # request a test run, however, now you can just call
  # AutomatedTestsHelper.request_a_test_run to send a test request.
  def index
    submission_id = params[:submission_id]

    # TODO: call_on should be passed to index as a parameter.
    list_call_on = %w(submission request collection)
    call_on = list_call_on[0]

    AutomatedTestsHelper.request_a_test_run(submission_id, call_on, @current_user)

    # TODO: render a new partial page
    #render :test_replace,
    #       :locals => {:test_result_files => @test_result_files,
    #                   :result => @result}
  end

  # Update is called when files are added to the assigment
  def update
    @assignment = Assignment.find(params[:assignment_id])

    create_test_repo(@assignment)

    # Perform transaction, if errors, none of new config saved
    @assignment.transaction do

      begin
        # Process testing framework form for validation
        @assignment = process_test_form(@assignment, params)
      rescue Exception, RuntimeError => e
        @assignment.errors.add(:base, I18n.t("assignment.error",
                                             :message => e.message))
        render :manage
        return
      end

      # Save assignment and associated test files
      if @assignment.save
        flash[:success] = I18n.t("assignment.update_success")
        redirect_to :action => 'manage',
                    :assignment_id => params[:assignment_id]
      else
        render :manage
      end

    end
  end

  # Manage is called when the Automated Test UI is loaded
  def manage
    @assignment = Assignment.find(params[:assignment_id])
  end

  # Manage is called when the Automated Test UI is loaded
  def tokens
    if current_user.ta?
      params[:filter] = 'assigned'
    else
      if params[:filter] == nil or params[:filter].blank?
        params[:filter] = 'none'
      end
    end
    
    @assignment = Assignment.find(params[:assignment_id])
    
    @c_per_page = current_user.id.to_s + "_" + @assignment.id.to_s + "_per_page"
    if !params[:per_page].blank?
       cookies[@c_per_page] = params[:per_page] 
    end 

    @c_sort_by = current_user.id.to_s + "_" + @assignment.id.to_s + "_sort_by"
    if !params[:sort_by].blank?
       cookies[@c_sort_by] = params[:sort_by]
    else
       params[:sort_by] = 'group_name' 
    end
 
    @groupings, @groupings_total = handle_paginate_event(
      S_TABLE_PARAMS,                                     # the data structure to handle filtering and sorting
        { :assignment => @assignment,                     # the assignment to filter by
          :user_id => current_user.id},                   # the submissions accessable by the current user
      params)                                             # additional parameters that affect things like sorting

    #Eager load all data only for those groupings that will be displayed
    sorted_groupings = @groupings
    @groupings = Grouping.find(:all, :conditions => {:id => sorted_groupings},
      :include => [:assignment, :group, :grace_period_deductions,
        {:current_submission_used => :result},
        {:accepted_student_memberships => :user}])

    #re-sort @groupings by the previous order, because eager loading query
    #messed up the grouping order
    @groupings = sorted_groupings.map do |sorted_grouping|
      @groupings.detect do |unsorted_grouping|
        unsorted_grouping == sorted_grouping
      end
    end
    
    if cookies[@c_per_page].blank?
       cookies[@c_per_page] = params[:per_page]
    end
    
    if cookies[@c_sort_by].blank?
       cookies[@c_sort_by] = params[:sort_by]
    end
 
    @current_page = params[:page].to_i()
    @per_page = cookies[@c_per_page] 
    @filters = get_filters(S_TABLE_PARAMS)
    @per_pages = S_TABLE_PARAMS[:per_pages]
    @desc = params[:desc]
    @filter = params[:filter]
    @sort_by = cookies[@c_sort_by]
  end
  
  def update_tokens
 
    return unless request.post?
    assignment = Assignment.find(params[:assignment_id])
    errors = []
    groupings = []
    if params[:ap_select_full] == 'true'
      # We should have been passed a filter
      if params[:filter].blank?
        raise I18n.t("student.submission.expect_filter")
      end
      # Get all Groupings for this filter
      groupings = S_TABLE_PARAMS[:filters][params[:filter]][:proc].call({:assignment => assignment, :user_id => current_user.id}, {})
    else
      # User selected particular Grouping IDs
      if params[:groupings].nil?
        errors.push(I18n.t('results.must_select_a_group'))
      else
        groupings = assignment.groupings.find(params[:groupings])
      end
    end
    
    groupings_test = params[:groupings]
    groupings_test.each do |g1|
      puts "This is the groupings #{g1} done \n\n\n"
    end
    
    log_message = ""
    # ATE_SIMPLE_UI: this is temporary 
    # After this action successfully done, it flashes the message "# of results has successfully changed"
    # which here, running test is not changing anything. Please see the user table UI for how to properly
    # do bulk action to table rows.
    if !params[:run_test].nil?
      
      groupings_test = params[:groupings]
      groupings_test.each do |g1|
        puts "This is the groupings #{g1} done \n\n\n"
        changed = run_tests(g1)
        log_message = "Run test for assignment '#{assignment.short_identifier}', ID: '" +
                      "#{assignment.id}' (For #{changed} groups)."
      end
    # ATE_SIMPLE_UI end
    end


    if !groupings.empty?
      assignment.set_results_average
    end

    #if changed > 0
     # flash[:success] = I18n.t('results.successfully_changed', {:changed => changed})
     # m_logger = MarkusLogger.instance
     # m_logger.log(log_message)
    #end
    flash[:errors] = errors

    redirect_to :action => 'tokens',
                :id => params[:id],
                :per_page => params[:per_page],
                :filter   => params[:filter],
                :sort_by  => params[:sort_by] 
  end

  def student_interface
    @assignment = Assignment.find(params[:id])
    @student = current_user
    @grouping = @student.accepted_grouping_for(@assignment.id)

    if !@grouping.nil?
      # Look up submission information
      repo = @grouping.group.repo
      @revision  = repo.get_latest_revision
      @revision_number = @revision.revision_number

      @test_script_results = TestScriptResult.find_by_grouping_id(@grouping.id)

      @token = Token.find_by_grouping_id(@grouping.id)
      if @token
        @token.reassign_tokens_if_new_day()
      end
    end
  end

  def request_test_run
    @assignment = Assignment.find(params[:id])
    @student = current_user
    @grouping = @student.accepted_grouping_for(@assignment.id)

    if !@grouping.nil?
      @token = Token.find_by_grouping_id(@grouping.id)

      # If the group has tokens to use, run a test
      if (@token && @token.tokens > 0) || @assignment.unlimited_tokens
        result = run_tests(@grouping.id)
        if result.nil?
          flash[:notice] = I18n.t("automated_tests.tests_running")
        else
          flash[:failure] = result
        end

      end
    end

    # Redirect back to the student interface
    redirect_to :action => 'student_interface',
                :assignment_id => params[:assignment_id]
  end

  def run_tests(grouping_id)
    changed = 0
    begin
      AutomatedTestsHelper.request_a_test_run(grouping_id, 'request', @current_user)
      return nil
    rescue Exception => e
      return e.message
    end
  end

  # Download is called when an admin wants to download a test script
  # or test support file
  # Check three things:
  #  1. filename is in DB
  #  2. file is in the directory it's supposed to be
  #  3. file exists and is readable
  def download
    filedb = nil
    if params[:type] == 'script'
      filedb = TestScript.find_by_assignment_id_and_script_name(params[:assignment_id], params[:filename])
    elsif params[:type] == 'support'
      filedb = TestSupportFile.find_by_assignment_id_and_file_name(params[:assignment_id], params[:filename])
    end

    if filedb
      if params[:type] == 'script'
        filename = filedb.script_name
      elsif params[:type] == 'support'
        filename = filedb.file_name
      end
      assn_short_id = Assignment.find(params[:assignment_id]).short_identifier

      # the given file should be in this directory
      should_be_in = File.join(MarkusConfigurator.markus_config_automated_tests_repository, assn_short_id)
      should_be_in = File.expand_path(should_be_in)
      filename = File.expand_path(File.join(should_be_in, filename))

      if should_be_in == File.dirname(filename) and File.readable?(filename)
        # Everything looks OK. Send the file over to the client.
        file_contents = IO.read(filename)
        send_file filename,
                  :type => ( SubmissionFile.is_binary?(file_contents) ? 'application/octet-stream':'text/plain' ),
                  :x_sendfile => true

     # print flash error messages
      else
        flash[:error] = I18n.t('automated_tests.download_wrong_place_or_unreadable');
        redirect_to :action => 'manage'
      end
    else
      flash[:error] = I18n.t('automated_tests.download_not_in_db');
      redirect_to :action => 'manage'
    end
  end

  # Download is called when an admin wants to download a test script
  # or test support file
  # Check three things:
  #  1. filename is in DB
  #  2. file is in the directory it's supposed to be
  #  3. file exists and is readable
  def download
    filedb = nil
    if params[:type] == 'script'
      filedb = TestScript.find_by_assignment_id_and_script_name(params[:assignment_id], params[:filename])
    elsif params[:type] == 'support'
      filedb = TestSupportFile.find_by_assignment_id_and_file_name(params[:assignment_id], params[:filename])
    end

    if filedb
      if params[:type] == 'script'
        filename = filedb.script_name
      elsif params[:type] == 'support'
        filename = filedb.file_name
      end
      assn_short_id = Assignment.find(params[:assignment_id]).short_identifier

      # the given file should be in this directory
      should_be_in = File.join(MarkusConfigurator.markus_config_automated_tests_repository, assn_short_id)
      should_be_in = File.expand_path(should_be_in)
      filename = File.expand_path(File.join(should_be_in, filename))

      if should_be_in == File.dirname(filename) and File.readable?(filename)
        # Everything looks OK. Send the file over to the client.
        file_contents = IO.read(filename)
        send_file filename,
                  :type => ( SubmissionFile.is_binary?(file_contents) ? 'application/octet-stream':'text/plain' ),
                  :x_sendfile => true

     # print flash error messages
      else
        flash[:error] = I18n.t('automated_tests.download_wrong_place_or_unreadable');
        redirect_to :action => 'manage'
      end
    else
      flash[:error] = I18n.t('automated_tests.download_not_in_db');
      redirect_to :action => 'manage'
    end
  end

  # Called by the "Add Test Script File" button, renders a form block
  # for the user to enter information into
  def add_new_test_form
    new_test_script = TestScript.new
    respond_to do |format|
      format.html {render(:partial => 'test_script_upload',
                     :locals => {:test_script => new_test_script,
                      :is_new => 'true'})}
    end
  end

  # Called by the "Add Test Support File" button
  def add_new_test_support_form
    assignment = Assignment.find(params[:assignment_id])
    new_test_support = TestSupportFile.new
    respond_to do |format|
      format.html {render(:partial => 'test_support_file_upload',
                     :locals => {:assignment => assignment, 
                       :test_support_file => new_test_support,
                       :is_new => "true"})}
    end
  end

  def add_new_test_helper_form
      assignment = Assignment.find(params[:assignment_id])
      test_script = TestScript.find(params[:test_script_id])
      new_test_helper = TestHelper.new
      respond_to do |format|
        format.html {render(:partial => 'test_helper_file_upload',
                      :locals => {
                        :test_script => test_script,
                        :test_helper_file => new_test_helper,
                        :is_new => "true"})}
      end
    end

  # Controller action to handle the updating and creation of new
  # test script elements in the database
  def update_test
    assignment = Assignment.find(params[:assignment_id])
    if params[:is_new] == 'true'
      # make new test
      test = assignment.test_scripts.build(params[:test_script])
      if (params[:FILE_UPLOAD])
        test.script_name = params[:FILE_UPLOAD]
      end
    else
      # find old test
      test = TestScript.find(params[:test_id])
      test.attributes=(params[:test_script])
      if (params[:FILE_UPLOAD])
        test.script_name = params[:FILE_UPLOAD]
      end
    end

    respond_to do |format|
      if test.save()
        format.html { render(:partial => 'test_update_response',
            :locals => {
              :success => true,
              :message => I18n.t('automated_tests.test_script_upload_succeeded'),
              :info => test.id.to_s,
              :errors => Array.new
              })}
      else
        format.html { render(:partial => 'test_update_response',
            :locals => {
              :success => false,
              :message => I18n.t('automated_tests.test_script_upload_failed'),
              :info => "",
              :errors => test.errors.full_messages()
              })}
      end
    end
  end

  # Controller action to delete a test script
  def remove_test
    TestScript.destroy(params[:test_id])
    respond_to do |format|
      format.html { render(:text => 'Success') }
    end
  end

  # Controller action to handle the updating and creation of new
  # test support files in the database
  def update_support
    assignment = Assignment.find(params[:assignment_id])
    if params[:is_new] == 'true'
      # make new support
      test = assignment.test_support_files.build(params[:test_support_file])
      if (params[:FILE_UPLOAD])
        test.file_name = params[:FILE_UPLOAD]
      end
    else
      # find old test
      test = TestSupportFile.find(params[:support_id])
      test.attributes=(params[:test_support_file])
      if (params[:FILE_UPLOAD])
        test.file_name = params[:FILE_UPLOAD]
      end
    end



    respond_to do |format|
      if test.save()
        format.html { render(:partial => 'test_update_response',
            :locals => {
              :success => true,
              :message => I18n.t('automated_tests.test_support_upload_succeeded'),
              :info => test.id.to_s,
              :errors => Array.new
              })}
      else
        format.html { render(:partial => 'test_update_response',
            :locals => {
              :success => false,
              :message => I18n.t('automated_tests.test_support_upload_failed'),
              :info => "",
              :errors => test.errors.full_messages()
              })}
      end
    end
  end

  # Controller action to delete a test support file
  def remove_support
    TestSupportFile.destroy(params[:support_id])
    respond_to do |format|
      format.html { render(:text => 'Success') }
    end
  end

  # Controller action to handle the updating and creation of new
  # test helper files in the database
  def update_helper
    test_script = TestScript.find(params[:test_script_id])
    if params[:is_new] == 'true'
      # make new helper
      helper = test_script.test_helpers.build()
      if (params[:FILE_UPLOAD])
        helper.file_name = params[:FILE_UPLOAD]
      end
    else
      # find old helper
      helper = TestHelper.find(params[:helper_id])
      if (params[:FILE_UPLOAD])
        helper.file_name = params[:FILE_UPLOAD]
      end
    end

    respond_to do |format|
      if helper.save()
        format.html { render(:partial => 'test_update_response',
            :locals => {
              :success => true,
              :message => I18n.t('automated_tests.test_helper_upload_succeeded'),
              :info => helper.id.to_s,
              :errors => Array.new
              })}
      else
        format.html { render(:partial => 'test_update_response',
            :locals => {
              :success => false,
              :message => I18n.t('automated_tests.test_helper_upload_failed'),
              :info => "",
              :errors => helper.errors.full_messages()
              })}
      end
    end
  end

  # Controller action to delete a test helper file
  def remove_helper
    TestHelper.destroy(params[:helper_id])
    respond_to do |format|
      format.html { render(:text => 'Success') }
    end
  end


  def download_script
    script = TestScript.find(params[:test_script_id])
    if File.exists?(script.file_path)
      file_contents = IO.read(script.file_path)
        send_file(
        script.file_path,
        :type => ( SubmissionFile.is_binary?(file_contents) ? 'application/octet-stream':'text/plain' ),
        :x_sendfile => true
        )
    end
  end

  def download_helper
    helper = TestHelper.find(params[:test_helper_id])
    if File.exists?(helper.file_path)
      file_contents = IO.read(helper.file_path)
        send_file(
        helper.file_path,
        :type => ( SubmissionFile.is_binary?(file_contents) ? 'application/octet-stream':'text/plain' ),
        :x_sendfile => true
        )
    end
  end

  def download_support
    support = TestSupportFile.find(params[:test_support_id])
    if File.exists?(support.file_path)
      file_contents = IO.read(support.file_path)
        send_file(
        support.file_path,
        :type => ( SubmissionFile.is_binary?(file_contents) ? 'application/octet-stream':'text/plain' ),
        :x_sendfile => true
        )
    end
  end

end
