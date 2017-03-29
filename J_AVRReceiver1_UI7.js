var AVR = (function(api)
{
	var uuid = 'E451565B-B468-4E9E-8981-30DB4FD16F71';
	var myModule = {};
	var device = api.getCpanelDeviceId();

	function onBeforeCpanelClose(args)
	{
		// do some cleanup...
		console.log('handler for before cpanel close');
	}

	function init()
	{
		// register to events...
		api.registerEventHandler('on_ui_cpanel_before_close', myModule,
			'onBeforeCpanelClose');
	}

	function ShowStatus(text, error)
	{
		var html = '';
		html =
			'<input type="button" value="Reload Luup" onClick="AVR.doReload()"/>';

		if (!error)
		{
			document.getElementById("avr_saveChanges_text")
				.style.backgroundColor = "#00A652";
			document.getElementById("avr_saveChanges_text")
				.innerHTML = text;
			document.getElementById("avr_saveChanges_button")
				.style.backgroundColor = "#00A652";
			document.getElementById("avr_saveChanges_button")
				.innerHTML = html;
		}
		else
		{
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

	function doReload(device)
	{
		var requestURL = data_request_url + 'id=lu_action';
		requestURL +=
			'&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&timestamp=' +
			new Date()
			.getTime() + '&action=Reload';
		var xmlHttp = new XMLHttpRequest();
		xmlHttp.open("GET", requestURL, false);
		xmlHttp.send(null);
	}

	myModule = {
		uuid: uuid,
		init: init,
		onBeforeCpanelClose: onBeforeCpanelClose,
		doReload: doReload,
	};
	return myModule;
})(api);
