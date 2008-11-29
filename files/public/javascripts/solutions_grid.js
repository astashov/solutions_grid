/**
 * Solution Grid JavaScript module for AJAXed pagination, sorting and filtering.
 * Require jQuery library for correct working.
 */

jQuery(document).ready(function($) {
  
  $('.grid_pagination a').livequery('click', function() { return solutionsGrid.paginate(this); });
  $('.filter_button').livequery('click', function() { return solutionsGrid.filter(this); });
  $('.sorted').livequery('click', function() { return solutionsGrid.sort(this); })

});

(function() {
  
  window.solutionsGrid = {
    
    paginate: function(that) {
      var name = $(that).parent().attr('id').match(/(.*)_grid_pagination/)[1];
      replace_grid_by_ajax(name, that);
      return false;
    },

    sort: function(that) {
      // parents: a -> th -> tr -> tbody -> table -> div
      var name = jQuery(that).parent().parent().parent().parent().parent().attr('id').match(/(.*)_grid/)[1];
      replace_grid_by_ajax(name, that);
      return false;
    },

    filter: function(that) {
      var form = that.form;
      var grid_name_element = jQuery('.grid_name', form);
      var name = grid_name_element.val();
      create_spinner(name);
      var data = jQuery(form).serialize();
      var url = form.action + '.js?' + data;
      load_grid(name, url);
      return false;
    }
    
  };

  function replace_grid_by_ajax(name, that) {
    create_spinner(name);
    var parts_of_url = separate_url_from_params(that.href);
    var url = parts_of_url[0] + ".js" + ((parts_of_url.length > 1) ? ("?" + parts_of_url[1]) : "");
    load_grid(name, url);
  };

  function create_spinner(name) {
    jQuery('#' + name + '_spinner').append("<span class='spinner_wrapper'><img src='/images/spinner.gif' " + 
      "alt='' title='spinner' /> Loading...</span>");
  };

  function destroy_spinners() {
    jQuery('.spinner_wrapper').remove();   
  };

  function separate_url_from_params(url) {
    var separated_url = url.match(/(.*)\/?\?(.*)/);
    if(separated_url) {
      separated_url[1] = separated_url[1].replace(/(.js|.xml|.html|.htm)/i, "")
      return [separated_url[1], separated_url[2]];
    } else {
      return [url];
    }
  };
  
  function load_grid(name, url) {
    jQuery('#' + name + '_grid').load(url, function() { 
      destroy_spinners(); 
    });
  };
})();