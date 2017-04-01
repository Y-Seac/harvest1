// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require turbolinks
//= require_tree .
//= require material
//= require moment
//= require bootstrap-timepicker
$(document).ready(function() {
  $("#market_state").change(function() {
    $.ajax({
      url: "/cities",
      dataType: "json",
      type: "GET",
      data: "state=" + $("#market_state").val(),
      success: function(data, success) {
        $('#market_city').empty();
        $('#market_city').append('<option select = "selected" value=' + data["cities"][0] + '>' + data["cities"][0] + '</option>');
        for (var i = 1; i < data['cities'].length; i++) {
            $('#market_city').append('<option value=' + data["cities"][i] + '>' + data["cities"][i] + '</option>');
        }
      },
      error: function(data, failure) {
        alert(success);
      }
    });
  });
});
