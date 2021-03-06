(function(){var a=Handlebars.template,b=Handlebars.templates=Handlebars.templates||{};b.confirm=a(function(a,b,c,d,e){function p(a,b){return"\n      "}function q(a,b){return"\n      <button class='warning cancel-snorbybox default' onClick='$.limpClose()'><span>Cancel</span></button>\n      "}c=c||a.helpers;var f="",g,h,i,j,k=this,l="function",m=c.helperMissing,n=void 0,o=this.escapeExpression;f+='<div class="snorby-box" id="snorby-box">\n\n  <div id="box-title">\n    ',i=c.title,g=i||b.title,typeof g===l?g=g.call(b,{hash:{}}):g===n&&(g=m.call(b,"title",{hash:{}})),f+=o(g)+'\n    <div class="more">\n    </div>\n  </div>\n  <div id="box-content-small">\n\n    <div id="snorbybox-content" class="">\n      <div class=\'snorbybox-content-message\'>\n      ',i=c.message,g=i||b.message,typeof g===l?g=g.call(b,{hash:{}}):g===n&&(g=m.call(b,"message",{hash:{}}));if(g||g===0)f+=g;f+='\n      </div>\n    </div>\n\n    <div id="box-footer">\n      <div id="form-actions">\n\n      <button class=\'button ',i=c.button,g=i||b.button,g=g===null||g===undefined||g===!1?g:g.type,typeof g===l?g=g.call(b,{hash:{}}):g===n&&(g=m.call(b,"button.type",{hash:{}})),f+=o(g)+" limp-action'><span>",i=c.button,g=i||b.button,g=g===null||g===undefined||g===!1?g:g.title,typeof g===l?g=g.call(b,{hash:{}}):g===n&&(g=m.call(b,"button.title",{hash:{}})),f+=o(g)+"</span></button>\n\n      ",i=c.ignore_cancel,g=i||b.ignore_cancel,h=c["if"],j=k.program(1,p,e),j.hash={},j.fn=j,j.inverse=k.program(3,q,e),g=h.call(b,g,j);if(g||g===0)f+=g;return f+="\n      </div>\n\n    </div>\n\n  </div>\n</div>\n",f}),b["edit-asset-name"]=a(function(a,b,c,d,e){function p(a,b){var d="",e;return d+='value="',i=c.asset_name,e=i||a.asset_name,typeof e===l?e=e.call(a,{hash:{}}):e===n&&(e=m.call(a,"asset_name",{hash:{}})),d+=o(e)+'"',d}function q(a,b){return"checked"}function r(a,b){return"disabled"}c=c||a.helpers;var f="",g,h,i,j,k=this,l="function",m=c.helperMissing,n=void 0,o=this.escapeExpression;f+='<div class="snorby-box" id="snorby-box">\n\n  <div id="box-title">\n    Edit Asset Name For ',i=c.ip_address,g=i||b.ip_address,typeof g===l?g=g.call(b,{hash:{}}):g===n&&(g=m.call(b,"ip_address",{hash:{}})),f+=o(g)+'\n    <div class="more"></div>\n  </div>\n  <div id="box-content-small">\n\n    <div id="snorbybox-content" class="">\n        <form class="update-asset-name-form" action="#">\n          <div class="grid_5">\n            \n            <input type="hidden" name="ip_address" value="',i=c.ip_address,g=i||b.ip_address,typeof g===l?g=g.call(b,{hash:{}}):g===n&&(g=m.call(b,"ip_address",{hash:{}})),f+=o(g)+'" />\n            <input type="hidden" name="id" value="',i=c.asset_id,g=i||b.asset_id,typeof g===l?g=g.call(b,{hash:{}}):g===n&&(g=m.call(b,"asset_id",{hash:{}})),f+=o(g)+'" />\n\n            <p>\n              <input id="edit-asset-name-title" ',i=c.asset_name,g=i||b.asset_name,h=c["if"],j=k.program(1,p,e),j.hash={},j.fn=j,j.inverse=k.noop,g=h.call(b,g,j);if(g||g===0)f+=g;f+=' name="name" type="text" style=\'width:339px;\' placeholder="Enter Asset Name" />\n            </p>\n\n            <div class="clear"></div>\n\n            <p>\n              <input type="checkbox" id=\'is-asset-name-global\' name="global" ',i=c.global,g=i||b.global,h=c["if"],j=k.program(3,q,e),j.hash={},j.fn=j,j.inverse=k.noop,g=h.call(b,g,j);if(g||g===0)f+=g;f+=" />\n              <label>Enable Globally</label> <em>(Enable this rule for all sensors)</em><br />\n            </p>\n\n            <div class=\"clear\"></div>\n\n            <div id='snorbybox-form-full'>\n              <select ",i=c.global,g=i||b.global,h=c["if"],j=k.program(5,r,e),j.hash={},j.fn=j,j.inverse=k.noop,g=h.call(b,g,j);if(g||g===0)f+=g;f+=' style="width:350px;margin-bottom:5px;" name="agents" id="edit-asset-name-agent-select" class=\'add_chosen\' "data-placeholder"="Select individual agents" multiple name="">\n                ',i=c.build_asset_name_agent_list,g=i||b.build_asset_name_agent_list,typeof g===l?g=g.call(b,{hash:{}}):g===n&&(g=m.call(b,"build_asset_name_agent_list",{hash:{}}));if(g||g===0)f+=g;return f+='\n              </select>\n              <br />\n            </div>\n          \n          </div>\n\n          <div class="grid_5" style=\'width:287px;\'>\n            <div class="note no-click">\n              <div class="message">\n                <strong>Global</strong> This asset name will be used for all sensors that match this address.<br />\n              </div>\n            </div>\n          </div>\n\n          <div class="clear"></div>\n\n          <br />\n\n          <div id="box-footer">\n            <div id="form-actions">\n              <button class=\'update-asset-name-submit-button button success default\' onclick="Snorby.submitAssetName(); return false;">\n                <span>Update</span>\n              </button>\n              <button class=\'warning cancel-snorbybox default\' onClick=\'$.limpClose()\'><span>Cancel</span></button>\n            </div>\n          </div>\n\n        </form>\n    </div>\n\n\n  </div>\n</div>\n',f}),b["search-rule"]=a(function(a,b,c,d,e){c=c||a.helpers;var f,g=this;return'<div class="search-content-box">\n  <div class="inside">\n\n    <div class="search-content-enable search-content-box-item">\n      <input name="enable-current-search-content" checked=\'checked\' type="checkbox" />\n    </div>\n\n    <div class="column-select search-content-box-item">\n      <select class=\'add_chosen\'>\n        <option value=\'any\'>Any</option>\n        <option value=\'all\'>All</option>\n      </select> \n    </div>\n\n    <div class="operator-select search-content-box-item">\n      <select class=\'add_chosen\'>\n        <option value=\'is\'>is</option>\n        <option value=\'is_not\'>is not</option>\n      </select>      \n    </div>\n\n    <div class="value search-content-box-item">\n      <input class=\'search-content-value\' placeholder="Enter search value" name="" type="text" /> \n    </div>\n\n    <div class="search-button-box-holder">\n      <div class="search-button-box-inside">\n        <div class="search-button-box">\n\n          <div title=\'Remove search rule\' class="search-content-remove search-content-box-item">\n            <img src="' + baseuri + '/images/icons/minus.png" alt="" />\n          </div>\n\n          <div title=\'Add new search rule\' class="search-content-add search-content-box-item">\n            <img src="' + baseuri + '/images/icons/add.png" alt="" />\n          </div>\n\n        </div>\n      </div>\n    </div>\n\n  </div>\n</div>\n'}),b.search=a(function(a,b,c,d,e){c=c||a.helpers;var f="",g,h,i=this,j="function",k=c.helperMissing,l=void 0,m=this.escapeExpression;return f+='<div id="search" class="boxit page grid_12">\n\n  <div class="search-match-box" style="display:;">\n    Match \n    <select class="global-match-setting">\n      <option value="any">Any</option>\n      <option value="all" selected="selected">All</option>\n    </select> \n    of the following rules: \n  </div>\n\n  <div class="other-search-options" style="display:none;">\n    <input name="limit-all-search-rules" type="checkbox"> \n    Limit to\n    <input class="limit-search-results-count" name="limit-search-results-to" type="text" value="10000"> \n    ordered by\n    <select><option value="any">Event Timestamp</option><option value="all">All</option></select>\n    <br>\n    <input name="ignore-classified-events" type="checkbox"> Ignore all classified events.\n  </div>\n\n  <div class="rules"></div>\n\n  <div id="form-actions">\n    <button class="',h=c.cssClass,g=h||b.cssClass,typeof g===j?g=g.call(b,{hash:{}}):g===l&&(g=k.call(b,"cssClass",{hash:{}})),f+=m(g)+' success default"><span>',h=c.buttonTitle,g=h||b.buttonTitle,typeof g===j?g=g.call(b,{hash:{}}):g===l&&(g=k.call(b,"buttonTitle",{hash:{}})),f+=m(g)+"</span></button>\n  </div>\n</div>\n",f}),b.select=a(function(a,b,c,d,e){function q(a,b){return"multiple"}function r(a,b){var d="",e;return d+='style="width:',i=c.width,e=i||a.width,typeof e===l?e=e.call(a,{hash:{}}):e===n&&(e=m.call(a,"width",{hash:{}})),d+=o(e)+';"',d}function s(a,b){var d="",e;return d+='data-placeholder="',i=c.placeholder,e=i||a.placeholder,typeof e===l?e=e.call(a,{hash:{}}):e===n&&(e=m.call(a,"placeholder",{hash:{}})),d+=o(e)+'"',d}function t(a,b){return'<option value=""></option>'}function u(a,b){var d="",e;return d+='\n    <option value="',i=c.id,e=i||a.id,typeof e===l?e=e.call(a,{hash:{}}):e===n&&(e=m.call(a,"id",{hash:{}})),d+=o(e)+'">',i=c.value,e=i||a.value,typeof e===l?e=e.call(a,{hash:{}}):e===n&&(e=m.call(a,"value",{hash:{}})),d+=o(e)+"</option>\n  ",d}c=c||a.helpers;var f="",g,h,i,j,k=this,l="function",m=c.helperMissing,n=void 0,o=this.escapeExpression,p=c.blockHelperMissing;f+="<select ",i=c.multiple,g=i||b.multiple,h=c["if"],j=k.program(1,q,e),j.hash={},j.fn=j,j.inverse=k.noop,g=h.call(b,g,j);if(g||g===0)f+=g;f+=" ",i=c.width,g=i||b.width,h=c["if"],j=k.program(3,r,e),j.hash={},j.fn=j,j.inverse=k.noop,g=h.call(b,g,j);if(g||g===0)f+=g;f+=' \n  class="add_chosen" \n  ',i=c.placeholder,g=i||b.placeholder,h=c["if"],j=k.program(5,s,e),j.hash={},j.fn=j,j.inverse=k.noop,g=h.call(b,g,j);if(g||g===0)f+=g;f+='\n  name="',i=c.name,g=i||b.name,typeof g===l?g=g.call(b,{hash:{}}):g===n&&(g=m.call(b,"name",{hash:{}})),f+=o(g)+'">\n\n  ',i=c.placeholder,g=i||b.placeholder,h=c["if"],j=k.program(7,t,e),j.hash={},j.fn=j,j.inverse=k.noop,g=h.call(b,g,j);if(g||g===0)f+=g;f+="\n\n  ",i=c.data,g=i||b.data,g=g===null||g===undefined||g===!1?g:g.value,j=k.program(9,u,e),j.hash={},j.fn=j,j.inverse=k.noop,i&&typeof g===l?g=g.call(b,j):g=p.call(b,g,j);if(g||g===0)f+=g;return f+="\n</select>\n\n\n",f}),b["session-event-row"]=a(function(a,b,c,d,e){c=c||a.helpers;var f="",g,h,i,j=this,k="function",l=c.helperMissing,m=void 0,n=this.escapeExpression;f+="<li id='event_",i=c.sid,g=i||b.sid,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"sid",{hash:{}})),f+=n(g),i=c.cid,g=i||b.cid,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"cid",{hash:{}})),f+=n(g)+"' data-session-id=\"",i=c.ip_src,g=i||b.ip_src,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"ip_src",{hash:{}})),f+=n(g)+"_",i=c.ip_dst,g=i||b.ip_dst,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"ip_dst",{hash:{}})),f+=n(g)+"_",i=c.sig_id,g=i||b.sig_id,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"sig_id",{hash:{}})),f+=n(g)+"\" class='event' style='' data-event-id='",i=c.sid,g=i||b.sid,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"sid",{hash:{}})),f+=n(g)+"-",i=c.cid,g=i||b.cid,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"cid",{hash:{}})),f+=n(g)+"' data-event-sid='",i=c.sid,g=i||b.sid,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"sid",{hash:{}})),f+=n(g)+"' data-event-cid='",i=c.cid,g=i||b.cid,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"cid",{hash:{}})),f+=n(g)+"'>\n  <div class='row geoip sessions'>\n    <div class='select small'><input class='event-selector' id='event-selector' name='event-selector' type='checkbox'></div>\n    <div class='important small'><div class='create-favorite enabled'></div></div>\n    <div class='severity small'><span class='severity sev",i=c.severity,g=i||b.severity,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"severity",{hash:{}})),f+=n(g)+"'>",i=c.severity,g=i||b.severity,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"severity",{hash:{}})),f+=n(g)+"</span></div>\n    <div class='click sensor'>",i=c.hostname,g=i||b.hostname,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"hostname",{hash:{}})),f+=n(g)+"</div>\n    <div class='click src_ip address'>\n      ",i=c.src_geoip,g=i||b.src_geoip,i=c.geoip,h=i||b.geoip,typeof h===k?g=h.call(b,g,{hash:{}}):h===m?g=l.call(b,"geoip",g,{hash:{}}):g=h;if(g||g===0)f+=g;f+=" ",i=c.ip_src,g=i||b.ip_src,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"ip_src",{hash:{}})),f+=n(g)+"\n    </div>\n    <div class='click dst_ip address'>\n      ",i=c.dst_geoip,g=i||b.dst_geoip,i=c.geoip,h=i||b.geoip,typeof h===k?g=h.call(b,g,{hash:{}}):h===m?g=l.call(b,"geoip",g,{hash:{}}):g=h;if(g||g===0)f+=g;return f+=" ",i=c.ip_dst,g=i||b.ip_dst,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"ip_dst",{hash:{}})),f+=n(g)+"\n    </div>\n    <div class='click signature'>",i=c.message,g=i||b.message,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"message",{hash:{}})),f+=n(g)+"</div>\n    <div class='click timestamp'>\n      <b class='add_tipsy' title='Event ID: ",i=c.sid,g=i||b.sid,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"sid",{hash:{}})),f+=n(g)+".",i=c.cid,g=i||b.cid,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"cid",{hash:{}})),f+=n(g)+" &nbsp; ",i=c.datetime,g=i||b.datetime,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"datetime",{hash:{}})),f+=n(g)+"'>\n        ",i=c.timestamp,g=i||b.timestamp,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"timestamp",{hash:{}})),f+=n(g)+'\n      </b>\n    </div>\n    <div class="click session-count" data-sessions="',i=c.session_count,g=i||b.session_count,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"session_count",{hash:{}})),f+=n(g)+'">\n      <span>',i=c.session_count,g=i||b.session_count,typeof g===k?g=g.call(b,{hash:{}}):g===m&&(g=l.call(b,"session_count",{hash:{}})),f+=n(g)+"</span>\n    </div>\n  </div>\n  <div style='display:none;' class='event-data' data='false'></div>\n</li>\n",f})})();
(function() {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['search-rule'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var foundHelper, self=this;

  return "<div class=\"search-content-box\">\n  <div class=\"inside\">\n\n    <div class=\"search-content-enable search-content-box-item\">\n      <input name=\"enable-current-search-content\" checked='checked' type=\"checkbox\" />\n    </div>\n\n    <div class=\"column-select search-content-box-item\">\n      <select class='add_chosen'>\n        <option value='any'>Any</option>\n        <option value='all'>All</option>\n      </select> \n    </div>\n\n    <div class=\"operator-select search-content-box-item\">\n      <select class='add_chosen'>\n        <option value='is'>is</option>\n        <option value='is_not'>is not</option>\n      </select>      \n    </div>\n\n    <div class=\"value search-content-box-item\">\n      <input class='search-content-value' placeholder=\"Enter search value\" name=\"\" type=\"text\" /> \n    </div>\n\n    <div class=\"search-button-box-holder\">\n      <div class=\"search-button-box-inside\">\n        <div class=\"search-button-box\">\n\n          <div title='Remove search rule' class=\"search-content-remove search-content-box-item\">\n            <img src=\"/images/icons/minus.png\" alt=\"\" />\n          </div>\n\n          <div title='Add new search rule' class=\"search-content-add search-content-box-item\">\n            <img src=\"/images/icons/add.png\" alt=\"\" />\n          </div>\n\n        </div>\n      </div>\n    </div>\n\n  </div>\n</div>\n";});
templates['search'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, foundHelper, self=this, functionType="function", helperMissing=helpers.helperMissing, undef=void 0, escapeExpression=this.escapeExpression;


  buffer += "<div id=\"search\" class=\"boxit page grid_12\">\n\n <div class=\"other-search-options\" style=\"display:none;\">\n    <input name=\"limit-all-search-rules\" type=\"checkbox\"> \n    Limit to\n    <input class=\"limit-search-results-count\" name=\"limit-search-results-to\" type=\"text\" value=\"10000\"> \n    ordered by\n    <select><option value=\"any\">Event Timestamp</option><option value=\"all\">All</option></select>\n    <br>\n    <input name=\"ignore-classified-events\" type=\"checkbox\"> Ignore all classified events.\n  </div>\n\n  <div class=\"rules\"></div>\n\n  <div id=\"form-actions\">\n    <button class=\"";
  foundHelper = helpers.cssClass;
  stack1 = foundHelper || depth0.cssClass;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "cssClass", { hash: {} }); }
  buffer += escapeExpression(stack1) + " success default\"><span>";
  foundHelper = helpers.buttonTitle;
  stack1 = foundHelper || depth0.buttonTitle;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "buttonTitle", { hash: {} }); }
  buffer += escapeExpression(stack1) + "</span></button>\n  </div>\n</div>\n";
  return buffer;});
templates['select'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, stack2, foundHelper, tmp1, self=this, functionType="function", helperMissing=helpers.helperMissing, undef=void 0, escapeExpression=this.escapeExpression, blockHelperMissing=helpers.blockHelperMissing;

function program1(depth0,data) {
  
  
  return "multiple";}

function program3(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "style=\"width:";
  foundHelper = helpers.width;
  stack1 = foundHelper || depth0.width;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "width", { hash: {} }); }
  buffer += escapeExpression(stack1) + ";\"";
  return buffer;}

function program5(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "data-placeholder=\"";
  foundHelper = helpers.placeholder;
  stack1 = foundHelper || depth0.placeholder;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "placeholder", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\"";
  return buffer;}

function program7(depth0,data) {
  
  
  return "<option value=\"\"></option>";}

function program9(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n    <option value=\"";
  foundHelper = helpers.id;
  stack1 = foundHelper || depth0.id;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "id", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\">";
  foundHelper = helpers.value;
  stack1 = foundHelper || depth0.value;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "value", { hash: {} }); }
  buffer += escapeExpression(stack1) + "</option>\n  ";
  return buffer;}

  buffer += "<select ";
  foundHelper = helpers.multiple;
  stack1 = foundHelper || depth0.multiple;
  stack2 = helpers['if'];
  tmp1 = self.program(1, program1, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += " ";
  foundHelper = helpers.width;
  stack1 = foundHelper || depth0.width;
  stack2 = helpers['if'];
  tmp1 = self.program(3, program3, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += " \n  class=\"add_chosen\" \n  ";
  foundHelper = helpers.placeholder;
  stack1 = foundHelper || depth0.placeholder;
  stack2 = helpers['if'];
  tmp1 = self.program(5, program5, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n  name=\"";
  foundHelper = helpers.name;
  stack1 = foundHelper || depth0.name;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "name", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\">\n\n  ";
  foundHelper = helpers.placeholder;
  stack1 = foundHelper || depth0.placeholder;
  stack2 = helpers['if'];
  tmp1 = self.program(7, program7, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n\n  ";
  foundHelper = helpers.data;
  stack1 = foundHelper || depth0.data;
  stack1 = (stack1 === null || stack1 === undefined || stack1 === false ? stack1 : stack1.value);
  tmp1 = self.program(9, program9, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  if(foundHelper && typeof stack1 === functionType) { stack1 = stack1.call(depth0, tmp1); }
  else { stack1 = blockHelperMissing.call(depth0, stack1, tmp1); }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n</select>\n\n\n";
  return buffer;});
})();