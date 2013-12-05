# The actions necessary for managing the Testing Framework form
require 'helpers/ensure_config_helper.rb'

class AutomatedTestsController < ApplicationController
  include AutomatedTestsHelper

  before_filter      :authorize_only_for_admin,
                     :only => [:manage, :update, :download]
  before_filter      :authorize_for_user,
                     :only => [:index]

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
    # assignment = Assignment.find(params[:assignment_id])
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
      # test_params = params[:test_script].clone.delete("script_name")
      test = assignment.test_scripts.build(params[:test_script])
      if (params[:FILE_UPLOAD])
        test.script_name = params[:FILE_UPLOAD]
      end
    else
      # find old test
      test = TestScript.find(params[:test_id])
      # test_params = params[:test_script].clone.delete("script_name")
      test.attributes=(params[:test_script])
      if (params[:FILE_UPLOAD])
        test.script_name = params[:FILE_UPLOAD]
      end
    end

    respond_to do |format|
      if test.save()
        format.html { render(:partial => 'test_upload_success',
            :locals => {:test_id => test.id}) }
      else
        format.html { render(:partial => 'test_upload_error',
            :locals => {:errors => test.errors.full_messages() }) }
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
        format.html { render(:partial => 'test_upload_success',
            :locals => {:test_id => test.id}) }
      else
        format.html { render(:partial => 'test_upload_error',
            :locals => {:errors => test.errors.full_messages() }) }
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
    # assignment = Assignment.find(params[:assignment_id])
    test_script = TestScript.find(params[:test_script_id])
    if params[:is_new] == 'true'
      # make new support
      helper = test_script.test_helpers.build()
      if (params[:FILE_UPLOAD])
        helper.file_name = params[:FILE_UPLOAD]
      end
    else
      # find old test
      helper = TestHelper.find(params[:helper_id])
      # helper.attributes=(params[:test_support_file])
      if (params[:FILE_UPLOAD])
        helper.file_name = params[:FILE_UPLOAD]
      end
    end

    respond_to do |format|
      if helper.save()
        format.html { render(:partial => 'test_upload_success',
            :locals => {:test_id => helper.id}) }
      else
        format.html { render(:partial => 'test_upload_error',
            :locals => {:errors => helper.errors.full_messages() }) }
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
end
