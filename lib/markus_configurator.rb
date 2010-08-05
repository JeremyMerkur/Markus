# ActiveRecord::Base mixin to configure MarkUs
# All descendants have the following methods available

module MarkusConfigurator
  
  ######################################
  # Repository configuration
  ######################################
  def markus_config_repository_admin?
    if defined? IS_REPOSITORY_ADMIN
      return IS_REPOSITORY_ADMIN
    else
      #If not defined, default to true
      return true
    end
  end
  
  def markus_config_repository_storage
    if defined? REPOSITORY_STORAGE
      return REPOSITORY_STORAGE
    else
      return File.join(RAILS_ROOT, "repositories")
    end
  end

  def markus_config_pdf_storage
    if defined? PDF_STORAGE
      return PDF_STORAGE
    else
      return File.join(RAILS_ROOT, "converted_pdf_dir")
    end
  end

  def markus_config_pdf_conv_memory_allowance
    if defined? PDF_CONV_MEMORY_ALLOWANCE
      return PDF_CONV_MEMORY_ALLOWANCE
    else
      return 100
    end
  end

  def markus_config_pdf_support
    if defined? PDF_SUPPORT
      return PDF_SUPPORT
    else
      return false
    end
  end

  def markus_config_repository_type
    if defined? REPOSITORY_TYPE
      return REPOSITORY_TYPE
    else
      return "svn"
    end
  end
  
  def markus_config_repository_external_base_url
    if defined? REPOSITORY_EXTERNAL_BASE_URL
      return REPOSITORY_EXTERNAL_BASE_URL
    else
      return "http://www.example.com/svn"
    end
  end
  
  def markus_config_repository_external_submits_only?
    case markus_config_repository_type
      when "svn"
        if defined? REPOSITORY_EXTERNAL_SUBMITS_ONLY
          retval = REPOSITORY_EXTERNAL_SUBMITS_ONLY
        else
          retval = false
        end
      else
        retval = false
    end
    return retval
  end
  
  def markus_config_repository_permission_file
    if defined? REPOSITORY_PERMISSION_FILE
      return REPOSITORY_PERMISSION_FILE
    else
      return File.join(markus_config_repository_storage, "svn_authz")
    end
  end

  def markus_config_course_name
    if defined? COURSE_NAME
      return COURSE_NAME
    else
      return "CSC199: Example Course Name"
    end
  end

  def markus_config_logout_redirect
    if defined? LOGOUT_REDIRECT
      return LOGOUT_REDIRECT
    else
      return "DEFAULT"
    end
  end

  def markus_config_remote_user_auth
    if defined? REMOTE_USER_AUTH
      return REMOTE_USER_AUTH
    else
      return false
    end
  end

  #Repository for the test framework
  #Students file will be compiled, executed and tested in this repository
  def markus_config_test_framework_repository
    if defined? TEST_FRAMEWORK_REPOSITORY
      return TEST_FRAMEWORK_REPOSITORY
    else
      return File.join(RAILS_ROOT, "test-framework")
    end
  end

  ######################################
  # MarkusLogger configuration
  ######################################
  def markus_config_validate_file
    if defined? VALIDATE_FILE
      return VALIDATE_FILE
    else
      return "#{RAILS_ROOT}./config/dummy_validate.sh"
    end
  end

  def markus_config_logging_rotate_by_interval
    if defined? MARKUS_LOGGING_ROTATE_BY_INTERVAL
      return MARKUS_LOGGING_ROTATE_BY_INTERVAL
    else
      return false
    end
  end
  
  def markus_config_logging_size_threshold
    if defined? MARKUS_LOGGING_SIZE_THRESHOLD
      return MARKUS_LOGGING_SIZE_THRESHOLD
    else
      return (1024 * 10**6)
    end
  end
  
  def markus_config_logging_rotate_interval
    if defined? MARKUS_LOGGING_ROTATE_INTERVAL
      return MARKUS_LOGGING_ROTATE_INTERVAL
    else
      return 'daily'
    end
  end
  
  def markus_config_logging_logfile
    if defined? MARKUS_LOGGING_LOGFILE
      return MARKUS_LOGGING_LOGFILE
    else
      return File.join(RAILS_ROOT, "log", "#{RAILS_ENV}_info.log")
    end
  end
  
  def markus_config_logging_errorlogfile
    if defined? MARKUS_LOGGING_ERRORLOGFILE
      return MARKUS_LOGGING_ERRORLOGFILE
    else
      return File.join(RAILS_ROOT, "log", "#{RAILS_ENV}_error.log")
    end
  end
  
  def markus_config_logging_num_oldfiles
    if defined? MARKUS_LOGGING_OLDFILES
      return MARKUS_LOGGING_OLDFILES
    else
      return 10
    end
  end

end
