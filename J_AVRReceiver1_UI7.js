var avr = (function(api) {
 var uuid = "CEAB36C6-08D6-4873-AA3b-CA2FE661C195";
 var myModule = {};
 var device = api.getCpanelDeviceId();
 var requestURL = api.getCommandURL();

 function onBeforeCpanelClose(args) {
  // do some cleanup...
  console.log('handler for before cpanel close');
 }

 function init() {
  // register to events...
  api.registerEventHandler('on_ui_cpanel_before_close', myModule, 'onBeforeCpanelClose');
 }

 function newLayout() {
  var html = "";
  html += '<!DOCTYPE html>';
  html += '<head>';

  html += '<style type="text/css">';

  html += 'h1 {';
  html += 'color: #006f44;';
  html += 'font-family: \'open_sanslight\';';
  html += 'font-size: 40px;';
  html += 'text-align: center;';
  html += '}';

  html += 'h3 {';
  html += 'color: #006f44;';
  html += 'font-family: \'open_sanslight\';';
  html += 'font-size: 25px;';
  html += 'text-align: left;';
  html += '}';
  
  html += 'form p label {';
  html += 'display:block;';
  html += 'float:left;';
  html += '}';

  html += '</style>';

  html += '</head>';
  html += '<body>';
  return html;
 }

 function ShowStatus(text, error) {
  var html = '';
  html =
   '<input type="button" value="Reload Luup" onClick="avr.doReload()"/>';

  if (!error) {
   document.getElementById("avr_saveChanges_text")
    .style.backgroundColor = "#00A652";
   document.getElementById("avr_saveChanges_text")
    .innerHTML = text;
   document.getElementById("avr_saveChanges_button")
    .style.backgroundColor = "#00A652";
   document.getElementById("avr_saveChanges_button")
    .innerHTML = html;
  } else {
   document.getElementById("avr_saveChanges_text")
    .style.backgroundColor = "#FF9090";
   document.getElementById("avr_saveChanges_text")
    .innerHTML = text;
   document.getElementById("avr_saveChanges_button")
    .style.backgroundColor = "#FF9090";
   document.getElementById("avr_saveChanges_button")
    .innerHTML = html;
  }
 }

 function setDeviceStateVariable(DEVICE, SID, VARIABLE, VALUE) {
  api.setDeviceStatePersistent(DEVICE, SID, VARIABLE, VALUE, {
   'onSuccess': function() {
    ShowStatus('Data updated, Reload LuuP Engine  to commit changes.',
     false);
   },
   'onFailure': function() {
    ShowStatus(
     'Failed to update data, Reload LuuP Engine and try again.',
     true);
   }
  });
 }

 function doReload() {
  var requestURL = data_request_url + 'id=lu_action';
  requestURL += '&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&timestamp=' + new Date().getTime() + '&action=Reload';
  var xmlHttp = new XMLHttpRequest();
  xmlHttp.open("GET", requestURL, false);
  xmlHttp.send(null);
 }

 function resetTemplate(device) {
  var zones = document.getElementById('avr_zones').value
  var inputs = document.getElementById('avr_inputs').value
  setDeviceStateVariable(device, "urn:denon-com:serviceId:Receiver1", "Inputs", inputs);
  setDeviceStateVariable(device, "urn:denon-com:serviceId:Receiver1", "Zones", zones);
  setDeviceStateVariable(device, "urn:denon-com:serviceId:Receiver1", "Setup", "0");
 }



 function configure(device) {
  var html = newLayout();
  var zones = api.getDeviceState(device, "urn:denon-com:serviceId:Receiver1", "Zones", 1);
  var inputs = api.getDeviceState(device, "urn:denon-com:serviceId:Receiver1", "Inputs", 1);
  html += '<div class="clearfix">';
  html += '<h1>AVR Receiver Configuration</h1>';
  html += '<form name ="avr_config">';
  html += '<p><label>Zones:</label><input id="avr_zones" type="text" value="' + zones + '" Name="avr_zones"></p>';
  html += '<p><label>Inputs:</label><input id="avr_inputs" type="text" value="' + inputs + '" Name="avr_inputs" size="100"></p>';
  html += '<p><input id="avr_reset" type="button" value="Reset Template" class="btn1" onclick="avr.resetTemplate(' + device + ')"></p>';
  html += '</form>';
  
  html += '<p id="avr_saveChanges_text" style= "font-weight: bold; text-align: center;"></p><p id="avr_saveChanges_button" style= "text-align: center;"></p>';
  html += '</div>';
  html += '</body>';
  html += '</html>';
  
  api.setCpanelContent(html);
 }

 myModule = {
  uuid: uuid,
  init: init,
  onBeforeCpanelClose: onBeforeCpanelClose,
  resetTemplate: resetTemplate,
  doReload: doReload,
  configure: configure
 };
 return myModule;
})(api);
