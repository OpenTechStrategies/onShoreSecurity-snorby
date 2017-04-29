// Snorby - A Web interface for Snort.
// 
// Copyright (c) 2010 Dustin Willis Webber (dustin.webber at gmail.com)
// 
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

var selected_events = [];
var flash_message   = [];
var loading_class   = "loading"
var csrf = $('meta[name="csrf-token"]').attr('content');
var secs;
var clock_locked = false;
var ajax_queue = new Array();

function blockWebUI() {
  $.blockUI({ 
    css: { 
      border: 'none', 
      padding: '15px', 
      backgroundColor: '#000', 
      '-webkit-border-radius': '10px', 
      '-moz-border-radius': '10px', 
      opacity: .5, 
      color: '#fff' 
    } 
  });
}

function get_chart(component) {
  container = $(component).parents(".graphcontainer:first")
  if (container.hasClass('dashboard-graph'))
    return window[container.attr('id')]

  return window[container.find(".dashboard-graph:first").attr('id')]
}


function selectTab(index){
  var tabs= $('#box-menu > li > a.show_metric')

  if (tabs.length>index) {
    tabs[index].click();
  }
}

function queue_ajax(ajax) {
  ajax_queue.push(ajax);
}

function clean_as_possible() {
  if (global_ticker!=null) {
    clearInterval(global_ticker);
    global_ticker = null
  }

  //falta la parte de dns

  for (var i=ajax_queue.length-1; i>=0; i--) {
    ajax_queue[i].abort()
  }
}

function start_counter_widgets(initial_secs){
  secs = initial_secs;
  if ($(".portlet").length>=0) {
    global_ticker = setInterval(function() {
      if (!clock_locked) {
        if ($(".portlet.loading").length==0) {
          $("#counter").css('opacity', 1);
          secs_str = (secs<10?"0":"") +secs
          $("#counter span").html(secs_str);
          if (secs == 0) {
            secs = initial_secs;
            reload_all_widgets()
          }
          secs --;
        } else {
          $("#counter").css('opacity', 0.6);
        }
      } else {
        $("#counter span").html('--');
      }
    }, 1000);
  }

  $("#counter").live('click', function(e) {
    reload_all_widgets()
    secs = initial_secs;
  });
}

function reload_all_widgets() {
  var portlets = $(".portlet")
  for (i=0; i<portlets.length; i++) {
    expand = $(portlets[i]).find('.expand')
    if (!expand.hasClass("loading")) {
      reload_widget($(portlets[i]), null);
    }
  }
}

function reload_widget(portlet, e) {
  var id      = portlet.attr('data');
  var ret     = false;

  if (portlet.hasClass('loading')) {
    if (e!=undefined && e!=null)
      e.preventDefault();
    ret = false;
  } else {
    portlet.addClass("loading");
    var last_title = portlet.find('.portlet-header .wtitle').html()
    var table_loaded = portlet.find('.portlet-content .expand').hasClass('showed')
    portlet.find('.portlet-header .wtitle').html(last_title +" <img style='width:10px;' src='/images/icons/pager.gif'>")
    portlet.find('.portlet-header .reload-widget').css('opacity', 0.4);
    ret = false;


    $.ajax({
      url: '/widgets/' +id +'/reload',
      data: {
        table_loaded: table_loaded
      },
      success: function(data) {
        portlet.find('.portlet-header .wtitle').html(last_title)
        portlet.find('.portlet-header .reload-widget').animate({"opacity": 1});
      },
      fail: function(data) {
        flash_message.push({
          type: 'error',
          message: "The widget has not been reloaded!!"
        });
        flash();
        $.scrollTo('#header', 500);
      }
    });
  }

  return ret;
}

function start_counter_dashboard(initial_secs){
  secs = initial_secs;
  global_ticker = setInterval(function() {
    if (!clock_locked) {
      if (!$("#dashboard").hasClass('loading')) {
        $("#counter").css('opacity', 1);
        secs_str = (secs<10?"0":"") +secs
        $("#counter span").html(secs_str);
        if (secs == 0) {
          secs = initial_secs;
          reload_dashboard();
        }
        secs --;
      } else {
        $("#counter").css('opacity', 0.6);
      }
    } else {
      $("#counter span").html('--');
    }
  }, 1000);

  $("#counter").live('click', function(e) {
    reload_dashboard();
    secs = initial_secs;
  });
}

function reload_dashboard() {
  $("#dashboard").addClass('loading');
  $('div#dashboard').animate({"opacity": 0.7});
  $("#box-holder").addClass('loading');
  $('div#box-holder').animate({"opacity": 0.7});
  $.getScript('/dashboard?load_all=true');  
}

function start_counter_snmp(initial_secs){
  secs = initial_secs;
  global_ticker = setInterval(function() {
    if (!clock_locked) {
      if (!$("#dashboard").hasClass('loading')) {
        $("#counter").css('opacity', 1);
        secs_str = (secs<10?"0":"") +secs
        $("#counter span").html(secs_str);
        if (secs == 0) {
          secs = initial_secs;
          reload_dashboard_snmp();
        }
        secs --;
      } else {
        $("#counter").css('opacity', 0.6);
      }
    } else {
      $("#counter span").html('--');
    }
  }, 1000);

  $("#counter").live('click', function(e) {
    reload_dashboard_snmp();
    secs = initial_secs;
  });
}

function reload_dashboard_snmp() {
  $("#dashboard").addClass('loading');
  $('div#dashboard').animate({"opacity": 0.7});
  $.getScript('/snmps?load_all=true');  
}

function start_counter_events(initial_secs){
  secs = initial_secs;
  global_ticker = setInterval(function() {
    if (!clock_locked) {
      if (!$("#events").hasClass('loading')) {
        $("#counter").css('opacity', 1);
        secs_str = (secs<10?"0":"") +secs
        $("#counter span").html(secs_str);
        if (secs == 0) {
          secs = initial_secs;
          reload_events();
        }
        secs --;
      } else {
        $("#counter").css('opacity', 0.6);
      }
    } else {
      $("#counter span").html('--');
    }
  }, 1000);
 
  $("#counter").live('click', function(e) {
    reload_events();
    secs = initial_secs;
  });
}

function reload_events() {
  $("div#events").addClass('loading');
  $('div#events').animate({"opacity": 0.7});
  $.getScript('/events');  
}

function reload_dashboard_sensor(type){
  var sensor_id = $("#dashboard").attr("data");
  var column = $("#dashboard .secondary");

  $("#title-menu li").hide()

  if (!column.hasClass(loading_class)){
    column.addClass(loading_class);
    var header_comp = $("#dashboard-sensor-" +type +" .dashboard-header .loading");
    header_comp.html('<img src="/images/icons/pager.gif"/>');
    $.ajax({
      url: "/sensors/" +sensor_id +"/update_dashboard_" +type,
      error: function(data){
        header_comp.html("");
        flash_message.push({
          type: 'error'
        });
        flash();
        $.scrollTo('#header', 500);
        column.removeClass(loading_class);
      },
      success: function(data){
        $("#dashboard-sensor-info-content").hide();
        $("#dashboard-sensor-load-content").hide();
        $("#dashboard-sensor-other-content").fadeIn('slow');
        column.removeClass(loading_class);
        header_comp.html("");
      }
    });
  }
};

function apply_event_filter(id, user_id, clean_filters) {
  $.getJSON('/saved/event_filters/' + id, function(data) {
    var search = data.filter;

    var search_id = null;

    if (user_id == data.user_id) {
      search_id = "" + data.id + "";
    };

    var widgets= ($("#widgets").length>0)
    var snmps= ($(".snmp_panel:first").length>0)

    var params = {
      search_id: search_id,
      match_all: data.filter.match_all,
      search: search.items,
      title: data.title,
      authenticity_token: csrf,
      widgets: widgets,
      snmps: snmps,
      clean_filters: clean_filters
    };
    post_to_url('/results', params);
  });
}

function apply_rule_filter(id, user_id, clean_filters, sensor_id) {
  $.getJSON('/sensors/'+ sensor_id + '/saved_rule_filters/' + id, function(data) {
    var search = data.filter;

    var search_id = null;

    if (user_id == data.user_id) {
      search_id = "" + data.id + "";
    };

    var widgets= ($("#widgets").length>0)
    var snmps= ($(".snmp_panel:first").length>0)

    var params = {
      search_id: search_id,
      match_all: data.filter.match_all,
      search: search.items,
      authenticity_token: csrf,
      clean_filters: clean_filters
    };
    post_to_url('/sensors/'+ sensor_id +'/rules/results', params);
  });
}

function post_to_url(path, params, method) {
  method = method || "post";

  var form = document.createElement("form");
  form.setAttribute("method", method);
  form.setAttribute("action", path);

  for(var key in params) {
    if (params.hasOwnProperty(key)) {
      var hiddenField = document.createElement("input");
      hiddenField.setAttribute("type", "hidden");
      hiddenField.setAttribute("name", key);

      var value = params[key];
      if (typeof value === "object") {
        hiddenField.setAttribute("value", JSON.stringify(value));
      } else if (typeof value === "string") {
        hiddenField.setAttribute("value", value);
      } else if (typeof value === "boolean") {
        hiddenField.setAttribute("value", value);
      };

      form.appendChild(hiddenField);
    };
  };

  document.body.appendChild(form);
  form.submit();
};

function HCloader(element) {
  var $holder = $('div#' + element);
  $holder.fadeTo('slow', 0.2);
  
  var $el = $('<div class="cover-loader" />');
  
  $el.css({
    top: $holder.offset().top,
    left: $holder.offset().left,
    height: $holder.height(),
    width: $holder.width(),
    'line-height': $holder.height() + 'px'
  }).html('Loading...');
  
  $el.appendTo('body');

};

function clippyCopiedCallback(a) {
  var b = $('span#main_' + a);
  b.length != 0 && (b.attr("title", "copied!").trigger('tipsy.reload'), setTimeout(function() {
    b.attr("title", "copy to clipboard")
  },
  500))
};

function Queue() {
  if ( !(this instanceof arguments.callee) ) {
    return new arguments.callee(arguments);
  }
  var self = this;
	
  self.up = function () {
    var current_count = parseInt($('span.queue-count').html());
    $('span.queue-count').html(current_count + 1);
  };
	
  self.down = function() {
    var current_count = parseInt($('span.queue-count').html());
    $('span.queue-count').html(current_count - 1);
    text = $('span.queue-count-with-text').html();
    $('span.queue-count-with-text').html((current_count - 1) <= 1 ? text.replace(/s/, " ") : text);
  };

}

function flash (data) {
  $('div#flash_message').remove();

  $.each(flash_message, function(index, data) {
    var message = Snorby.templates.flash(data);
    $('body').prepend(message);
    $('div#flash_message').fadeIn('slow').delay(3000).fadeOut("slow");
    flash_message = [];
  });
	
  return false;
}

function clear_selected_events () {
  selected_events = [];
  $('input#selected_events').val('');
  return false;
}

function set_classification (class_id) {
  var selected_events = $('input#selected_events').attr('value');
  var current_page = $('div#events').attr('data-action');
  var current_page_number = $('div#events').attr('data-page');

  if (selected_events.length > 0) {
    $('div.content').fadeTo(500, 0.4);
    Snorby.helpers.remove_click_events(true);

    $.post('/events/classify', {
      events: selected_events,
      classification: class_id,
      authenticity_token: csrf
    }, function() {

      if (current_page == "index") {
        clear_selected_events();
        $.getScript('/events?page=' + current_page_number);
      }else if (current_page == "queue") {
        clear_selected_events();
        $.getScript('/events/queue?page=' + current_page_number);
      } else if (current_page == "history") {
        clear_selected_events();
        $.getScript('/events/history?page=' + current_page_number);
      } else if (current_page == "results") {
        clear_selected_events();
        $.getScript($('input#current_url').val());
      } else {
      // clear_selected_events();
      // $.getScript('/events');
      };

      flash_message.push({
        type: 'success',
        message: "Event(s) Classified Successfully"
      });

    });

  } else {

    if ($('ul.table div.content li.event.currently-over.highlight').is(':visible')) {

      $('ul.table div.content li.event.currently-over.highlight .row div.select input#event-selector').click().trigger('change');
      set_classification(class_id);

    } else {

      flash_message.push({
        type: 'error',
        message: "Please select Events to perform this action"
      });
      flash();
      $.scrollTo('#header', 500);

    };

  };
};

function fetch_last_event(callback) {
  $.ajax({
    url: '/events/last',
    dataType: 'json',
    type: 'GET',
    global: false,
    cache: false,
    success: function(data) {
      if (data && (data.time)) {
        $('div#wrapper').attr({last_event: data.time});
        callback(data.time);
      };
    }
  });
};

function monitor_events(prepend_events) {
 
  $("#growl").notify({
      speed: 500,
      expires: 5000
  });

  fetch_last_event(function(time) {
    setInterval (function () {
      new_event_check(prepend_events);
    }, 100000);
  });

};

var SearchRule;
SearchRule = function() {

  function SearchRule(selectData, sensor_sid, rule_type, callback) {
    var self = this;
    self.html = Handlebars.templates['search-rule']({});
    self.columns = selectData.columns;
    self.operators = selectData.operators;
    self.selectData = selectData;
    self.action_id = selectData.action_id;
    self.category4_id = selectData.category4_id;
    self.category2_id = selectData.category2_id;
    self.favorite = selectData.favorite;
    self.flowbit_id = selectData.flowbit_id;
    self.flowbit_state_id = selectData.flowbit_state_id;
    self.inherited = selectData.inherited;
    self.is_modified = selectData.is_modified;
    self.is_new = selectData.is_new;
    self.category1_id = selectData.category1_id;
    self.policy_id = selectData.policy_id;
    self.protocol = selectData.protocol;
    self.source_id = selectData.source_id;
    self.is_deprecated = selectData.is_deprecated;
    self.severity = selectData.severity;

    self.sensor_sid = sensor_sid;
    self.rule_type = rule_type;

    self.init();
    return self;
  };

  SearchRule.prototype = {

    init: function(callback) {
      var self = this;
      var width = "368px";

      self.action_id_html = Handlebars.templates['select']({
        name: "action_id-select",
        width: width,
        multiple: false,
        data: self.action_id
      });

      self.category4_id_html = Handlebars.templates['select']({
        name: "category4_id-select",
        width: width,
        multiple: false,
        data: self.category4_id
      });

      self.category2_id_html = Handlebars.templates['select']({
        name: "category2_id-select",
        width: width,
        multiple: false,
        data: self.category2_id
      });

      self.favorite_html = Handlebars.templates['select']({
        name: "favorite-select",
        width: width,
        multiple: false,
        data: self.favorite
      });

      self.flowbit_id_html = Handlebars.templates['select']({
        name: "flowbit_id-select",
        width: width,
        multiple: false,
        data: self.flowbit_id
      });

      self.flowbit_state_id_html = Handlebars.templates['select']({
        name: "flowbit_state_id-select",
        width: width,
        multiple: false,
        data: self.flowbit_state_id
      });

      self.inherited_html = Handlebars.templates['select']({
        name: "inherited-select",
        width: width,
        multiple: false,
        data: self.inherited
      });

      self.is_modified_html = Handlebars.templates['select']({
        name: "is_modified-select",
        width: width,
        multiple: false,
        data: self.is_modified
      });

      self.is_new_html = Handlebars.templates['select']({
        name: "is_new-select",
        width: width,
        multiple: false,
        data: self.is_new
      });

      self.category1_id_html = Handlebars.templates['select']({
        name: "category1_id-select",
        width: width,
        multiple: false,
        data: self.category1_id
      });

      self.policy_id_html = Handlebars.templates['select']({
        name: "policy_id-select",
        width: width,
        multiple: false,
        data: self.policy_id
      });

      self.protocol_html = Handlebars.templates['select']({
        name: "protocol-select",
        width: width,
        multiple: false,
        data: self.protocol
      });

      self.source_id_html = Handlebars.templates['select']({
        name: "source_id-select",
        width: width,
        multiple: false,
        data: self.source_id
      });

      self.is_deprecated_html = Handlebars.templates['select']({
        name: "is_deprecated-select",
        width: width,
        multiple: false,
        data: self.is_deprecated
      });

      self.severity_html = Handlebars.templates['select']({
        name: "severity-select",
        width: width,
        multiple: false,
        data: self.severity
      });

      self.columns_html = Handlebars.templates['select']({
        name: "column-select",
        placeholder: "Choose a query term...",
        data: {
          value: self.columns
        }
      });

      self.operators_html = function($html, data) {
        var select = Handlebars.templates['select']({
          name: "operators-select",
          data: {
            value: data
          }
        });

        $html.find('div.operator-select').html(select);
      };

      self.datetime_picker = function(that) {
        that.datetimepicker({
          timeFormat: 'hh:mm:ss',
          dateFormat: 'yy-mm-dd',
          numberOfMonths: 1,
          showSecond: true,
          separator: ' '
        });
      };

    },

    searchUI: function(data, callback) {
      var self = this;
      $('#content #title').after(Handlebars.templates['search'](data));

      $('.search-content-add').live('click', function(e) {
        e.preventDefault();
        self.add(this);
      });

      $('.search-content-remove').live('click', function(e) {
        e.preventDefault();
        self.remove(this);
      });

      $('div.search-content-enable input').live('click', function() {
        if ($(this).is(':checked')) {
          $(this)
          .parents('.search-content-box')
          .find('.value *, .operator-select *, .column-select *')
          .attr('disabled', false).css('opacity', 1);
        } else {
          $(this)
          .parents('.search-content-box')
          .find('.value *, .operator-select *, .column-select *')
          .attr('disabled', true).css('opacity', 0.8);
        };

        $('.add_chosen').trigger("liszt:updated");
      });

      $('button.submit-search').live('click', function(e) {
        e.preventDefault();
        self.submit();
      });

      $('#content #title').on('click', 'a.reset-search-form', function(e) {
        e.preventDefault();

        $('.rules').empty();

        self.add();
        self.add();
        self.add();
      });

      if (callback && (typeof callback === "function")) {
        callback();
      };
    },

    add: function(that, newOptions, callback) {
      var self = this;
      var options = {};

      if (options && (typeof options === "object")) {
        options = newOptions;
      };

      var $html = $(self.html);
      $html.find('div.column-select').html(self.columns_html);

      if (that && (typeof that === "object")) {
        $(that).parents('.search-content-box').after($html);
      } else {
        $('.rules').append($html);
      };

      $html.find('.add_chosen')
      .chosen({allow_single_deselect: true})
      .change(function(event, data) {
        var value = $(this).val();
        var that = $(this).parents('.search-content-box');

        if (value === "action_id") {
          that.find('.value').html(self.action_id_html);
          self.operators_html($html, self.operators.text_input);
        } else if (value === "category4_id") {
          that.find('.value').html(self.category4_id_html);
          self.operators_html($html, self.operators.text_input);
        } else if (value === "category2_id") {
          that.find('.value').html(self.category2_id_html);
          self.operators_html($html, self.operators.text_input);
        } else if (value === "favorite") {
          that.find('.value').html(self.favorite_html);
          self.operators_html($html, self.operators.boolean_input);
        } else if (value === "flowbit_id") {
          that.find('.value').html(self.flowbit_id_html);
          self.operators_html($html, self.operators.text_input);
        } else if (value === "flowbit_state_id") {
          that.find('.value').html(self.flowbit_state_id_html);
          self.operators_html($html, self.operators.text_input);
        } else if (value === "inherited") {
          that.find('.value').html(self.inherited_html);
          self.operators_html($html, self.operators.boolean_input);
        } else if (value === "is_modified") {
          that.find('.value').html(self.is_modified_html);
          self.operators_html($html, self.operators.boolean_input);
        } else if (value === "is_new") {
          that.find('.value').html(self.is_new_html);
          self.operators_html($html, self.operators.boolean_input);
        } else if (value === "category1_id") {
          that.find('.value').html(self.category1_id_html);
          self.operators_html($html, self.operators.text_input);
        } else if (value === "policy_id") {
          that.find('.value').html(self.policy_id_html);
          self.operators_html($html, self.operators.text_input);
        } else if (value === "protocol") {
          that.find('.value').html(self.protocol_html);
          self.operators_html($html, self.operators.text_input);
        } else if (value === "source_id") {
          that.find('.value').html(self.source_id_html);
          self.operators_html($html, self.operators.text_input);
        } else if (value === "is_deprecated") {
          that.find('.value').html(self.is_deprecated_html);
          self.operators_html($html, self.operators.boolean_input);
        } else if (value === "severity") {
          that.find('.value').html(self.severity_html);
          self.operators_html($html, self.operators.text_input);
        } else if (value === "") {
          that.find('.value').html('<input class="search-content-value" placeholder="Enter search value" name="" type="text">');
          self.operators_html($html, self.operators.text_input);
        } else {
          that.find('.value').html('<input class="search-content-value" placeholder="Enter search value" name="" type="text">');
          self.operators_html($html, self.operators.text_input);
        };

        that.find('.add_chosen').chosen({
          allow_single_deselect: true
        });

        if (callback && (typeof callback === "function")) {
          callback(that);
        };

        that.trigger('snorby:search:change');
      });

      $('.search-content-box:first')
      .find('.search-content-remove')
      .css('opacity', 1)
      .unbind('hover')
      .unbind('mouseover');

      return $html;
    },

    remove: function(that) {
      var self = this;
      if ($('.search-content-box').length > 2) {
        $(that).parents('.search-content-box').remove();
      } else if ($('.search-content-box').length == 2) {
        $(that).parents('.search-content-box').remove();

        $('.search-content-box:first')
        .find('.search-content-remove')
        .css('opacity', 0.4)
        .attr('title', 'You must have at least one search rule.')
        .tipsy({
          gravity: 's'
        });
      };
    },

    pack: function() {
      var self = this;
      var matchAll = false;

      if ($('#search select.global-match-setting').val() === "all") {
        matchAll = true;
      };

      var json = {
        match_all: matchAll,
        items: {}
      };

      $('.search-content-box').each(function(index, item) {
        var enabled = $(item).find('.search-content-enable input').is(':checked');
        var column = $(item).find('.column-select select').val();
        var operator = $(item).find('.operator-select select').val();
        var value = $(item).find('.value input, .value select').val();

        if (column == "start_time" || column == "end_time"){
          value = new Date(value).getTime() / 1000;
        }

        if ((column !== "") || (value !== "")) {
          json.items[index] = {
            column: column,
            operator: operator,
            value: value,
            enabled: enabled
          };
        };
      });

      return json;
    },

    submit: function(callback, otherOptions) {
      var self = this;
      var search = self.pack();

      if (typeof otherOptions !== "object") {
        otherOptions = {};
      };

      if (self.sensor_sid != 0){
        url = '/sensors/'+ self.sensor_sid +'/rules/results';
      } else {
        url = '/rules'
      }

      var update_url = function() {
        if (history && history.pushState) {
          history.pushState(null, document.title, url);
        };
      };

      if (callback && (typeof callback === "function")) {
        callback(search, self);
      };

      if (search && !$.isEmptyObject(search.items)) {
        if (otherOptions.search_id) {
          post_to_url(url, {
            search: search.items,
            rule_type: self.rule_type,
            new_search: 'true',
            authenticity_token: csrf
          });
        } else {
          post_to_url(url, {
            search: search.items,
            rule_type: self.rule_type,
            new_search: 'true',
            authenticity_token: csrf
          });
        };
      } else {
        flash_message.push({type: 'error', message: "You cannot submit all empty search rules."});flash();
      };
    },

    build: function(search) {
      var self = this;

      if (typeof search === "string") {
        var data = JSON.parse(search);
      } else if (typeof search === "object") {
        var data = search;
      } else {
        var data = {};
      };

      if (data.items) {
       var rules = data.items;
      } else if (data.search) {
        var rules = data.search;
      } else {
        var rules = {};
      };

      if (data.match_all && data.match_all === "false") {
       $('select.global-match-setting option[value="any"]').attr('selected', 'selected');
      } else {
        $('select.global-match-setting option[value="all"]').attr('selected', 'selected');
      };

      for (id in rules) {
        var item = rules[id];

        var rule = self.add(false, {});

        var column = rule.find('div.column-select select');

        rule.bind('snorby:search:change', function() {
          var operator = $(this).find('div.operator-select select');
          var value = $(this).find('div.value select, div.value input');

          operator.find("option[value='"+item.operator+"']").attr('selected', 'selected');
          operator.trigger("liszt:updated");
          value.attr('value', item.value);

          rule.unbind('snorby:search:change');
        });

        rule.attr('data-rule-id', id);

        column.find("option[value='"+item.column+"']").attr('selected','selected');
        column.trigger("liszt:updated").trigger('change');

        if (item.enabled === "false") {
          rule.find('div.search-content-enable input').attr('checked', false);
          rule.find('.value *, .operator-select *, .column-select *')
          .attr('disabled', true).css('opacity', 0.8);
        };
      };

      $('.rules .add_chosen').trigger("liszt:updated");
    },

  };

  return SearchRule;
}();

var SearchEvent;
SearchEvent = function() {

  function SearchEvent(selectData, callback) {
    var self = this;
    self.html = Handlebars.templates['search-rule']({});
    self.columns = selectData.columns;
    self.operators = selectData.operators;

    self.selectData = selectData;

    self.classifications = selectData.classifications;
    self.sensors = selectData.sensors;
    self.users = selectData.users;
    self.signatures = selectData.signatures;
    self.severities = selectData.severities;
    self.protocol = selectData.protocol;

    self.init();
    return self;
  };

  SearchEvent.prototype = {

    init: function(callback) {
      var self = this;
      var width = "368px";

      self.sensors_html = Handlebars.templates['select']({
        name: "sensors-select",
        width: width,
        multiple: false,
        data: self.sensors
      });

      self.classifications_html = Handlebars.templates['select']({
        name: "classifications-select",
        width: width,
        data: self.classifications
      });

      self.severity_html = Handlebars.templates['select']({
        name: "severities-select",
        width: width,
        data: self.severities
      });

      self.signatures_html = Handlebars.templates['select']({
        name: "signatures-select",
        width: width,
        data: self.signatures
      });

      self.users_html = Handlebars.templates['select']({
        name: "users-select",
        width: width,
        data: self.users
      });

      self.protocol_html = Handlebars.templates['select']({
        name: "protocol-select",
        width: width,
        data: self.protocol
      });

      self.columns_html = Handlebars.templates['select']({
        name: "column-select",
        placeholder: "Choose a query term...",
        data: {
          value: self.columns
        }
      });

      self.operators_html = function($html, data) {
        var select = Handlebars.templates['select']({
          name: "operators-select",
          data: {
            value: data
          }
        });

        $html.find('div.operator-select').html(select);
      };

      self.datetime_picker = function(that) {
        that.datetimepicker({
          timeFormat: 'hh:mm:ss',
          dateFormat: 'yy-mm-dd',
          numberOfMonths: 1,
          showSecond: true,
          separator: ' '
        });
      };

    },

    searchUI: function(data, callback) {
      var self = this;
      $('#content #title').after(Handlebars.templates['search'](data));

      $('.search-content-add').live('click', function(e) {
        e.preventDefault();
        self.add(this);
      });

      $('.search-content-remove').live('click', function(e) {
        e.preventDefault();
        self.remove(this);
      });

      $('div.search-content-enable input').live('click', function() {
        if ($(this).is(':checked')) {
          $(this)
          .parents('.search-content-box')
          .find('.value *, .operator-select *, .column-select *')
          .attr('disabled', false).css('opacity', 1);
        } else {
          $(this)
          .parents('.search-content-box')
          .find('.value *, .operator-select *, .column-select *')
          .attr('disabled', true).css('opacity', 0.8);
        };

        $('.add_chosen').trigger("liszt:updated");
      });

      $('button.submit-search').live('click', function(e) {
        e.preventDefault();
        self.submit();
      });

      $('#content #title').on('click', 'a.reset-search-form', function(e) {
        e.preventDefault();

        $('.rules').empty();

        self.add();
        self.add();
        self.add();
      });

      if (callback && (typeof callback === "function")) {
        callback();
      };
    },

    add: function(that, newOptions, callback) {
      var self = this;
      var options = {};

      if (options && (typeof options === "object")) {
        options = newOptions;
      };

      var $html = $(self.html);
      $html.find('div.column-select').html(self.columns_html);

      if (that && (typeof that === "object")) {
        $(that).parents('.search-content-box').after($html);
      } else {
        $('.rules').append($html);
      };

      $html.find('.add_chosen')
      .chosen({allow_single_deselect: true})
      .change(function(event, data) {
        var value = $(this).val();
        var that = $(this).parents('.search-content-box');

        if (value === "signature") {
          that.find('.value').html(self.signatures_html);
          self.operators_html($html, self.operators.text_input);
        } else if (value === "signature_name") {
          that.find('.value').html('<input class="search-content-value" placeholder="Enter search value" name="" type="text">');
          self.operators_html($html, self.operators.more_text_input);
        } else if (value === "sensor") {
          that.find('.value').html(self.sensors_html);
          self.operators_html($html, self.operators.text_input);
        } else if (value === "classification") {
          that.find('.value').html(self.classifications_html);
          self.operators_html($html, self.operators.select_with_null);
        } else if (value === "user") {
          that.find('.value').html(self.users_html);
          self.operators_html($html, self.operators.text_input);
        } else if (value === "severity") {
          that.find('.value').html(self.severity_html);
          self.operators_html($html, self.operators.text_input);
        } else if (value === "protocol") {
          that.find('.value').html(self.protocol_html);
          self.operators_html($html, self.operators.text_input);
        } else if (value === "start_time") {
          that.find('.value').html('<input id="time-'+ new Date().getTime() +'" class="search-content-value" placeholder="Enter search value" name="" type="text">');
          self.datetime_picker(that.find('.value input:first'))
          self.operators_html($html, self.operators.datetime);
        } else if (value === "end_time") {
          that.find('.value').html('<input id="time-'+ new Date().getTime() +'" class="search-content-value" placeholder="Enter search value" name="" type="text">');
          self.datetime_picker(that.find('.value input:first'))
          self.operators_html($html, self.operators.datetime);
        } else if (value === "payload") {
          that.find('.value').html('<input class="search-content-value" placeholder="Enter search value" name="" type="text">');
          self.operators_html($html, self.operators.more_text_input);
        } else if (value === "") {
          that.find('.value').html('<input class="search-content-value" placeholder="Enter search value" name="" type="text">');
          self.operators_html($html, self.operators.text_input);
        } else {
          that.find('.value').html('<input class="search-content-value" placeholder="Enter search value" name="" type="text">');
          self.operators_html($html, self.operators.text_input);
        };

        that.find('.add_chosen').chosen({
          allow_single_deselect: true
        });

        if (callback && (typeof callback === "function")) {
          callback(that);
        };

        that.trigger('snorby:search:change');
      });

      $('.search-content-box:first')
      .find('.search-content-remove')
      .css('opacity', 1)
      .unbind('hover')
      .unbind('mouseover');

      return $html;
    },

    remove: function(that) {
      var self = this;
      if ($('.search-content-box').length > 2) {
        $(that).parents('.search-content-box').remove();
      } else if ($('.search-content-box').length == 2) {
        $(that).parents('.search-content-box').remove();

        $('.search-content-box:first')
        .find('.search-content-remove')
        .css('opacity', 0.4)
        .attr('title', 'You must have at least one search rule.')
        .tipsy({
          gravity: 's'
        });
      };
    },

    pack: function() {
      var self = this;
      var matchAll = false;

      if ($('#search select.global-match-setting').val() === "all") {
        matchAll = true;
      };

      var json = {
        match_all: matchAll,
        items: {}
      };

      $('.search-content-box').each(function(index, item) {
        var enabled = $(item).find('.search-content-enable input').is(':checked');
        var column = $(item).find('.column-select select').val();
        var operator = $(item).find('.operator-select select').val();
        var value = $(item).find('.value input, .value select').val();

        if (column == "start_time" || column == "end_time"){
          value = new Date(value).getTime() / 1000;
        }

        if ((column !== "") || (value !== "")) {
          json.items[index] = {
            column: column,
            operator: operator,
            value: value,
            enabled: enabled
          };
        };
      });

      return json;
    },

    submit: function(callback, otherOptions) {
      var self = this;
      var search = self.pack();

      if (typeof otherOptions !== "object") {
        otherOptions = {};
      };

      var update_url = function() {
        if (history && history.pushState) {
          history.pushState(null, document.title, '/results');
        };
      };

      if (callback && (typeof callback === "function")) {
        callback(search, self);
      };

      if (search && !$.isEmptyObject(search.items)) {
        if (otherOptions.search_id) {
          post_to_url('/results', {
            match_all: search.match_all,
            search: search.items,
            title: otherOptions.title,
            search_id: ""+otherOptions.search_id+"",
            authenticity_token: csrf
          });
        } else {
          post_to_url('/results', {
            match_all: search.match_all,
            search: search.items,
            authenticity_token: csrf
          });
        };
      } else {
        flash_message.push({type: 'error', message: "You cannot submit all empty search rules."});flash();
      };
    },

    build: function(search) {
      var self = this;

      if (typeof search === "string") {
        var data = JSON.parse(search);
      } else if (typeof search === "object") {
        var data = search;
      } else {
        var data = {};
      };

      if (data.items) {
       var rules = data.items;
      } else if (data.search) {
        var rules = data.search;
      } else {
        var rules = {};
      };

      if (data.match_all && data.match_all === "false") {
       $('select.global-match-setting option[value="any"]').attr('selected', 'selected');
      } else {
        $('select.global-match-setting option[value="all"]').attr('selected', 'selected');
      };

      for (id in rules) {
        var item = rules[id];

        var rule = self.add(false, {});

        var column = rule.find('div.column-select select');

        rule.bind('snorby:search:change', function() {
          var operator = $(this).find('div.operator-select select');
          var value = $(this).find('div.value select, div.value input');

          operator.find("option[value='"+item.operator+"']").attr('selected', 'selected');
          operator.trigger("liszt:updated");
          value.attr('value', item.value);

          rule.unbind('snorby:search:change');
        });

        rule.attr('data-rule-id', id);

        column.find("option[value='"+item.column+"']").attr('selected','selected');
        column.trigger("liszt:updated").trigger('change');

        if (item.enabled === "false") {
          rule.find('div.search-content-enable input').attr('checked', false);
          rule.find('.value *, .operator-select *, .column-select *')
          .attr('disabled', true).css('opacity', 0.8);
        };
      };

      $('.rules .add_chosen').trigger("liszt:updated");
    },

  };

  return SearchEvent;
}();


function new_event_check(prepend_events) {
  $.ajax({
    url: '/events/last',
    dataType: 'json',
    type: 'GET',
    global: false,
    cache: false,
    success: function(data) {
      var old_id = $('div#wrapper').attr('last_event');
      
      var page = parseInt($('.pager li.active a').html());

      if (old_id != data.time) {
        $.ajax({
          url: '/events/since',
          data: { timestamp: old_id },
          dataType: 'json',
          type: 'GET',
          global: false,
          cache: false,
          success: function(newEvents) {
            if (newEvents.events && newEvents.events.length != 0) {
              if (prepend_events) {
                if (page <= '1') { 
                  if ($('div.new_events').length == 0) {                    
                    $('#events').prepend('<div class="note new_events"><strong class="new_event_count">'+newEvents.events.length+'</strong> New Events Are Available Click here To View Them.</div>');                    
                  } else {                    
                    var new_count = parseInt($('#events div.new_events strong.new_event_count').html()) + newEvents.events.length;
                    $('#events div.new_events').html('<strong class="new_event_count">'+new_count+'</strong> New Events Are Available Click here To View Them.');                    
                  };
                  //$('#events ul.table div.content').prepend(Snorby.templates.event_table(newEvents));
                };
              };
              Snorby.notification({title: 'New Events', text: newEvents.events.length + ' Events Added.'});
            };
          }
        });

        $('div#wrapper').attr('last_event', data.time);
      };
    }
  });
};

function update_note_count (event_id, data) {
	
  var event_row = $('li#'+event_id+' div.row div.timestamp');
  var notes_count = event_row.find('span.notes-count');
	
  var template = '<span class="add_tipsy round notes-count" title="{{notes_count_in_words}}"><img alt="Notes" height="16" src="/images/icons/notes.png" width="16"></span>'
  var event_html = Snorby.templates.render(template, data);
  	
  if (data.notes_count == 0) {
		
    notes_count.remove();
		
  } else {
		
    if (notes_count.length > 0) {
      notes_count.replaceWith(event_html).trigger('tipsy.reload');
    } else {
      event_row.prepend(event_html).trigger('tipsy.reload');
    };
		
  };
	
};

function update_main_note_count(object_id, data) {

  var object_tr     = $('tr#'+ object_id);
  var notes_count   = object_tr.find('span.notes-count');

  if (data.notes_count == 0) {
    notes_count.remove();
  } else {
    var template        = '<span class="add_tipsy round notes-count" title="{{notes_count_in_words}}"><img alt="Notes" height="16" src="/images/icons/notes.png" width="16"></span>'
    var object_html = Snorby.templates.render(template, data);

    if (notes_count.length > 0) {
      notes_count.replaceWith(object_html).trigger('tipsy.reload');
    } else {
      object_tr.find('td.notes').prepend(object_html).trigger('tipsy.reload');
    };
  };

};

var Snorby = {

  file: {
      upload_asset_csv: function(){
       var self = $('#bulk-upload-form')
       self.submit();
    }
  },
  submitAssetName: function() {
    var self = $('form.update-asset-name-form');
    var q = self.formParams();
    var params = {};
    var errors = 0;

    $('button.update-asset-name-submit-button').attr('disabled', true).find('span').text('Loading...');

    if (q.id) {
      params.id = q.id;
    };

    if (q.ip_address) {
      params.ip_address = q.ip_address;
    } else {
      errors++;
    };

    if (q.name) {
      params.name = q.name;
    } else {
      errors++;
      $('input#edit-asset-name-title').addClass('error');
    };

    if (q.global) {
      params.global = true;
    } else {
      params.global = false;
      if (q.agents) {
        params.sensors = q.agents;
      } else {
        errors++;
        $('#edit-asset-name-agent-select_chzn .chzn-choices').addClass('error');
      };
    };
    if (Snorby.submitAjaxRequestAssetName) {
      Snorby.submitAjaxRequestAssetName.abort();
    };

    if (errors <= 0) {
      Snorby.submitAjaxRequestAssetName = $.ajax({
        url: '/asset_names/add',
        dataType: "json",
        data: params,
        type: "post",
        success: function(data) {
          $.limpClose();
          var agent_ids = [];

          for (var i = 0; i < data.asset_name.sensors.length; i += 1) {
            agent_ids.push(parseInt(data.asset_name.sensors[i]));
          }

          $('ul.table div.content li.event div.address').each(function() {
            var self = $(this).parents('li.event');
            var address = $('div.asset-name', this);
            var addr = $(this).attr('data-address');
            var id = parseInt(self.attr('data-agent-id'));

            if (addr === data.asset_name.ip_address) {

              self.find('dd a.edit-asset-name').each(function() {
                var ip = $(this).attr('data-ip_address');
                if (addr === ip) {
                  $(this).attr('data-asset_agent_ids', agent_ids);
                  $(this).attr('data-asset_global', data.asset_name.global);
                  $(this).attr('data-asset_name', data.asset_name.name);
                };
              });

              if (data.asset_name.global) {
                address.text(data.asset_name.name);
              } else {
                if ($.inArray(id, agent_ids) !== -1) {
                  address.text(data.asset_name.name);
                } else {
                  address.text(data.asset_name.ip_address);
                };
              };
            };

          });
        },
        error: function(a,b,c) {
          $('button.update-asset-name-submit-button').attr('disabled', false).find('span').text('Update');
          flash_message.push({
            type: 'error',
            message: "Error: " + c
          });
          flash();
        }
      });
    } else {
      $('button.update-asset-name-submit-button').attr('disabled', false).find('span').text('Update');
      flash_message.push({
        type: 'error',
        message: "Please make sure all form fields are correctly populated."
      });
      flash();
    }; // no errors

  },

	
  setup: function(){
    $( ".portlet-column" ).sortable({
      placeholder: 'widget-placeholder',
      connectWith: ".portlet-column",
      cursor: 'crosshair',
      opacity: 0.6,
      revert: true,
      dropOnEmpty: true,
      appendTo: '#widgets',
      handle: '.portlet-header .wtitle',
      stop: function(event, ui) {
        var this_colum = parseInt($(this).attr('data'));
        var id = $(ui.item).attr('data');

        if (this_colum>=0 && id>=0) {
          //I would like to check if the final dropped position is valid
          var column_position = $(ui.item).parents(".portlet-column").attr('data');
          var position = $(ui.item).prevAll().length;

          //$(ui.item).find('.portlet-header').append('<img class="loading" src="/images/icons/pager.gif"/>')
          queue_ajax($.ajax({
            type: 'POST',
            url: '/widgets/change_position',
            data: {
              id: id,
              column_position: column_position,
              position: position
            },
            success: function(data) {
              //$(ui.item).find('.portlet-header').find("img.loading").remove();
            }
          }));

        } else {
          event.preventDefault();
        }
      }
    });

    $( ".portlet" ).addClass( "ui-widget ui-widget-content ui-helper-clearfix ui-corner-all" );
    $(".portlet-header .toolbar").addClass("ui-widget-header ui-corner-all" );

    $(".portlet").live({
      mouseenter: function (over) {
        $(this).find(".portlet-header .toolbar").animate({"opacity": 1});
        $(this).find(".show_on_hover").animate({"opacity": 1});
      },
      mouseleave: function (out) {
        $(this).find(".portlet-header .toolbar").animate({"opacity": 0});
        var button = $(this).find(".show_on_hover")
        if (!button.hasClass("loading"))
          button.animate({"opacity": 0});
      }
    });

    $('#widgets .expand a').live('click', function(e) {
      e.preventDefault();
      var expand = $(this).parents(".expand:first")
      var portlet = $(this).parents(".portlet:first")
      var id = portlet.attr('data')
      if (!expand.hasClass('loading') && !expand.hasClass('loaded') && id>0) {
        var last_html = expand.html();
        expand.addClass('loading').html('<img src="/images/icons/pager.gif" style="opacity: 1;"/>');

        var start_time = portlet.find(".start_time").html()
        var end_time = portlet.find(".end_time").html()

        queue_ajax($.ajax({
          url: '/widgets/' +id +'/show_table',
          data: {
            start_time: start_time,
            end_time: end_time
          },
          success: function(data) {
            expand.addClass('loaded').addClass('showed');
            expand.removeClass("loading");
            expand.html(last_html);
            expand.find("a div.row").html('Hide');
            portlet.find(".table-chart").slideDown('slow');
          }
        }));
      } else if (expand.hasClass('loaded')) {
        if (expand.hasClass('showed')) {
          expand.find("a div.row").html('Show');
          portlet.find(".table-chart").slideUp('slow');
        } else {
          expand.find("a div.row").html('Hide');
          portlet.find(".table-chart").slideDown('slow');
        }
        expand.toggleClass('showed');
      }
      return false;
    });

    $( ".portlet-header .reload-widget" ).live('click', function(e) {
      var portlet = $(this).parents(".portlet");
      return reload_widget(portlet, e);
    });

    $( ".portlet-header .close-widget" ).live('click', function(e) {
      e.preventDefault();
      var portlet = $(this).parents(".portlet");
      var id = portlet.attr('data');

      if (confirm("Are you sure you want to delete this widget?")){
        var self    = this
        $(self).css('opacity', '0.4');
        portlet.effect( "blind", {}, 700, null );
        //update it for next reload
        queue_ajax($.ajax({
          type: 'POST',
          url: '/widgets/' +id +'/remove',
          success: function(data) {
            $(self).css('opacity', '1');
            portlet.remove();
            flash_message.push({
              type: 'error',
              message: "Widget removed successfully"
            });
            flash();
            $.scrollTo('#header', 500);
          },
          fail: function(data) {
            portlet.show();
            flash_message.push({
              type: 'error',
              message: "The widget has not been removed successfully"
            });
            flash();
            $.scrollTo('#header', 500);
          }
        }));
      }
      return false;
    });

    $('.portlet-header .visibility').live('click', function(e) {
      e.preventDefault();
      var contentPortlet = $(this).parents(".graphcontainer:first").find(".portlet-content");
      var chart          = get_chart(this);
      var minimized      = !$(this).hasClass('plus') ? 1 : 0;
      var id             = $(this).parents(".portlet:first").attr('data');

      if (chart!=undefined && !minimized && !contentPortlet.hasClass("MAP")  ) {
        contentPortlet.css('opacity', 0);
      }

      $(this).toggleClass("minus" ).toggleClass( "plus" );

      $(this).parents( ".portlet:first" ).find( ".portlet-content" ).slideToggle('slow', function() {
        // Animation complete.
        if (!contentPortlet.hasClass("MAP")) {
          if (chart!=undefined && !minimized) {          
            chart.setSize(parseInt(contentPortlet.width()), 280 );
          }
          contentPortlet.css('opacity', 1);
        }
      });
      
      $(this).hide();
      if ($(this).hasClass("plus")) {
        $(this).parent().prepend('<img alt="Widget_minus" height="16" src="/images/icons/widget_plus.png" width="16" class="visibility plus"></img>')
      } else {
        $(this).parent().prepend('<img alt="Widget_minus" height="16" src="/images/icons/widget_minus.png" width="16" class="visibility minus"></img>')
      }
      $(this).remove();
      
      //update it for next reload
      queue_ajax($.ajax({
        type: 'POST',
        url: '/widgets/change_visibility',
        data: {
          id: id,
          minimized: minimized
        }
      }));

      return false;
    });

    $( ".portlet-column" ).disableSelection();

    //end portlet


		
    $(window).resize(function() {
      $.fancybox.center;
    });

    $.fn.tipsy.defaults = {
        delayIn: 0,      // delay before showing tooltip (ms)
        delayOut: 0,     // delay before hiding tooltip (ms)
        fade: false,     // fade tooltips in/out?
        fallback: '',    // fallback text to use when no tooltip text
        gravity: 'n',    // gravity
        html: false,     // is tooltip content HTML?
        live: false,     // use live event support?
        offset: 0,       // pixel offset of tooltip from element
        opacity: 0.9,    // opacity of tooltip
        title: 'title',  // attribute/callback containing tooltip text
        trigger: 'hover' // how tooltip is triggered - hover | focus | manual
    };
		
    $('div#flash_message, div#flash_message > *').live('click', function() {
      $('div#flash_message').stop().fadeOut('fast');
    });
		
    $("#growl").notify({
      speed: 500,
      expires: 5000
    });
		
    $('.edit-sensor-name').editable("/sensors/update_name", {
      height: '20px',
      width: '180px',
      name: "name",
      indicator: '<img src="/images/icons/pager.gif">',
      data: function(value) {
        var retval = value.replace(/<br[\s\/]?>/gi, '\n');
        return retval;
      },
      submitdata : function() {
        return {
          id: $(this).attr('data-sensor-id'),
          authenticity_token: csrf
        };
      }
    });

    $('.edit-sensor-ip').editable("/sensors/update_ip", {
      height: '20px',
      width: '100px',
      name: "ip",
      indicator: '<img src="/images/icons/pager.gif">',
      data: function(value) {
        var retval = value.replace(/<br[\s\/]?>/gi, '\n');
        return retval;
      },
      submitdata : function() {
        return {
          id: $(this).attr('data-sensor-id'),
          authenticity_token: csrf
        };
      }
    });

    $('.edit-snort-text-name').editable("/snort_stats/update_text_name", {
      height: '20px',
      width: '100px',
      name: "text_name",
      indicator: '<img src="/images/icons/pager.gif">',
      data: function(value) {
        var retval = value.replace(/<br[\s\/]?>/gi, '\n');
        return retval;
      },
      submitdata : function() {
        return {
          id: $(this).attr('data-snort-name-id'),
          authenticity_token: csrf
        };
      }
    });

    $('.edit-snort-measure-unit').editable("/snort_stats/update_measure_unit", {
      height: '20px',
      width: '100px',
      name: "measure_unit",
      indicator: '<img src="/images/icons/pager.gif">',
      data: function(value) {
        var retval = value.replace(/<br[\s\/]?>/gi, '\n');
        return retval;
      },
      submitdata : function() {
        return {
          id: $(this).attr('data-snort-name-id'),
          authenticity_token: csrf
        };
      }
    });


    $(document).ready(function()  {
      if ($("#sensorTable").length > 0) {
        $("#sensorTable").treeTable();
      }
    });
  },
	
  pages: {
		
    classifications: function(){
      $('a.classification').live('click', function() {
        var class_id = $(this).attr('data-classification-id');
        set_classification(class_id);
        return false;
      });
    },

    dashboard_sensor: function() {
      $('#dashboard-sensor-info .dashboard-header > span.title').live('click', function() {
        var column = $("#dashboard .secondary")
        if (!column.hasClass(loading_class)){
          column.addClass(loading_class);
          $("#dashboard-sensor-other-content, #dashboard-sensor-load-content").hide();
          $("#dashboard-sensor-info-content").fadeIn('slow', function() {
            column.removeClass(loading_class);
          });
          $("#title-menu li").show()
        }
        
        return false;
      });

      $('#dashboard-sensor-rules .dashboard-header > span.title').live('click', function() {
        reload_dashboard_sensor("rules");
        return false;
      });

      $('#dashboard-sensor-load .dashboard-header > span.title').live('click', function() {
        reload_dashboard_sensor("load");
        return false;
      });

      $('#dashboard-sensor-hardware .dashboard-header > span.title').live('click', function() {
        reload_dashboard_sensor("hardware");
        return false;
      });

      $('#dashboard-sensor-segments .dashboard-header > span.title').live('click', function() {
        reload_dashboard_sensor("segments");
        return false;
      });

      $('#dashboard-sensor-other-content .category > .row').live('click', function() {
        $($(this).parents('.boxit')[0]).children(".table").toggle('fast');
        //$(this).parent().toggleClass('highlight');
      });
    },

    rules: function() {
      $('li.sensor-options a').live('click', function(event) {
        var sid = $(this).parent('li').attr('data-sensor-id');
        event.preventDefault();
        var elements = $('dl.sensor-menu');
        for (var i = 0; i < elements.length; i++){
          var sid_aux = $(elements[i]).attr('data-sensor-id');
          if (sid != sid_aux){
            elements[i].style.display = 'none';
          }
        }
        $('dl#sensor-menu-'+sid).toggle();
        return false;
      });
      
      $('li.ip-options a').live('click', function(ip_element) {
        var ip = $(this).parent('li').attr('data-ip');
        ip_element.preventDefault();
        var elements = $('dl.ip-menu');
        for (var i = 0; i < elements.length; i++){
          var ip_aux = $(elements[i]).attr('data-ip');
          if (ip != ip_aux){
            elements[i].style.display = 'none';
          }
        }
        $('dl#ip-menu-'+ip).toggle();
        return false;
      });

      $('dl#sensor-menu a').live('click', function(event) {
        $(this).parents('dl').fadeOut('fast');
        return false;
      });

      $('dl.sensor-menu a').live('click', function(event) {
        $(this).parents('dl').fadeOut('fast');
      });
      
      $('dl.ip-menu dd a').live('click', function(ip) {
        $(this).parents('dl').fadeOut('fast');
      });

      $('dl.rule_actions dd').live('click', function(event) {
        if ($(this).parents(".row").children(".important").children(".not-allow-overwrite.disabled").length == 0) {
          var id = $(this).parents('li').first().attr('data');
          var class_type = $(this).parents('li').first().attr('class').replace(' currently-over', '');
          event.preventDefault();
          var elements = $('dl.rule_actions-menu');
          for (var i = 0; i < elements.length; i++){
            var id_aux = $(elements[i]).parents('li').first().attr('data');
            var class_type_aux = $(elements[i]).parents('li').first().attr('class').replace(' currently-over', '');
            if (id != id_aux || class_type != class_type_aux){
              elements[i].style.display = 'none';
            }
          }
          $(this).parent().next('.rule_actions-menu').toggle();
        }
        return false;
      });

      $('#wrapper').live('click', function() {
        if ($('dl#admin-menu').is(':visible')) {
          $('dl#admin-menu').fadeOut('fast');
        };
      });

      $('td.search-by-signature').live('click', function(event) {
        event.preventDefault();
        var url = $(this).attr('data-url');
        window.location = url;
      });
    },
		
    dashboard: function(){
      $('a.close-tab').live('click', function(e) {
        var data_column = $(this).attr('data_column');
        if ($('ul#box-menu li').length == 1){
          e.preventDefault();
          return false;
        }
        if ($(this).parent().hasClass('active')){
          if ($(this).parent().prev().length == 0) {
            var new_tab = $(this).parent().next();
          } else {
            var new_tab = $(this).parent().prev();
          }
          new_tab.addClass('active');
          new_tab.children('a.show_metric').trigger('click');
        }
        $(this).parent().remove();
        $('div.dashboard-graph[data_column='+ data_column +']').remove();
      });

      $('dl#tab a').live('click', function(e) {
        var data_column = $(this).attr('data_column');
        $('ul#box-menu').append('<li class="data_column loading" data_column="' +data_column +'"> <a href="#" class="show metric" data_column=' +data_column +'>'+ $(this).html() +'</a> <a href="#" class="close-tab" data_column=' +data_column +'><img style="width:10px;" class="loading-tab" src="/images/icons/loading.gif"></a></li>');
        $('div.box-large-inside').append('<div class="dashboard-graph" style="display:none;" data_column=' +data_column +'></div>');
        $(this).parent('dd').hide();
      });

      $('a.show_metric').live('click', function(e) {
        if ($(this).parent().hasClass("loading")) {
          flash_message.push({
            type: 'error',
            message: "The selected tab is loading. Please wait ..."
          });
          flash();
        } else if ($(this).parent().hasClass("snmp")) {
          var data_column = $(this).attr('data_column');
          $('#box-menu li.snmp').removeClass('active');
          $(this).parent('li').addClass('active');
          $('div.dashboard-graph.snmp').hide();
          $('div#metric-graph_'+ data_column).show();

          var graph = $('div.dashboard-graph[data_column='+ data_column +']')
          if(graph.length > 0){
            var width  = graph.width();
            var height = graph.height();
            var chart  = window[data_column +"-graph"];
            chart.setSize(width, height);
          }
          
        } else {
          var data_column = $(this).attr('data_column');        
          $('#box-menu li.data_column').removeClass('active');
          $(this).parent('li.data_column').addClass('active');
          $('div.dashboard-graph').hide();
          $('div.dashboard-graph[data_column='+ data_column +']').show();
          
          //Cargamos los mapas o recargamos las gráficas
          if(data_column == "MAP"){
            Gmaps.loadMaps();
          } else {
            var graph = $('div.dashboard-graph[data_column='+ data_column +']')
            if(graph.length > 0){
              var width  = graph.width();
              var height = graph.height();
              var chart  = window[data_column +"-graph"];
              chart.setSize(width, height);
            }
          }
        } 
        return false;
      });
			
      $('#box-holder div.box').live('click', function(e) {
        e.preventDefault();
        window.location = $(this).attr('data-url');
        return false;
      });
			
    },
		
    events: function(){
			
      $('select.email-user-select').live('change', function(e) {
        var email = $('select.email-user-select').val();
				
        if (email != '') {
          if ($('input#email_to').val() == '') {
            $('input#email_to').val(email);
          } else {
            $('input#email_to').val($('input#email_to').val() + ', ' + email);
          };
        };
      });
			
      $('button.email-event-information').live('click', function(e) {
        e.preventDefault();
        if ($('input#email_to').val() == '') {
          flash_message.push({
            type: 'error',
            message: "The email recipients cannot be blank."
          });
          flash();
          $.scrollTo('#header', 500);
        } else {
          if ($('input#email_subject').val() == '') {
            flash_message.push({
              type: 'error',
              message: "The email subject cannot be blank."
            });
            flash();
            $.scrollTo('#header', 500);
          } else {
            $('a#fancybox-close').click();
            $.post('/events/email', $('form.email-event-information').serialize(), null, "script");
          };
        };
        return false;
      });
			
      $('button.request_packet_capture').live('click', function(e) {
        e.preventDefault();
        if ($(this).attr('data-deepsee')) {
          $('form.request_packet_capture input#method').val('deepsee')
        };
        $.post('/events/request_packet_capture', $('form.request_packet_capture').serialize(), null, "script");
        return false;
      });
			
      $('dl#event-sub-menu a').live('click', function(e) {
        $('dl#event-sub-menu').hide();
      });
			
      $('a.has-event-menu').live('click', function(e) {
        e.preventDefault();
        var menu = $(this).parent().find('dl.event-sub-menu');
        if (menu.is(':visible')) {
          menu.fadeOut('fast')
        } else {
          $('dl.event-sub-menu').hide();
          menu.fadeIn('fast')
        };
        return false;
      });
		
      $('dl.event-sub-menu dd a').live('click', function(event) {
        $(this).parents('dl').fadeOut('fast');
      });

      $('button.mass-action').live('click', function(e) {
        e.preventDefault();
        var nform = $('form#mass-action-form');
        $('a#fancybox-close').click();
        $.post('/events/mass_action', nform.serialize(), null, "script");
        return false;
      });
			
      $('button.create-notification').live('click', function(e) {
        e.preventDefault();
        var nform = $('form#new_notification');
        $.post('/notifications', nform.serialize(), null, "script");
        $('a#fancybox-close').click();
        return false;
      });
			
      $('button.cancel-snorbybox').live('click', function(e) {
        e.preventDefault();
        $('a#fancybox-close').click();
        return false;
      });
			
      $('ul.payload-tabs li a').live('click', function(e) {
        e.preventDefault();
				
        var div_class = $(this).attr('data-div');
				
        $(this).parents('ul').find('li').removeClass('current');
        $(this).parent('li').addClass('current');
        $('div.payload-holder').hide();
				
        $('div.'+div_class+' pre').css('opacity', 0);
				
        $('div.'+div_class).show();
				
        $('div.'+div_class+' pre').stop().animate({
          "opacity": 1
        }, 1000);
				
        return false;
      });
			
			
      $('a.export').live('click', function(e) {
        e.preventDefault();
        var selected_events = $('input#selected_events').attr('value');
				
        if (selected_events) {
					
          $.post(this.href, {
            events: selected_events,
            authenticity_token: csrf
          });
					
        } else {
          flash_message.push({
            type: 'error',
            message: "Please select Events to perform this action"
          });
          flash();
        };
				
        return false;
      });
		
      $('a.edit-event-note').live('click', function(e) {
        e.preventDefault();
        var note = $(this).parents('div.event-note');
        var note_id = $(this).attr('data-note-id');
        $.getScript('/notes/' + note_id + '/edit');
        return false;
      });
			
      $('a.destroy-event-note').live('click', function(e) {
        e.preventDefault();
        var note = $(this).parents('div.event-note');
        var note_id = $(this).attr('data-note-id');
				
        if ( confirm("Are you sure you want to delete this note?") ) {
          $('div.notes').fadeTo(500, 0.4);
          $.post('/notes/destroy', {
            id: note_id,
            authenticity_token: csrf,
            '_method': 'delete'
          }, null, 'script');
        };
				
        return false;
      });

      $('a.destroy-main-note').live('click', function(e) {
        e.preventDefault();

        var note_id = $(this).attr('data-note-id');
        
        if ($(this).attr('data_class') == 'reputation'){
          var path = '/reputations/destroy_note';
        } else {
          var path = '/event_filterings/destroy_note';
        };
        
        if ( confirm("Are you sure you want to delete this note?") ) {
          $('div.notes').fadeTo(500, 0.4);
          $.post(path, {
            id: note_id,
            authenticity_token: csrf,
            '_method': 'delete'
          }, null, 'script');
        };
        
        return false;
      });

      $('a.destroy-rule-note').live('click', function(e) {
        e.preventDefault();
        var note_id = $(this).attr('data-note-id');

        if ( confirm("Are you sure you want to delete this note?") ) {
          $('div.notes').fadeTo(500, 0.4);
          $.post('/rule_notes/destroy', {
            id: note_id,
            authenticity_token: csrf,
            '_method': 'delete'
          }, null, 'script');
        };

        return false;
      });
			
      $('button.add_new_note-working').live('click', function(e) {
        e.preventDefault();
        return false;
      });
			
      $('button.cancel-note').live('click', function(e) {
        e.preventDefault();
        $(this).parents('div#new_note_box').remove();
        $('ul.table div.content li').removeClass('currently-over');
        return false;
      });
			
      $('button.add_new_note').live('click', function(e) {
        e.preventDefault();
        var event_sid = $(this).parent('div#form-actions').parent('div#new_note').attr('data-event-sid');
        var event_cid = $(this).parent('div#form-actions').parent('div#new_note').attr('data-event-cid');
				
        if ($('div#new_note_box').length > 0) {
					
        } else {
          $(this).removeClass('add_new_note').addClass('add_new_note-working');
					
          var current_width = $(this).width();
          $(this).addClass('loading').css('width', current_width);
					
          $.get('/notes/new', {
            sid: event_sid,
            cid: event_cid,
            authenticity_token: csrf
          }, null, 'script');
        };
				
        return false;
      });

      $('button.add_new_main_note').live('click', function(e) {
        e.preventDefault();
        
        var object_id = $('div#new_main_note').attr('data-object-id');
        
        if ($(this).attr('data_class') == 'reputation'){
          var path = '/reputations/'+ object_id +'/new_note';
        } else {
          var path = '/event_filterings/'+ object_id +'/new_note';
        };

        if ($('div#new_note_box').length > 0) {
          
        } else {
          $(this).removeClass('add_new_main_note').addClass('add_new_note-working');
          
          var current_width = $(this).width();
          $(this).addClass('loading').css('width', current_width);
          
          $.get(path, {
            authenticity_token: csrf
          }, null, 'script');
        };
        
        return false;
      });
			

      $('button.submit_new_note').live('click', function(e) {
        e.preventDefault();
        var event_sid = $(this).parent('div#form-actions').parent('div#new_note').attr('data-event-sid');
        var event_cid = $(this).parent('div#form-actions').parent('div#new_note').attr('data-event-cid');
        var note_body = $(this).parent('div#form-actions').parent('div#new_note').find('textarea#body').val();
				
        if (note_body.length > 0) {
					
          var current_width = $(this).width();
          $(this).addClass('loading').css('width', current_width);
					
          $.post('/notes/create', {
            sid: event_sid,
            cid: event_cid,
            body: note_body,
            authenticity_token: csrf
          }, null, 'script');
					
        } else {
          flash_message.push({
            type: "error",
            message: "The note body cannot be blank!"
          });
          flash();
          $.scrollTo('#header', 500);
        };
				
        return false;
      });

      $('button.submit_new_main_note').live('click', function(e) {
        e.preventDefault();
        var object_id = $('div#new_main_note').attr('data-object-id');
        var note_body = $('div#new_main_note').find('textarea#body').val();
        
        if ($(this).attr('data_class') == 'reputation'){
          var path = '/reputations/' + object_id + '/create_note';
        } else {
          var path = '/event_filterings/' + object_id + '/create_note';
        };

        if (note_body.length > 0) {
          
          var current_width = $(this).width();
          $(this).addClass('loading').css('width', current_width);
          
          $.post(path, {
            body: note_body,
            authenticity_token: csrf
          }, null, 'script');
          
        } else {
          flash_message.push({
            type: "error",
            message: "The note body cannot be blank!"
          });
          flash();
          $.scrollTo('#header', 500);
        };
        
        return false;
      });
			
      $('a.query-data').live('click', function() {
        $('pre.query-data-content').hide();
        $('pre#' + $(this).attr('data-content-name')).show();
        return false;
      });
		
      $('a.snorbybox-content').live('click', function(event) {
        event.preventDefault();
        $('dl.drop-down-menu').fadeOut('slow');
        var content = $(this).attr('data-content');

        $.fancybox({
          padding: 0,
          content: content,
          centerOnScroll: true,
          zoomSpeedIn: 300,
          zoomSpeedOut: 300,
          overlayShow: true,
          overlayOpacity: 0.5,
          overlayColor: '#000',
          onStart: function() {
            Snorby.eventCloseHotkeys(false);
            $('dl#event-sub-menu').hide();
          },
          onClosed: function() {
            Snorby.eventCloseHotkeys(true);
          }
        });
      });

      $('a.snorbybox').live('click', function() {
        var self = $(this);

        $('dl.drop-down-menu').fadeOut('slow');
        $.fancybox({
          padding: 0,
          centerOnScroll: true,
          zoomSpeedIn: 300,
          zoomSpeedOut: 300,
          overlayShow: true,
          overlayOpacity: 0.5,
          overlayColor: '#000',
          href: this.href,
          onStart: function() {
            Snorby.eventCloseHotkeys(false);
            $('dl#event-sub-menu').hide();
          },
          onClosed: function() {
            Snorby.eventCloseHotkeys(true);
          },
          onComplete: function() {
            if($(self).hasClass('snorbybox-map')){
              Gmaps.load_map();
            }
          }
        });
        return false;
      });
			
      $('#events div.create-favorite.enabled').live('click', function() {
        var sid = $(this).parents('li.event').attr('data-event-sid');
        var cid = $(this).parents('li.event').attr('data-event-cid');
				
        $(this).removeClass('create-favorite').addClass('destroy-favorite');
        $.post('/events/favorite', {
          sid: sid,
          cid: cid,
          authenticity_token: csrf
        });
				
        var count = new Queue();
        count.up();
				
        return false;
      });
			
      $('#events div.destroy-favorite.enabled').live('click', function() {
        var sid = $(this).parents('li.event').attr('data-event-sid');
        var cid = $(this).parents('li.event').attr('data-event-cid');
        var action = $('div#events').attr('data-action');
				
        $(this).removeClass('destroy-favorite').addClass('create-favorite');
        $.post('/events/favorite', {
          sid: sid,
          cid: cid,
          authenticity_token: csrf,
          success: function(data) {
            if (action == 'queue') {
              $('div.content').not(".protected").fadeTo(500, 0.4);
              Snorby.helpers.remove_click_events(true);
              $('div.destroy-favorite').removeClass('enabled').css('cursor', 'default');
              $.get('/events/queue', null, null, "script");
            };
          }
        });
				
        var count = new Queue();
        count.down();
        return false;
      });

//      $('#rules div.create-favorite.enabled').live('click', function() {
//        var id  = $(this).parents("li.rule").attr("data")
//        $(this).removeClass('create-favorite').addClass('destroy-favorite');
//        $.post('/rules/favorite', {
//          id: id,
//          authenticity_token: csrf
//        });
//
//        var count = new Queue();
//        count.up();
//
//        return false;
//      });
//
//      $('#rules div.destroy-favorite.enabled').live('click', function() {
//        var id  = $(this).parents("li.rule").attr("data")
//        $(this).removeClass('destroy-favorite').addClass('create-favorite');
//        $.post('/rules/favorite', {
//          id: id,
//          authenticity_token: csrf
//        });
//
//        var count = new Queue();
//        count.down();
//
//        return false;
//      });

//      $('#rules div.allow-overwrite.enabled').live('click', function() {
//        var id    = $(this).parents("li.rule").attr("data")
//        var sensor_id = $("#rules").attr("data-sensor-sid");
//
//        $(this).removeClass('allow-overwrite').addClass('not-allow-overwrite');
//        $.post('/rules/allow_overwrite', {
//          id: id,
//          rule_id: id,
//          sensor_id: sensor_id,
//          allow_overwrite: "0",
//          authenticity_token: csrf
//        });
//        return false;
//      });

//      $('#rules div.not-allow-overwrite.enabled').live('click', function() {
//        var id    = $(this).parents("li.rule").attr("data")
//        var sensor_id = $("#rules").attr("data-sensor-sid");
//
//        $(this).removeClass('not-allow-overwrite').addClass('allow-overwrite');
//        $.post('/rules/allow_overwrite', {
//          id: id,
//          rule_id: id,
//          sensor_id: sensor_id,
//          allow_overwrite: "1",
//          authenticity_token: csrf
//        });
//        return false;
//      });
			
      $('ul.table div.content li.event div.click').live('click', function() {
        var self = $(this);

        $('dl#event-sub-menu').hide();
				
        var sid = $(this).parents('li').attr('data-event-sid');
        var cid = $(this).parents('li').attr('data-event-cid');
        var parent_row = $('li#event_'+sid+''+cid);
        var check_box = $('li#event_'+sid+''+cid+' input#event-selector');
        if (!check_box.is(':visible'))
          check_box = $('li#event_'+sid+''+cid+' .create-favorite');
				
        var current_row = $('li#event_'+sid+''+cid+' div.event-data');
				
        Snorby.helpers.remove_click_events(true);
        $('li.event').removeClass('highlight');
				
        if (!current_row.is(':visible')) {
          parent_row.addClass('highlight');
        } else {
          parent_row.removeClass('highlight');
        };
				
        if (current_row.attr('data') == 'true') {
          Snorby.helpers.remove_click_events(false);

          if (current_row.is(':visible')) {
            
            current_row.slideUp('fast', function () {
              $('li.event div.event-data').slideUp('fast');
              Snorby.eventCloseHotkeys(true);
            });
            
          } else {
            $('li.event div.event-data').slideUp('fast');
            current_row.slideDown('fast', function() {

              $(document).bind('keydown', 'esc', function() {
                $('li.event').removeClass('highlight');
                parent_row.removeClass('highlight');

                current_row.slideUp('fast', function () {
                  $('li.event div.event-data').slideUp('fast');
                });
              
                Snorby.eventCloseHotkeys(true);
                $(this).unbind('keydown', 'esc');
              });

              Snorby.eventCloseHotkeys(false);
            });
          };

        } else {

          check_box.hide();
          
          $('li.event div.event-data').slideUp('fast');
          parent_row.find('div.select').append("<img alt='laoding' src='/images/icons/loading.gif' class='select-loading'>");

          $.get('/events/show/'+sid+'/'+cid, function () {
            $(document).bind('keydown', 'esc', function() {
              $('li.event').removeClass('highlight');
              parent_row.removeClass('highlight');

              current_row.slideUp('fast', function () {
                $('li.event div.event-data').slideUp('fast');
              });
            
              $(this).unbind('keydown', 'esc');
              Snorby.eventCloseHotkeys(true);
            });

            Snorby.helpers.remove_click_events(false);

            $('.select-loading').remove();
            check_box.show();
            current_row.attr('data', true);
            Snorby.eventCloseHotkeys(false);
          }, 'script');
					
        };
				
        return false;
      });

      $('div.new_events').live('click', function() {
        $(this).remove();
        $('div#events').animate({"opacity": 0.7});
        $.getScript('/events')
        return false;
      });

    },
		
  },
	
  eventCloseHotkeys: function(bind) {
    if (bind) {
      $(document).bind('keydown', '1', Snorby.hotKeyCallback.Sev1);
      $(document).bind('keydown', '2', Snorby.hotKeyCallback.Sev2);
      $(document).bind('keydown', '3', Snorby.hotKeyCallback.Sev3);

      $(document).bind('keydown', 'shift+right', Snorby.hotKeyCallback.shiftPlusRight);
      $(document).bind('keydown', 'right', Snorby.hotKeyCallback.right);			
      $(document).bind('keydown', 'shift+left', Snorby.hotKeyCallback.shiftPlusLeft);
      $(document).bind('keydown', 'left', Snorby.hotKeyCallback.left);      
    } else {
      
      $(document).unbind('keydown', Snorby.hotKeyCallback.Sev1);
      $(document).unbind('keydown', Snorby.hotKeyCallback.Sev2);
      $(document).unbind('keydown', Snorby.hotKeyCallback.Sev3);
      
      $(document).unbind('keydown', Snorby.hotKeyCallback.shiftPlusRight);
      $(document).unbind('keydown', Snorby.hotKeyCallback.right);			
      $(document).unbind('keydown', Snorby.hotKeyCallback.shiftPlusLeft);
      $(document).unbind('keydown', Snorby.hotKeyCallback.left);
    }
  },

  admin: function(){
    
    $('#users input#enabled').live('click', function(e) {
      var user_id = $(this).parent('td').attr('data-user');
      if ($(this).attr('checked')) {
        $.post('/users/toggle_settings', {
          user_id: user_id,
          user: {
            enabled: true
          },
          authenticity_token: csrf
        });
      } else {
        $.post('/users/toggle_settings', {
          user_id: user_id,
          user: {
            enabled: false
          },
          authenticity_token: csrf
        });
      };
    });
		
    $('#users input#admin').live('click', function(e) {
      var user_id = $(this).parent('td').attr('data-user');
      if ($(this).attr('checked')) {
        $.post('/users/toggle_settings', {
          user_id: user_id,
          user: {
            admin: true
          },
          authenticity_token: csrf
        });
      } else {
        $.post('/users/toggle_settings', {
          user_id: user_id,
          user: {
            admin: false
          },
          authenticity_token: csrf
        });
      };
    });
		
    $('#severity-color-bg').ColorPicker({
      color: $('#severity-color-bg').attr('value'),
      onShow: function (colpkr) {
        $(colpkr).fadeIn(500);
        return false;
      },
      onHide: function (colpkr) {
        $(colpkr).fadeOut(500);
        return false;
      },
      onSubmit: function(hsb, hex, rgb, el) {
        $(el).ColorPickerHide();
      },
      onChange: function (hsb, hex, rgb) {
        $('#severity-color-bg').val('#'+hex);
        $('span.severity').css('backgroundColor', '#' + hex);
      }
    });
		
    $('#severity-color-text').ColorPicker({
      color: $('#severity-color-text').attr('value'),
      onShow: function (colpkr) {
        $(colpkr).fadeIn(500);
        return false;
      },
      onHide: function (colpkr) {
        $(colpkr).fadeOut(500);
        return false;
      },
      onSubmit: function(hsb, hex, rgb, el) {
        $(el).ColorPickerHide();
      },
      onChange: function (hsb, hex, rgb) {
        $('#severity-color-text').val('#'+hex);
        $('span.severity').css('color', '#' + hex);
      }
    });
  },
	
  templates: {
	
    render: function(source, data) {
      var self = this;

      var template = Handlebars.compile(source);
      return template(data);
    },

    flash: function(data){
      var self = this;

      var template = " \
			<div class='{{type}}' id='flash_message' style='display:none;'> \
				<div class='message {{type}}'>{{message}}</div> \
			</div>";
      return Snorby.templates.render(template, data);
    },
		
    event_table: function(data){
      var self = this;
      
      var klass = '';
      if (data.events[0].geoip) {
        klass = ' geoip'
      };

      var template = " \
			{{#events}} \
			<li id='event_{{sid}}{{cid}}' class='event' style='display:none;' data-event-id='{{sid}}-{{cid}}' data-event-sid='{{sid}}' data-event-cid='{{cid}}'> \
				<div class='row"+klass+"'> \
					<div class='select small'><input {{enable_disable}}='true' class='event-selector' id='event-selector' name='event-selector' type='checkbox'></div> \
					<div class='important small'><div class='create-favorite enabled'></div></div> \
					<div class='severity small'><span class='severity sev{{severity}}'>{{severity}}</span></div> \
					<div class='click domain'>{{domain}}</div> \
          <div class='click sensor'>{{hostname}}</div> \
          <div class='click src_ip address'> \
            {{{geoip this.src_geoip}}} {{ip_src}} \
          </div> \
					<div class='click dst_ip address'> \
            {{{geoip this.dst_geoip}}} {{ip_dst}} \
          </div> \
					<div class='click signature'>{{message}}</div> \
					<div class='click timestamp'> \
            <b class='add_tipsy' title='Event ID: {{sid}}.{{cid}} &nbsp; {{datetime}}'>{{timestamp}}</b> \
          </div> \
				</div> \
				<div style='display:none;' class='event-data' data='false'></div> \
			</li> \
			{{/events}}"
			
      return Snorby.templates.render(template, data);
    },
    
    update_notifications: function(data) {
      var self = this;
      var template = '<div id="update-notification">' +
        '<span>' + 
        '<div class="message-update-notification">' +
        'A new version of Snorby is now avaliable. ' +
        '</div>' +
        'Version {{version}} - ' +
        '' +
        '<a href="{{download}}" target="_blank">Download</a>  - ' +
        '<a href="{{changeLog}}" target="_blank">Change Log</a>' +
        '' +
        '<div class="close-update-notification">x</div>' +
        '</span>' +
        '</div>';


      $('div.close-update-notification').live('click', function(e) {
        e.preventDefault();
        $.cookie('snorby-ignore-update', 1, { expires: 20 });
        $('div#update-notification').remove();
      });

      return Snorby.templates.render(template, data);
    },

    searchLoading: function() {
      var self = this;
      var template = '<div class="search-loading" />';
      return template;
    },

    signatureTable: function() {
      var self = this;
      var template = '<div id="signatures-input-search" class="grid_12 page boxit" style="display: block;">' +
        '<table class="default" border="0" cellspacing="0" cellpadding="0">' +
        '<tbody><tr><th style="width:30px">Sev.</th><th>Signature Name</th><th>Event Count</th><th></th></tr></tbody>' +
        '<tbody class="signatures content">' +
        '</tbody>' +
        '</table>' +
        '</div>';

      return template;
    },

    sensorTable: function() {
      var self = this;
      var template = '<div id="sensors-input-search" class="grid_12 page boxit" style="display: block;">' +
        '<table class="default" border="0" cellspacing="0" cellpadding="0">' +
        '<tbody><tr><th>Sensor Name</th><th>Event Count</th><th></th></tr></tbody>' +
        '<tbody class="sensors content">' +
        '</tbody>' +
        '</table>' +
        '</div>';

      return template;
    },

    signatures: function(data) {
      var self = this;
      var event_count = data.total;

      var template = '{{#each signatures}}' +
        '<tr>' +
          '<td class="first">' +
            '<div class="severity small">' +
              '<span class="severity sev{{sig_priority}}">' +
                '{{sig_priority}}' +
              '</span>' +
            '</div>' +
          '</td>' +
          '<td class="" title="{{sig_name}}">' +
            '{{{truncate this.sig_name 60}}}' +
          '</td>' +
          '<td class="chart-large add_tipsy" original-title="{{events_count}} of {{../total}} events">' +
            '<div class="progress-container-large">' +
              '<div style="width: {{{percentage ../total}}}%">' +
                '<span>{{{percentage ../total}}}%</span>' +
              '</div>' +
            '</div>' +
          '</td>' +
          '<td class="last" style="width:45px;padding-right:6px;padding-left:0px;">' +
            '<a href="/results?search%5Bcolumn%5D=signature&search%5Boperator%5D=is&search%5Bvalue%5D={{sig_id}}">View</a>' +
          '</td>' +
        '</tr>{{/each}}'; 
      return Snorby.templates.render(template, data);

    },

    sensors: function(data) {
      var self = this;
      var event_count = data.total;

      var template = '{{#each sensors}}' +
        '<tr>' +
          '<td class="first" title="{{name}}">' +
            '{{{truncate this.name 100}}}' +
          '</td>' +
          '<td class="chart-large add_tipsy" original-title="{{events_count}} of {{../total}} events">' +
            '<div class="progress-container-large">' +
              '<div style="width: {{{percentage ../total}}}%">' +
                '<span>{{{percentage ../total}}}%</span>' +
              '</div>' +
            '</div>' +
          '</td>' +
          '<td class="last" style="width:45px;padding-right:6px;padding-left:0px;">' +
            '<a href="/results?search%5Bcolumn%5D=sensor&search%5Boperator%5D=is&search%5Bvalue%5D={{sid}}">View</a>' +
          '</td>' +
        '</tr>{{/each}}'; 
      return Snorby.templates.render(template, data);
    }
    
  },
	
  notification: function(message){
    $('#growl').notify("create", message,{
      expires: 3000,
      speed: 500
    });
  },
	
  helpers: {
		
    tipsy: function(){
			
      $('.add_tipsy').tipsy({
        fade: true,
        html: false,
        gravity: 's',
        live: true
      });
			
      $('.add_tipsy_html').tipsy({
        fade: true,
        html: true,
        gravity: 's',
        live: true
      });

    },
		
    input_style: function(){

      $('div#form-actions button.cancel').live('click', function() {
        window.location = '/';
        return false;
      });
			
      $('input[name=blank]').focus();

    },
		
    dropdown: function(){
			
      $(document).click(function() {
        $('dl.drop-down-menu:visible').hide();
      });
			
      $('dl.drop-down-menu dd a').live('click', function() {
        $('dl.drop-down-menu').fadeOut('slow');
        return true;
      });

      $('dl.drop-down-menu').hover(function() {
        var timeout = $(this).data("timeout");
        if(timeout) clearTimeout(timeout);
      }, function() {
        $(this).data("timeout", setTimeout($.proxy(function() {
          $(this).fadeOut('fast');
        }, this), 500));
      });
			
      $('a.has_dropdown').live('click', function() {
				
        var id = $(this).attr('id');
        var dropdown = $(this).parents('li').find('dl#'+id);
				
        $('dl.drop-down-menu').each(function(index) {
				  
          if (id === $(this).attr('id')) {
						
            if ($(this).is(':visible')) {
              dropdown.fadeOut('fast');
            } else {
              dropdown.slideDown({
                duration: 'fast',
                easing: 'easeOutSine'
              });
            };
						
          } else {
            $(this).fadeOut('fast')
          };

        });
        return false;
      });
    },
		
    persistence_selections: function() {
			
      $('input#event-selector').live('change', function() {
				
        var event_id = $(this).parents('li').attr('data-event-id');
				
        if ($(this).attr('checked')) {
					
          selected_events.push(event_id);
          $('input#selected_events[type="hidden"]').val(selected_events);
					
        } else {
					
          var removeItem = event_id;
          selected_events = jQuery.grep(selected_events, function(value) {
            return value != removeItem;
          });
					
          $('input#selected_events[type="hidden"]').val(selected_events);
        };
				
      });
			
      $('input#event-select-all').live('change', function() {

        if ($(this).attr('checked')) {

          $('ul.table div.content li input[type="checkbox"][disabled!="disabled"]').each(function (index, value) {
            var event_id = $(this).parents('li').attr('data-event-id');
            $(this).attr('checked', true);
            selected_events.push(event_id);
          });

        } else {

          $('ul.table div.content li input[type="checkbox"]').each(function (index, value) {
            var removeItem = $(this).parents('li').attr('data-event-id');
            $(this).attr('checked', false);
            selected_events = jQuery.grep(selected_events, function(value) {
              return value != removeItem;
            });
          });
        };

        $('input#selected_events[type="hidden"]').val(selected_events);

      });
			
    },
		
    recheck_selected_events: function(){
      $('input#selected_events').val(selected_events);
      $.each(selected_events, function(index, value) {
        $('input.check_box_' + value).attr('checked', 'checked');
      });
    },
		
    pagenation: function() {

      $('ul.pager li').live('click', function() {
        var self = this;

        var notes = $(this).parents('.pager').hasClass('notes-pager');

        if (history && history.pushState) {
          $(window).bind("popstate", function() {
            $.getScript(location.href);
          });
        };

        if (!$(self).hasClass('more')) {

          var current_width = $(self).width();
          if (current_width < 16) { var current_width = 16 };

          $(self).addClass('loading').css('width', current_width);

          if ($(self).parents('div').hasClass('notes-pager')) {
            $('div.notes').fadeTo(500, 0.4);
          } else {
            $('div.content, tbody.content').fadeTo(500, 0.4);
          };

          Snorby.helpers.remove_click_events(true);

          if ($('div#search-params').length > 0) {

            var search_data = JSON.parse($('div#search-params').text());

            if (search_data) {
              $.ajax({
                url: $(self).find('a').attr('href'),
                global: false,
                dataType: 'script',
                data: {
                  match_all: search_data.match_all,
                  search: search_data.search,
                  authenticity_token: csrf
                },
                cache: false,
                type: 'POST',
                success: function(data) {
                  $('div.content').fadeTo(500, 1);
                  Snorby.helpers.remove_click_events(false);
                  Snorby.helpers.recheck_selected_events();

                  if (!notes) {
                    if (history && history.pushState) {
                      history.pushState(null, document.title, $(self).find('a').attr('href'));
                    };
                    $.scrollTo('#header', 500);
                  };
                }
              });
            };

          } else {
            $.getScript($(self).find('a').attr('href'), function() {
              $('div.content').fadeTo(500, 1);
              Snorby.helpers.remove_click_events(false);
              Snorby.helpers.recheck_selected_events();

              if (!notes) {
                if (history && history.pushState) {
                  history.pushState(null, document.title, $(self).find('a').attr('href'));
                };
                $.scrollTo('#header', 500);
              };

            });
          };

        };

        return false;
      });

    },
		
    remove_click_events: function(hide){
      if (hide) {
        $('ul.table div.content div').removeClass('click');
      } else {
        $('li.event div.domain, li.event div.sensor, li.event div.src_ip, li.event div.dst_ip, li.event div.signature, li.event div.timestamp').addClass('click');
      };
    },
  },
	
  callbacks: function(){

    $('body').ajaxError(function (event, xhr, ajaxOptions, thrownError) {
			
      $('div.content').not(".protected").fadeTo(500, 1);
      $('ul.table div.content li input[type="checkbox"]').attr('checked', '');
      Snorby.helpers.remove_click_events(false);
			
      if (xhr['status'] === 404) {
        flash_message.push({
          type: 'error',
          message: "The requested page could not be found."
        });
        flash();
      } else {
        flash_message.push({
          type: 'error',
          message: "The request failed to complete successfully."
        });
        flash();
      };
			
    });
		
  },

  hotKeyCallback: {
      
    left: function() {
      $('div.pager.main ul.pager li.previous a').click();
    },

    right: function() {
      $('div.pager.main ul.pager li.next a').click();
    },

    shiftPlusRight: function() {
      $('div.pager.main ul.pager li.last a').click();
    },

    shiftPlusLeft: function() {
      $('div.pager.main ul.pager li.first a').click();
    },

    Sev1: function() {
      $('span.sev1').parents('div.row').find('input#event-selector').each(function() {
        var $checkbox = $(this);
        $checkbox.attr('checked', !$checkbox.attr('checked'));
        $checkbox.trigger('change');
      }); 
    },

    Sev2: function() {
      $('span.sev2').parents('div.row').find('input#event-selector').each(function() {
        var $checkbox = $(this);
        $checkbox.attr('checked', !$checkbox.attr('checked'));
        $checkbox.trigger('change');
      }); 
    },

    Sev3: function() {
      $('span.sev3').parents('div.row').find('input#event-selector').each(function() {
        var $checkbox = $(this);
        $checkbox.attr('checked', !$checkbox.attr('checked'));
        $checkbox.trigger('change');
      }); 
    }

  },

  hotkeys: function(){
    var self = this;

    $(document).bind('keydown', 'ctrl+shift+h', function() {
      $.fancybox({
        padding: 0,
        centerOnScroll: true,
        zoomSpeedIn: 300, 
        zoomSpeedOut: 300,
        overlayShow: true,
        overlayOpacity: 0.5,
        overlayColor: '#000',
        href: '/events/hotkey'
      });
      return false;
    });
		
    $(document).bind('keydown', 'ctrl+3', function() {
      window.location = '/jobs';
      return false;
    });
	
    $(document).bind('keydown', 'ctrl+2', function() {
      window.location = '/events';
      return false;
    });
		
    $(document).bind('keydown', 'ctrl+1', function() {
      window.location = '/events/queue';
      return false;
    });
	
    $(document).bind('keydown', 'ctrl+shift+s', function() {
      window.location = '/search';
      return false;
    });
	
    if ($('div.pager').is(':visible')) {
			
      $(document).bind('keydown', 'shift+down', function() {
        var item = $('ul.table div.content li.event.currently-over');
        
        if (item.is(':visible')) {
          if (item.next().length != 0) {
            item.removeClass('currently-over');
            item.next().addClass('currently-over');
          } else {
            $('ul.table div.content li.event:first').addClass('currently-over');
          };
        } else {
          $('ul.table div.content li.event:first').addClass('currently-over');
        };

      });

      $(document).bind('keydown', 'shift+up', function() {
        var item = $('ul.table div.content li.event.currently-over');
        if (item.is(':visible')) {
          if (item.prev().length != 0) {
            item.removeClass('currently-over');
            item.prev().addClass('currently-over');
          } else {
            $('ul.table div.content li.event:last').addClass('currently-over');
          };
        } else {
          $('ul.table div.content li.event:last').addClass('currently-over');
        };
      });
			
      $(document).bind('keydown', 'shift+return', function() {
        $('ul.table div.content li.event.currently-over div.row div.click').click();
      });
			
      $(document).bind('keydown', 'ctrl+shift+1', Snorby.hotKeyCallback.Sev1);
      $(document).bind('keydown', 'ctrl+shift+2', Snorby.hotKeyCallback.Sev2);
      $(document).bind('keydown', 'ctrl+shift+3', Snorby.hotKeyCallback.Sev3);
			
      $(document).bind('keydown', 'ctrl+shift+u', function() {
        set_classification(0);
      });

      $(document).bind('keydown', 'alt+right', function() {
        $('div.pager.notes-pager ul.pager li.next a').click();
      });

      $(document).bind('keydown', 'alt+left', function() {
        $('div.pager.notes-pager ul.pager li.previous a').click();
      });
			
      $(document).bind('keydown', 'ctrl+shift+a', function() {
        $('input.event-select-all').click().trigger('change');
      });
			
      Snorby.eventCloseHotkeys(true);

    };
		
  },
	
  validations: function(){
		
    jQuery.validator.addMethod("hex-color", function(value, element, param) {
      return this.optional(element) || /^#?([a-f]|[A-F]|[0-9]){3}(([a-f]|[A-F]|[0-9]){3})?$/i.test(value);
    }, jQuery.validator.messages.url);
		
    $('.validate').validate();
		
  },
	
  settings: function(){
		
    if ($('div#general-settings').length > 0) {
			
      if ($('input#_settings_packet_capture').is(':checked')) {
        $('div.pc-settings').show();
        $('p.pc-settings input[type="text"], p.pc-settings select').addClass('required');
      } else {
        $('div.pc-settings').hide();
        $('p.pc-settings input[type="text"], p.pc-settings select').removeClass('required');
      };

      if ($('input#_settings_packet_capture_auto_auth').is(':checked')) {
        $('input#_settings_packet_capture_user, input#_settings_packet_capture_password').attr('disabled', null);
      } else {
        $('input#_settings_packet_capture_user, input#_settings_packet_capture_password').attr('disabled', 'disabled');
        $('input#_settings_packet_capture_user, input#_settings_packet_capture_password').removeClass('required');
      };
			
      var packet_capture_plugin = $('select#_settings_packet_capture_type').attr('packet_capture_plugin');
      $('select#_settings_packet_capture_type option[value="'+packet_capture_plugin+'"]').attr('selected', 'selected');
			
      if ($('input#_settings_autodrop').is(':checked')) {
        $('select#_settings_autodrop_count').attr('disabled', null);
      } else {
        $('select#_settings_autodrop_count').attr('disabled', 'disabled');
      };

      if ($('input#_settings_autodrop_rollback').is(':checked')) {
        $('select#_settings_autodrop_rollback_count').attr('disabled', null);
      } else {
        $('select#_settings_autodrop_rollback_count').attr('disabled', 'disabled');
      };
			
      if ($('input#_settings_proxy').is(':checked')) {
        $('div.proxy-settings').show();
        $('p.proxy-settings input[type="text"].req').addClass('required');
      } else {
        $('div.proxy-settings').hide();
        $('p.proxy-settings input[type="text"].req').removeClass('required');
      };

      var autodrop_count = $('select#_settings_autodrop_count').attr('autodrop_count');
      $('select#_settings_autodrop_count option[value="'+autodrop_count+'"]').attr('selected', 'selected');

      var autodrop_rollback_count = $('select#_settings_autodrop_rollback_count').attr('autodrop_rollback_count');
      $('select#_settings_autodrop_rollback_count option[value="'+autodrop_rollback_count+'"]').attr('selected', 'selected');
    };

    $('input#_settings_packet_capture').live('click', function() {
      if ($('input#_settings_packet_capture').is(':checked')) {
        $('div.pc-settings').show();
        $('p.pc-settings input[type="text"], p.pc-settings select').addClass('required');
      } else {
        $('div.pc-settings').hide();
        $('p.pc-settings input[type="text"], p.pc-settings select').removeClass('required');
      };
    });

		$('input#_settings_proxy').live('click', function() {
      if ($('input#_settings_proxy').is(':checked')) {
        $('div.proxy-settings').show();
        $('p.proxy-settings input[type="text"].req').addClass('required');
      } else {
        $('div.proxy-settings').hide();
        $('p.proxy-settings input[type="text"].req').removeClass('required');
      };
    });

    $('input#_settings_autodrop').live('click', function() {
      if ($(this).is(':checked')) {
        $('select#_settings_autodrop_count').attr('disabled', null);
      } else {
        $('select#_settings_autodrop_count').attr('disabled', 'disabled');
      };
    });

    $('input#_settings_autodrop_rollback').live('click', function() {
      if ($(this).is(':checked')) {
        $('select#_settings_autodrop_rollback_count').attr('disabled', null);
      } else {
        $('select#_settings_autodrop_rollback_count').attr('disabled', 'disabled');
      };
    });

    $('input#_settings_packet_capture_auto_auth').live('click', function() {
      if ($('input#_settings_packet_capture_auto_auth').is(':checked')) {
        $('input#_settings_packet_capture_user, input#_settings_packet_capture_password').addClass('required');
        $('input#_settings_packet_capture_user, input#_settings_packet_capture_password').attr('disabled', null);
      } else {
        $('input#_settings_packet_capture_user, input#_settings_packet_capture_password').removeClass('required');
        $('input#_settings_packet_capture_user, input#_settings_packet_capture_password').attr('disabled', 'disabled');
      };
    });
		
  },
	
  jobs: function(){
		
    $('a.view_job_handler, a.view_job_last_error').live('click', function() {
      $.fancybox({
        padding: 0,
        centerOnScroll: true,
        zoomSpeedIn: 300, 
        zoomSpeedOut: 300,
        overlayShow: true,
        overlayOpacity: 0.5,
        overlayColor: '#000',
        href: this.href
      });
      return false;
    });
		
  }
	
};

jQuery(document).ready(function($) {

  Handlebars.registerHelper('geoip', function(ip) {
    if (ip) {
      var name = ip.country_name;
      var code = ip.country_code2;
      if (name === "--") {
        name = 'N/A'
      };

      return '<span class="click ' +
      'country_flag add_tipsy_html" title="&lt;img class=&quot;flag&quot; ' +
      'src=&quot;/images/flags/'+code.toLowerCase()+'.png&quot;&gt; ' + name + '">' + code + '</span>'; 
    } else {
      return null;
    };
  });

  Handlebars.registerHelper('truncate', function(data, length) {
     if (data.length > length) {
       return data.substring(0,length) + "...";
     } else {
      return data;
     };
  });

  Handlebars.registerHelper('percentage', function(total) {
    var calc = ((parseFloat(this.events_count) / parseFloat(total)) * 100);
    return calc.toFixed(2);
  });

  $('#login form#user_new').submit(function(event) {
    event.preventDefault();
    var self = $('#login');
    var that = this;
    login = $('input#user_login').length>0 ? $('input#user_login') : $('input#user_email') 
    
    if ($('input#user_password', that).attr('value').length > 1) {
      if (login.attr('value').length > 0) {
        
        $('#content').append('<div class="auth-loading">Submitting credentials, Please wait...</div>');
        $('#content #title, #content #signin').animate({
          opacity: 0.2
        }, 500);
        
        $.post(that.action, $(that).serialize(), function(data) {
          if (data.success) {

            $('div.auth-loading').animate({
              opacity: 0
            }, 500, function() {
              $('div.auth-loading').html('Authentication Successful, Please wait...');
              $('div.auth-loading').animate({
                opacity: 1
              }, 500);
            });
            
            $.get(data.redirect, function(data) {
              self.fadeOut('slow', function() {
                document.open();
                document.write(data);
                document.close();
                history.pushState(null, 'onGuard IDS - Dashboard', '/');
              });
            });
          } else {
            flash_message.push({
              type: 'error',
              message: "Error - Authentication Failed!"
            });
            flash();
            $('div.auth-loading').remove();
            $('#content #title, #content #signin').animate({
              opacity: 1
            }, 1000);
          };
        });

      };
    };
  });

  $('#login button.forgot-my-password').live('click', function(event) {
    event.preventDefault();
    $.get('/users/password/new', function(data) {
      var content = $(data).find('#content').html();
      $('#content').html(content);
      history.pushState(null, 'Snorby - Password Reset', '/users/password/new');
    });
  });

  $('#fancybox-wrap').draggable({
    handle: 'div#box-title',
    cursor: 'move'
  });

  $('li.administration a').live('click', function(event) {
    var self = this;
    event.preventDefault();
    $('dl#admin-menu').toggle();
  });

  $('dl#admin-menu a').live('click', function(event) {
    $(this).parents('dl').fadeOut('fast');
  });

  

  Snorby.setup();
  Snorby.admin();
  Snorby.callbacks();
  Snorby.hotkeys();
  Snorby.jobs();
  Snorby.settings();
  Snorby.validations();
	
  Snorby.helpers.tipsy();
  Snorby.helpers.dropdown();
  Snorby.helpers.input_style();
  Snorby.helpers.persistence_selections();
  Snorby.helpers.pagenation();
	
  Snorby.pages.classifications();
  Snorby.pages.dashboard();
  Snorby.pages.events();
  Snorby.pages.rules();
  Snorby.pages.dashboard_sensor();

  $('.add_chosen').chosen();

  $('ul.table div.content li').live('hover', function() {
    $('ul.table div.content li').removeClass('currently-over');
    $(this).toggleClass('currently-over');
  }, function() {
    $(this).toggleClass('currently-over');
  });
  
  var signature_input_search = null;
  var signature_input_search_last = null;
  var signature_input_search_timeout = null;

  $('input#signature-search').live('keyup', function() {
    var value = $(this).val().replace(/^\s+|\s+$/g, '');

    if (value.length >= 3) {

      if (value !== signature_input_search_last) {
        if (signature_input_search) { signature_input_search.abort() };

        signature_input_search_last = value;

        if ($('div.search-loading').length == 0) {
          $('div#title').append(Snorby.templates.searchLoading());
        };
        
        signature_input_search = $.ajax({
          url: '/signatures/search',
          global: false,
          data: { q: value, authenticity_token: csrf },
          type: "POST",
          dataType: "json",
          cache: false,
          success: function(data) {
            signature_input_search = null;
            signature_input_search_last = value;

            $('div#signatures').hide();
            $('div.search-loading').remove();

            if ($('div#signatures-input-search').length == 0) {
              $('div#content').append(Snorby.templates.signatureTable());
            };

            $("div#signatures-input-search tbody.signatures").html(Snorby.templates.signatures(data));
          }
        });
      };

    } else {
      $('div#signatures').show(); 
      $("div#signatures-input-search").remove();
      $('div.search-loading').remove();
      signature_input_search_last = null;
      if (signature_input_search) { signature_input_search.abort() };
    };
  });

  var sensor_input_search = null;
  var sensor_input_search_last = null;
  var sensor_input_search_timeout = null;

  $('input#sensor-search').live('keyup', function() {
    var value = $(this).val().replace(/^\s+|\s+$/g, '');

    if (value.length >= 3) {

      if (value !== sensor_input_search_last) {
        if (sensor_input_search) { sensor_input_search.abort() };

        sensor_input_search_last = value;

        if ($('div.search-loading').length == 0) {
          $('div#title').append(Snorby.templates.searchLoading());
        };
        
        sensor_input_search = $.ajax({
          url: '/sensors/search',
          global: false,
          data: { q: value, authenticity_token: csrf },
          type: "POST",
          dataType: "json",
          cache: false,
          success: function(data) {
            sensor_input_search = null;
            sensor_input_search_last = value;

            $('div#sensors').hide();
            $('div.search-loading').remove();

            if ($('div#sensors-input-search').length == 0) {
              $('div#content').append(Snorby.templates.sensorTable());
            };

            $("div#sensors-input-search tbody.sensors").html(Snorby.templates.sensors(data));
          }
        });
      };

    } else {
      $('div#sensors').show(); 
      $("div#sensors-input-search").remove();
      $('div.search-loading').remove();
      sensor_input_search_last = null;
      if (sensor_input_search) { sensor_input_search.abort() };
    };
  });

  var ip_input_search = null;
  var ip_input_search_last = null;
  var ip_input_search_timeout = null;

  $('input#ip-search').live('keyup', function() {
    var value = $(this).val().replace(/^\s+|\s+$/g, '');
    var type = $(this).attr("data_type");

    if (value.length >= 3) {

      if (value !== ip_input_search_last) {
        if (ip_input_search) { ip_input_search.abort() };

        ip_input_search_last = value;

        if ($('div.search-loading').length == 0) {
          $('div#title').append(Snorby.templates.searchLoading());
        };
        
        ip_input_search = $.ajax({
          url: '/events/ip_search',
          global: false,
          data: { q: value, type: type, authenticity_token: csrf },
          type: "GET",
          dataType: "script",
          cache: false
        });
      };

    } else {
      $('div#ips').show(); 
      $("div#ips-input-search").remove();
      $('div.search-loading').remove();
      ip_input_search_last = null;
      if (ip_input_search) { ip_input_search.abort() };
    };
  });

  var cache_reload_count = 0;
  function currently_caching() {
    $.ajax({
      url: '/cache/status',
      global: false,
      dataType: 'json',
      cache: false,
      type: 'GET',
      success: function(data) {
        if (data.caching) {
          setTimeout(function() {
            cache_reload_count = 0;
            currently_caching();
          }, 2000);
        } else {
          if (cache_reload_count == 3) {
            cache_reload_count = 0;
            location.reload();
          } else {
            cache_reload_count++;
            currently_caching();
          };
        };
      }
    });
  };

  $('dd a.force-cache-update').live('click', function(e) {
    e.preventDefault();
    $('li.last-cache-time').html("<i>Currently Caching <img src='../images/icons/pager.gif' width='16' height='11' /></i>");
    $.getJSON(this.href, function(data) {
      setTimeout(currently_caching, 6000);
    });
  });

  $('input#rule-select-all').live('change', function() {
    if ($(this).attr('checked')) {
      $('ul.table div.content li.category input[type="checkbox"]').attr('checked', true);
    } else {
      $('ul.table div.content li.category input[type="checkbox"]').attr('checked', false);
    }
    return true;
  });

  $('input#category-selector').live('change', function() {
    if (!$(this).attr('checked')) {
      $('input#rule-select-all').attr('checked', false);
      $(this).parents("li.category").find('input[type="checkbox"]').attr('checked', false);
    }
    else{
      $(this).parents("li.category").find('input[type="checkbox"]').attr('checked', "checked");
    }
    return true;
  });

  $('input#group-selector').live('change', function() {
    if (!$(this).attr('checked')) {
      $(this).parents("li.group").find('input[type="checkbox"]').attr('checked', false);
      $(this).parents('li.category').children('div.row').children('div.select').children('input').attr('checked', false);
      $('input#rule-select-all').attr('checked', false);
    }
    else{
      $(this).parents("li.group").find('input[type="checkbox"]').attr('checked', "checked");
    }
    return true;
  });

  $('input#family-selector').live('change', function() {
    if (!$(this).attr('checked')) {
      $(this).parents("li.family").find('input[type="checkbox"]').attr('checked', false);
      $(this).parents('li.group').children('div.row').children('div.select').children('input').attr('checked', false);
      $(this).parents('li.category').children('div.row').children('div.select').children('input').attr('checked', false);
      $('input#rule-select-all').attr('checked', false);
    }
    else{
      $(this).parents("li.family").find('input[type="checkbox"]').attr('checked', "checked");
    }
    return true;
  });

  $('input#rule-selector').live('change', function() {
    if (!$(this).attr('checked')) {
      $(this).parents('li.family').children('div.row').children('div.select').children('input').attr('checked', false);
      $(this).parents('li.group').children('div.row').children('div.select').children('input').attr('checked', false);
      $(this).parents('li.category').children('div.row').children('div.select').children('input').attr('checked', false);
      $('input#rule-select-all').attr('checked', false);
    }
    return true;
  });

  $('button.add_new_rule_note').live('click', function(e) {
    e.preventDefault();
    var rule_id = $(this).parents('.rule').attr('data');

    if ($('div#new_note_box').length > 0) {

    } else {
        $(this).removeClass('add_new_note').addClass('add_new_note-working');

        var current_width = $(this).width();
        $(this).addClass('loading').css('width', current_width);

        $.get('/rule_notes/new', {
            rule_id: rule_id,
            authenticity_token: csrf
        }, null, 'script');
    };

    return false;
  });

  $('button.submit_new_rule_note').live('click', function(e) {
    e.preventDefault();
    var rule_id = $(this).parents('.rule').attr('data');
    var note_body = $(this).parent('div#form-actions').parent('div#new_note').find('textarea#body').val();

    if (note_body.length > 0) {

      var current_width = $(this).width();
      $(this).addClass('loading').css('width', current_width);

      $.post('/rule_notes/create', {
        rule_id: rule_id,
        body: note_body,
        authenticity_token: csrf
      }, null, 'script');

    } else {
      flash_message.push({
        type: "error",
        message: "The note body cannot be blank!"
      });
      flash();
      $.scrollTo('#header', 500);
    };
    $('ul.table div.content li').removeClass('currently-over');    
    return false;
  });

  $('.content > li.rule > div.row > .message').live('click', function(event) {
    var self = this

    if(!$(this).hasClass('click')){
      return false;
    }

    var sensor_id   = $("#rules").attr("data-sensor-sid");
    var rule_id     = $(self).parents(".rule").attr("data");
    var content     = $(self).parent().next()

    if (sensor_id>=0 && rule_id>0) {
      if (!$(self).hasClass("loaded")) {
        $(self).addClass("loaded");
        $(self).parents("li.rule").toggleClass("highlight");
        var select_comp = $(self).parents(".row").children(".select");
        var select_html = select_comp.html();
        select_comp.html('<img src="/images/icons/loading.gif">');

        $.ajax({
          url: "/sensors/" +sensor_id +"/update_rule_details",
          data: {sensor_id: sensor_id, rule_id: rule_id},
          success: function(data){
            content.toggle('fast');
            select_comp.html(select_html);
          }
        });
      } else {
        $(self).parents("li.rule").toggleClass("highlight");
        content.toggle('fast')
      }
    }
  });

  $(".table.categories .sec-title").live('click', function() {
    $(this).parent().children(".table").toggle('fast');
  });

  $(".table.reputations .sec-title").live('click', function() {
    $(this).parent().children(".table").toggle('fast');
  });

  $(".table.conf-settings .sec-title").live('click', function() {
    $(this).parent().children(".table").toggle('fast');
  });

  $(".table.last-10-events-info .sec-title").live('click', function() {
    $(this).parent().children(".table").toggle('fast');
  });

  $(".table.last-5-traps-info .sec-title").live('click', function() {
    $(this).parent().children(".table").toggle('fast');
  });

  $('#dashboard #dashboard-sensor-other-content input[type="checkbox"][name="bypass"]').live('click', function() {
    
    if (confirm('Are you sure?')){
      var sensor_id = $("#dashboard").attr("data");
      var segment   = $(this).attr("class");
      
      if ($(this).is(':checked')){
        $.ajax({
          type: "POST",
          url: "/sensors/" +sensor_id +"/bypass",
          data: {sensor_id: sensor_id, segment: segment, mode: 'on'}
        });
      }else{
        $.ajax({
          type: "POST",
          url: "/sensors/" +sensor_id +"/bypass",
          data: {sensor_id: sensor_id, segment: segment, mode: 'off'}
        });
      }
      $('div.box-holder').fadeTo(500, 0.4);
      $(this).hide();
      $(this).parent().append('<img class="'+segment+'" src="/images/icons/pager.gif">');
    } else {
      return false;
    }
  });

  $('.discard-rules-button').live('click', function() {
    if (confirm('Are you sure to discard the pending rules?')) {
      blockWebUI(); 
      window.location = $(this).attr('href')
    }
  });

  $('.reset-rules-button').live('click', function() {
    if (confirm('All defined rules will be deleted conserving only inherited rules. Are you sure you want to continue?')) {
      blockWebUI(); 
      window.location = $(this).attr('href')
    }
  });

  $(".block-ui-but").live('click', function(e) {
    blockWebUI();
  });

  $(".click-loading").live('click', function(e) {
    $(this).html('<img src="/images/icons/pager.gif"/>');   
  });  

  $("#versions #sources tr td").live({
    mouseenter: function (over) {
      $(this).find(".icons").animate({"opacity": 1});
    },
    mouseleave: function (out) {
      $(this).find(".icons").animate({"opacity": 0});
    }
  });

  $('a.notallowed').live('click', function() {
    flash_message.push({
      type: 'error',
      message: "This action is not allowed"
    });
    flash();
    $.scrollTo('#header', 500);
  });  

  $('body').on('click', 'button.new-saved-search-record', function(e) {
    e.preventDefault();

    var model = $(this).attr('data_model');

    if(model == 'event'){
      var url = '/saved_event_filters/create';
      var title = $('input#saved_event_filter_title').val();
      var search_public = $('input#saved_event_filter_public').is(":checked");
    } else {
      // get sensor and make the url with that
      var url = '/saved_rule_filters/create';
      var title = $('input#saved_rule_filter_title').val();
      var search_public = $('input#saved_rule_filter_public').is(":checked");
    }

    if ($('#snorby-box #saved_filter_title').val()=="") {
      $('#snorby-box #saved_filter_title').css('border' ,  "2px solid #FD2E3F !important;")
    } else {
      var dd = false;

      if (typeof rule !== "undefined") {
        dd = rule.pack();
      } else {
        var json = $('div#search-params').text();

        if (json) {
          try {
            var tmp = JSON.parse(json)
            dd = {
              filter: tmp.search
            };
          } catch(e) {
            dd = false;
          }
        };
      };

      if (dd) {
        $('#snorby-box #form-actions button.success').attr('disabled', true);
        $('#snorby-box #form-actions button.success span').text('Please wait...');

        $.ajax({
          url: url,
          global: false,
          dataType: 'json',
          cache: false,
          type: 'POST',
          data: {
            "authenticity_token": csrf,
            "filter": {
              "title": title,
              "public": search_public,
              "filter": dd
            }
          },
          success: function(data) {
            if (data.error) {
              flash_message.push({type: 'error', message: "ERROR: This search may already exists."});flash();
            } else {
              flash_message.push({type: 'success', message: "Your search was saved successfully"});flash();
            };
            $('a#fancybox-close').click();
          },
          error: function(data) {
           flash_message.push({type: 'error', message: "Error: This search may already exists."});flash();
           $(document).trigger('limp.close');
          }
       });

      } else {
        flash_message.push({type: 'error', message: "An Unknown Error Has Occurred"});flash();
        $(document).trigger('limp.close');
      };
  $('#is-asset-name-global').live('change', function(e) {
    var value = $(this).is(':checked');
    if (value) {
      $('#edit-asset-name-agent-select').attr('disabled', true);
      $('.add_chosen').trigger("liszt:updated");
    } else {
      $('#edit-asset-name-agent-select').attr('disabled', false);
      $('.add_chosen').trigger("liszt:updated");
    };
  });

  $('.edit-asset-name').live('click', function(e) {
    e.preventDefault();
    var self = $(this);

    if (Snorby.getSensorList) {
      Snorby.getSensorList.abort();
    };

    $('.loading-bar').slideDown('fast');

    Snorby.getSensorList = $.ajax({
      url: "/sensors/agent_list.json",
      type: "GET",
      dataType: "json",
      success: function(data) {

        $('.loading-bar').slideUp('fast');

        var params = {
          ip_address: self.attr('data-ip_address'),
          agent_id: self.attr('data-agent_id'),
          asset_name: self.attr('data-asset_name'),
          asset_id: self.attr('data-asset_id'),
          global: (self.attr('data-asset_global') === "true" ? true : false),
          agents: data
        };

        params.agent_ids = [];
        if (self.attr('data-asset_agent_ids')) {
          var ids = self.attr('data-asset_agent_ids').split(',');
           for (var i = 0; i < ids.length; i += 1) {
             params.agent_ids.push(parseInt(ids[i]));
           }
        }
        var box = Snorby.box('edit-asset-name', params);
        box.open();
      },
      error: function(a,b,c) {
        $('.loading-bar').slideUp('fast');
        flash_message.push({
          type: 'error',
          message: "Unable to edit asset name for address."
        });
        flash();
      }
    });

  });

  $('a.destroy-asset-name').live('click', function(e) {
    e.preventDefault();
    var id = $(this).attr('data-asset_id');

    var box = Snorby.box('confirm', {
      title: "Remove Asset Name",
      message: "Are you sure you want to remove this asset name? This action cannot be undone.",
      button: {
        title: "Yes",
        type: "default success"
      },
      icon: "warning"
    }, {
      onAction: function() {
        $('.loading-bar').slideDown('fast');
        $('.limp-action').attr('disabled', true).find('span').text('Loading...');
        $.ajax({
          url: '/asset_names/' + id + '/remove',
          type: 'delete',
          data: {
            csrf: csrf
          },
          dataType: "json",
          success: function(data) {
            $('.loading-bar').slideUp('fast');
            $.limpClose();
            $('tr[data-asset-id="'+id+'"]').remove();
          },
          error: function(a,b,c) {
            $('.loading-bar').slideUp('fast');
            $.limpClose();
          }
        });
      }
    });

    box.open();
  });

    }
    return false;
  });
  
});

