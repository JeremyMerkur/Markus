/* Removes a newly created test script */
function removeNewTestScript ( remove_check_box ) {
  jQuery(remove_check_box).closest('.test_script').remove();
}

/* Expands/Collapses the settings box for a test script */
function toggleSettings ( collapse_lnk ) {
  collapse_lnk = jQuery(collapse_lnk);

  // find the needed DOM elements
  box = collapse_lnk.closest('.settings_box')

  left_side = box.find('.settings_left_side');
  right_side = box.find('.settings_right_side');

  max_marks = box.find('.maxmarks');
  desc = left_side.find('.desc');
  desc_box = desc.find('textarea');

  if( collapse_lnk.data('collapsed') ) {
    // Was collapsed. Need to expand.
    desc.nextAll('*').show();
    max_marks.nextAll('*').show();

    desc_box.attr('rows', 2);
    max_marks.insertAfter(desc);

    collapse_lnk.text('[-]');
    collapse_lnk.data('collapsed', false);
  } else {
    // Was expanded. Need to collapse.
    right_side.prepend(max_marks);
    desc_box.attr('rows', 1);

    desc.nextAll('*').hide();
    max_marks.nextAll('*').hide();

    collapse_lnk.text('[+]');
    collapse_lnk.data('collapsed', true);
  }
}

/* Expands/Collapses all the settings boxes for the test scripts */
function change_all(which) {
  jQuery('.collapse').each(function (i) {
    if(jQuery(this).data('collapsed')) {
      // This box is collapsed. Can be expanded.
      if(which == 'expand') { toggleSettings(this); }
    } else {
      // This box is expanded. Can be collapsed.
      if(which == 'collapse') { toggleSettings(this); }
    }
  });
}

/* ---------------------------------------------------------------------- */

function test_helper_submit(elem) {

  // Success function for 
  var success_function = function(data, status, xhr) {
        if ($F('is_testing_framework_enabled') != null) {
          // Acquire response message and update the form
          var submit_result = jQuery(xhr.responseText);
          elem.find('.ajax_message').html(submit_result);
          if (submit_result.attr("class") == "success") {
            elem.find('.is_new').val("false");
            elem.find('.helper_id').val(jQuery(submit_result).find('#info').attr("value"));
          }
        }
      };

  // Bind the custom submit button to avoid unwanted normal form behavior
  elem.find('.submit_test_script_helper').click(function () {
    // Get the form data using the spiffy new HTML5 api
    var formData = new FormData(elem[0]);
    // Validate file upload
    if (elem.find(".upload_file")[0].files.length > 0) {
      var file = elem.find(".upload_file")[0].files[0];
      formData.append("FILE_UPLOAD", file, elem.find('.upload_file').attr('file_name'));
    } 
    jQuery.ajax({
      url: elem.attr('action'),  //Server script to process data
      type: 'POST',
      xhr: function() {  // Custom XMLHttpRequest
          var myXhr = jQuery.ajaxSettings.xhr();
          return myXhr;
      },
      success: success_function,
      // Form data
      data: formData,
      //Options to tell jQuery not to process data or worry about content-type.
      cache: false,
      contentType: false,
      processData: false
    });
  });


  // Bind the file upload input so that it updates UI elements and a name tag
  elem.find('.upload_file').change(function () {
    // jQuery(this).closest('.settings_box').find('.file_name').text(this.value);
    elem.find('.file_name').text(this.value);
    elem.find('.upload_file').attr('file_name', this.value);
    // elem.find('.script_name_field').attr('value', this.value);
  });

  // Bind the remove-form functionality to the appropriate button
  elem.find('.remove_test_script_helper').click(function () {
  if (elem.find('.is_new').attr("value") == "true") {
      elem.closest(".test_helper_file").remove();
    } else {
      var conf = confirm("Really delete test?");
      if (conf == true) {      
        var formData = new FormData(elem[0]);
        jQuery.ajax({
          url: elem.find('.remove_test_script_helper').attr('action'),  //Server script to process data
          type: 'POST',
          xhr: function() {  // Custom XMLHttpRequest
              var myXhr = jQuery.ajaxSettings.xhr();
              return myXhr;
          },
          success: function() { elem.closest(".test_helper_file").remove(); },
          // Form data
          data: formData,
          //Options to tell jQuery not to process data or worry about content-type.
          cache: false,
          contentType: false,
          processData: false
        });
      }
    }
  });

} // END test_helper_submit(elem)

/* ---------------------------------------------------------------------- */

// Function that prepares and binds event listeners to test script form elements
function test_script_submit(elem) {

  // Success function for 
  var success_function = function(data, status, xhr) {
        if ($F('is_testing_framework_enabled') != null) {
          // Acquire response message and update the form
          var submit_result = jQuery(xhr.responseText);
          elem.find('.ajax_message').html(submit_result);
          if (submit_result.attr("class") == "success") {
            elem.find('.is_new').val("false");
            elem.find('.test_id').val(jQuery(submit_result).find('#info').attr("value"));
            elem.closest(".test_script").find('.test_script_helper_field').show();
            elem.closest(".test_script").find('.add_test_script_helper_button').show();
          }
        }
      };

  // Bind the custom submit button to avoid unwanted normal form behavior
  elem.find('.alt_submit_test_script').click(function () {
    // Get the form data using the spiffy new HTML5 api
    var formData = new FormData(elem[0]);
    // Validate file upload
    if (elem.find(".upload_file")[0].files.length > 0) {
      var file = elem.find(".upload_file")[0].files[0];
      formData.append("FILE_UPLOAD", file, elem.find('.upload_file').attr('file_name'));
    } 

    jQuery.ajax({
      url: elem.attr('action'),  //Server script to process data
      type: 'POST',
      xhr: function() {  // Custom XMLHttpRequest
          var myXhr = jQuery.ajaxSettings.xhr();
          return myXhr;
      },
      success: success_function,
      // Form data
      data: formData,
      //Options to tell jQuery not to process data or worry about content-type.
      cache: false,
      contentType: false,
      processData: false
    });

  });
  

  // Bind the file upload input so that it updates UI elements and a name tag
  elem.find('.upload_file').change(function () {
    // jQuery(this).closest('.settings_box').find('.file_name').text(this.value);
    elem.find('.file_name').text(this.value);
    elem.find('.upload_file').attr('file_name', this.value);
    // elem.find('.script_name_field').attr('value', this.value);
  });

  // Bind the remove-form functionality to the appropriate button
  elem.find('.alt_remove_test_script').click(function () {
  if (elem.find('.is_new').attr("value") == "true") {
      elem.closest(".test_script").remove();
    } else {
      var conf = confirm("Really delete test?");
      if (conf == true) {      
        var formData = new FormData(elem[0]);
        jQuery.ajax({
          url: elem.find('.alt_remove_test_script').attr('action'),  //Server script to process data
          type: 'POST',
          xhr: function() {  // Custom XMLHttpRequest
              var myXhr = jQuery.ajaxSettings.xhr();
              return myXhr;
          },
          success: function() { elem.closest(".test_script").remove(); },
          // Form data
          data: formData,
          //Options to tell jQuery not to process data or worry about content-type.
          cache: false,
          contentType: false,
          processData: false
        });
      }
    }
  });

  elem.find('.add_test_script_helper_button').click(function () {
    jQuery.ajax({
      url: elem.find('.add_test_script_helper_button').attr('action'),  //Server script to process data
      type: 'POST',
      success: function(data, status, xhr) {
        if ($F('is_testing_framework_enabled') != null) {
          var new_test_helper_file = jQuery(xhr.responseText);
          test_helper_submit(new_test_helper_file.find('.new_test_helper'));
          elem.closest(".test_script").find('.test_script_helper').append(new_test_helper_file);
        }
      },
      data: {test_script_id: elem.find(".test_id").val()}
    });
  });

} // END test_script_submit(elem)

/* ---------------------------------------------------------------------- */

// Function that prepares and binds event listeners to test script form elements
function test_support_submit(elem) {

  // Success function for 
  var success_function = function(data, status, xhr) {
        if ($F('is_testing_framework_enabled') != null) {
          // Acquire response message and update the form
          var submit_result = jQuery(xhr.responseText);
          elem.find('.ajax_message').html(submit_result);
          if (submit_result.attr("class") == "success") {
            elem.find('.is_new').val("false");
            elem.find('.support_id').val(jQuery(submit_result).find('#info').attr("value"));
          }
        }
      };

  // Bind the custom submit button to avoid unwanted normal form behavior
  elem.find('.submit_test_script_support').click(function () {
    // Get the form data using the spiffy new HTML5 api
    var formData = new FormData(elem[0]);
    // Validate file upload
    if (elem.find(".upload_file")[0].files.length > 0) {
      var file = elem.find(".upload_file")[0].files[0];
      formData.append("FILE_UPLOAD", file, elem.find('.upload_file').attr('file_name'));
    } 

    jQuery.ajax({
      url: elem.attr('action'),  //Server script to process data
      type: 'POST',
      xhr: function() {  // Custom XMLHttpRequest
          var myXhr = jQuery.ajaxSettings.xhr();
          return myXhr;
      },
      success: success_function,
      // Form data
      data: formData,
      //Options to tell jQuery not to process data or worry about content-type.
      cache: false,
      contentType: false,
      processData: false
    });

  });
  

  // Bind the file upload input so that it updates UI elements and a name tag
  elem.find('.upload_file').change(function () {
    // jQuery(this).closest('.settings_box').find('.file_name').text(this.value);
    elem.find('.file_name').text(this.value);
    elem.find('.upload_file').attr('file_name', this.value);
    // elem.find('.script_name_field').attr('value', this.value);
  });

  // Bind the remove-form functionality to the appropriate button
  elem.find('.remove_test_script_support').click(function () {
  if (elem.find('.is_new').attr("value") == "true") {
      elem.closest(".test_support_file").remove();
    } else {
      var conf = confirm("Really delete test?");
      if (conf == true) {      
        var formData = new FormData(elem[0]);
        jQuery.ajax({
          url: elem.find('.remove_test_script_support').attr('action'),  //Server script to process data
          type: 'POST',
          xhr: function() {  // Custom XMLHttpRequest
              var myXhr = jQuery.ajaxSettings.xhr();
              return myXhr;
          },
          success: function() { elem.closest(".test_support_file").remove(); },
          // Form data
          data: formData,
          //Options to tell jQuery not to process data or worry about content-type.
          cache: false,
          contentType: false,
          processData: false
        });
      }
    }
  });

} // END test_support_submit(elem)

/* ---------------------------------------------------------------------- */

jQuery(document).ready(function() {
  /* Update the script name in the legend when the admin uploads a file */
  jQuery('.upload_file').change(function () {
    jQuery(this).closest('.settings_box').find('.file_name').text(this.value);
  })

  /* Existing files are collapsed by default */
  jQuery('.collapse').each(function (i) {
    jQuery(this).data('collapsed', true);
  });

  /* Make the list of test script files sortable. */
  jQuery( "#test_scripts" ).sortable({
    cancel: ".settings_box",
    stop: function( event, ui) {
      var moved_seqnum_elem = ui.item.find('.seqnum');
      var moved_seqnum = parseFloat(moved_seqnum_elem.val());

      var next_siblings = ui.item.nextAll('div.test_script')
      var prev_siblings = ui.item.prevAll('div.test_script')

      if(prev_siblings.length > 0 && next_siblings.length > 0) {
        // test script file was moved in between two other test scripts
        var next_seqnum = parseFloat( next_siblings.first().find('.seqnum').val() );
        var prev_seqnum = parseFloat( prev_siblings.first().find('.seqnum').val() );
        if(Math.abs(next_seqnum - prev_seqnum) < 1e-6) {
          console.log('difference is too small!')
          next_siblings.find('.seqnum').each(function () {
            this.value = parseFloat(this.value) + 16;
          });
          next_seqnum += 16;
        }
        if( prev_seqnum >= moved_seqnum || moved_seqnum >= next_seqnum ) {
          moved_seqnum_elem.val((prev_seqnum + next_seqnum) / 2);
        }
      } else if(prev_siblings.length > 0) {
        // test script file was moved to the end of the list
        var prev_seqnum = parseFloat( prev_siblings.first().find('.seqnum').val() );
        if( moved_seqnum <= prev_seqnum ) {
          moved_seqnum_elem.val(prev_seqnum + 16);
        }
      } else if(next_siblings.length > 0) {
        // test script file was moved to the front of the list
        var next_seqnum = parseFloat( next_siblings.first().find('.seqnum').val() );
        if( moved_seqnum >= next_seqnum) {
          moved_seqnum_elem.val(next_seqnum - 16);
        }
      } 
    }
  });

  // Binds the custom submit botton onclick event and other form-specific jQuery
  var i = 0;
  var elems = jQuery('.edit_test_script');
  for (i = 0; i < elems.length; ++i) {
    test_script_submit(jQuery(elems[i]));
  }
  elems = jQuery('.edit_test_support_file');
  for (i = 0; i < elems.length; ++i) {
    test_support_submit(jQuery(elems[i]));
  }
  elems = jQuery('.edit_test_helper');
  for (i = 0; i < elems.length; ++i) {
    test_helper_submit(jQuery(elems[i]));
  }

  // Adds an event listener that catches the ajax response to the add_new_test
  // link/button, cleans it up, and appends it to the test_scripts div
  jQuery( "#add_new_test_script_form" ).on('ajax:success', function(e, data, status, xhr) {

    if ($F('is_testing_framework_enabled') != null) {

      var last_seqnum = jQuery('.seqnum').last().val();
      var new_seqnum = 0;
      if(last_seqnum) {
        new_seqnum = 16 + parseFloat(last_seqnum);
      }

      var new_test_script = jQuery(xhr.responseText);
      jQuery('#test_scripts').append(new_test_script);

      new_test_script.find('.seqnum').val(new_seqnum);
      new_test_script.data('collapsed', false);

      // Don't let new test scripts have helper files added
      new_test_script.find('.test_script_helper_field').hide();
      new_test_script.find('.add_test_script_helper_button').hide();

      // Bind a proper submit function to the form
      test_script_submit(new_test_script.find('.new_test_script'));

    }

  });

  jQuery( "#add_new_test_support_form" ).on("ajax:success", function(e, data, status, xhr) {

    if ($F('is_testing_framework_enabled') != null) {
      var new_test_support_file_id = new Date().getTime();
      var new_test_support_file = jQuery(xhr.responseText);
      jQuery('#test_support_files').append(new_test_support_file);
      test_support_submit(new_test_support_file.find('.new_test_support_file'));
    }

  });

});
