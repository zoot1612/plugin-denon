var AVR = (function(api)
{
	var uuid = 'E451565B-B468-4E9E-8981-30DB4FD16F71';
	var myModule = {};
	var device = api.getCpanelDeviceId();
	
	function init()
	{
		// register to events...
		api.registerEventHandler('on_ui_cpanel_before_close', myModule,
			'onBeforeCpanelClose');
	}

	function onBeforeCpanelClose(args)
	{
		// do some cleanup...
		console.log('handler for before cpanel close');
	}

	function doReload(device)
	{
	  var requestURL = data_request_url + 'id=lu_action';
	  requestURL += '&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&timestamp=' + new Date().getTime() + '&action=Reload';
	  var xmlHttp = new XMLHttpRequest();
	  xmlHttp.open("GET", requestURL, false);
	  xmlHttp.send(null);
	}
	
	function configuration(device)
	{
	  var html = '';
	  html +=
	    '<table width="100%" style="border-collapse: collapse"><tbody><tr><td id="wemo_saveChanges_text" style= "font-weight: bold; text-align: center;"></td><td id="wemo_saveChanges_button" style= "text-align: center;"></td></tr></tbody>';
	  html +=
	    '</table>';
	}

	myModule = {
		uuid: uuid,
		init: init,
		onBeforeCpanelClose: onBeforeCpanelClose,
		doReload: doReload,
		configuration: configuration
	};
	return myModule;
})(api);
