local VERSION = "0.447"

local SWP_SID = "urn:upnp-org:serviceId:SwitchPower1"
local SWP_STATUS = "Status"
local SWP_TARGET = "Target"
local SWP_SET_TARGET = "SetTarget"

local IPS_IID = "urn:micasaverde-com:serviceId:InputSelection1"
local VOL_SID = "urn:micasaverde-com:serviceId:Volume1"
local DEN_SID = "urn:denon-com:serviceId:Receiver1"

local DEVICETYPE_DENON_AVR_CONTROL = "urn:schemas-denon-com:device:receiver:1"
local DEVICEFILE_DENON_AVR_CONTROL = "D_DenonReceiver1.xml"
--
local MAX_VOL = 98
local MIN_VOL = 0
local MIN_VOL_ZONE = "10"
local INCR = 0.5
local DEBUG_MODE = true

local g_sourceName = {}
local g_zones = {}
local g_tuner = {}
local g_xm = {}

local MODEL = {
	['1000'] = {zones = "2"},
	['1713'] = {zones = "2"},
	['1913'] = {zones = "2"},
	['2000'] = {zones = "2"},
	['2106'] = {zones = "2"},
	['2307'] = {zones = "1"},
	['2803'] = {zones = "1"},
	['2805'] = {zones = "2"},
	['2807'] = {zones = "2"},
	['3312'] = {zones = "2,3"},
	['3313'] = {zones = "2,3"},
	['3803'] = {zones = "1"},
	['3805'] = {zones = "1,2"},
	['3806'] = {zones = "2,3"},
	['3808'] = {zones = "2,3"},
	['4000'] = {zones = "2,3"},
	['4306'] = {zones = "2,3"},
	['4520'] = {zones = "2,3,4"},
	['4802'] = {zones = "1"},
	['4806'] = {zones = "2,3"},
	['5803'] = {zones = "1,2"},
	['5805'] = {zones = "2,3,4"}
}

local avr_rec_dev = nil
------------------------------------------------------------------------------------------
local function log (text,level)
  luup.log("AVRReceiverPlugin::" .. text,level or 50)
end
------------------------------------------------------------------------------------------
function debug (text,level)
  if (DEBUG_MODE == true) then
    log(text,level or 1)
  end
end
------------------------------------------------------------------------------------------
function trim(s)
  return s:match "^%s*(.-)%s*$"
end
------------------------------------------------------------------------------------------
function listTable(table)
	for k, v in pairs(table) do
		debug('listTable: key: _' .. k .. ' value: _' .. v .. '.')
	end
end
------------------------------------------------------------------------------------------
function normaliseVolume(device, volume)

	quant,frac = math.modf(volume)
	frac = ((device == avr_rec_dev) and (string.format("%.1f", frac) == "0.5")) and "5" or ""
	if ((device ~= avr_rec_dev) and (tonumber(quant) <= tonumber(MIN_VOL_ZONE))) then quant = MIN_VOL_ZONE end
	return (string.format("%02i", quant)..frac)

end
------------------------------------------------------------------------------------------
function AVRReceiverSend(command)

    local cmd = command
    local dataSize = string.len(cmd)
    assert(dataSize <= 135)
    --luup.sleep(500)
    if (luup.io.write(cmd) == false) then
        log("AVRReceiverSend: cannot send command " .. command .. " communications error", 1)
        luup.set_failure(true)
        return false
    end
    log("AVRReceiverSend: command sent " .. command .. ".", 1)
    return true

end
------------------------------------------------------------------------------------------
function setMute(device, mute)

	local zone = findZone(device)
	local prefix = (zone ~= "ZM") and zone or ""
	AVRReceiverSend(prefix .. "MU" .. mute)

end
------------------------------------------------------------------------------------------
function setMasterPower(status)

	for k, v in pairs(luup.devices) do
		if(v.device_num_parent == avr_rec_dev or k == avr_rec_dev) then
			debug("setMasterPower: Device:" .. k)
			luup.variable_set(DEN_SID,"PowerStatus", status, k)
		end
	end

end
-----------------------------------------------------------------------------------
function setVolume(device, volume, fade, voltype)

	local zone = findZone(device)
	fade = (fade == 'true') and true or false
	local prefix = (zone ~= "ZM") and zone or "MV"
	local current_volume = tonumber(luup.variable_get(DEN_SID,"Volume",avr_rec_dev),10)
	if ((tonumber(volume)) ~= nil) then
		volume = tonumber(volume)
		if (fade) then
			local step = (current_volume > volume) and -0.5 or 0.5
			for i = current_volume, volume, step do
				volume = normaliseVolume(device, i)
				luup.sleep(200)
				AVRReceiverSend(prefix .. volume)
			end
		else
			volume = normaliseVolume(device, volume)
			AVRReceiverSend(prefix .. volume)
		end
	else
		volume = (volume == "UP") and "UP" or "DOWN"
		AVRReceiverSend(prefix .. volume)
	end

end
------------------------------------------------------------------------------------------
function setInput(device, input_no)

	local zone = findZone(device)
	local prefix = (zone ~= "ZM") and zone or "SI"
	local source = ""

	if(tonumber(input_no,10)~= nil) then
		source = (g_sourceName[tonumber(input_no,10)]["source"]) or false
	else
		for k, v in pairs(g_sourceName) do
			source = g_sourceName[k]["source"] or false
		end

	end
	if(source ~= false) then
		AVRReceiverSend(prefix .. source)
	end

end
------------------------------------------------------------------------------------------
function tablePrint(table, format)
  local jsonString = '{\"PRESETS\": ['

  local xmlString = '<?xml version=\"1.0\" encoding=\"UTF-8\"?><PRESETS>'
  for key, value in pairs(table) do
    jsonString = jsonString .. '{\"PRESETNO\": \"' .. key .. '\",' .. '\"STATION\": \"' ..  value .. '\"},'
    xmlString = xmlString .. '<PRESET><PRESETNO>' .. key .. '</PRESETNO><STATION>' ..  value .. '</STATION></PRESET>'
  end
  jsonString = (jsonString:sub(1,-2):len() == 0) and jsonString .. ']}' or jsonString:sub(1,-2) .. ']}'

  xmlString = xmlString .. "</PRESETS>"

	local string = format == "json" and jsonString or xmlString
  return string
end
------------------------------------------------------------------------------------------
function callbackHandler(lul_request, lul_parameters, lul_outputformat)
  local functionName = "callbackHandler"

  if (lul_request == "tuner") then
    return tablePrint(g_tuner, lul_outputformat)
  elseif (lul_request == "xm") then
    return tablePrint(g_xm, lul_outputformat)
  end

end
------------------------------------------------------------------------------------------
function handleResponse(data)
	log("handleResponse: data received " .. data)
	local msgFrom = data:sub(1,1)
	local msgType = data:sub(1,2)

	local msgZone = nil
	local message = ""
	local message_type2 = ""

	if(data:match("^Z[M?%d].")) then

		message = data:sub(3)

		msgZone = findChild(msgType)
		log("handleResponse: message from device: " .. tostring(msgZone))
		if(message:match("^CV[FCS][LR]%s%d+")) then
			msgType, message_type2 = (message:sub(3)):match("^([FCS][LR])%s(%d+)$")

		elseif (message:match("^%d+")) then
			msgType = "MV"
			data = data:sub(3)

		elseif (message:match("^OFF$") or message:match("^ON$")) then
			msgType = "PZ"

		elseif (message:match("^MUON$") or message:match("^MUOFF$")) then
			msgType = message:sub(1,2)
			data = message:sub(3)

		elseif (get_source(message) ~= false) then
			msgType = "SI"
			data = data:sub(3)

		else
			msgType = data:sub(1,2)
			data = data:sub(3)
		end

	elseif(data:match("^R[%d].*")) then
		msgType = "RR"
		msgZone = avr_rec_dev

	else
		msgType = data:sub(1,2)
		data = data:sub(3)
		msgZone = avr_rec_dev

	end

	if(msgZone == nil) then msgZone = avr_rec_dev end
	log("handleResponse: Data:" .. data .. ' Type:' .. msgType .. ' Zone:' .. msgZone)
	processMessage (data, msgType, msgZone)
	return true
end
------------------------------------------------------------------------------------------
local RECEIVER_RESPONSES = {

		["MV"] = {
		description = "Volume level change",
		handlerFunc = function (self, data, msgZone)
      local volume = data:match("(%d+)")
      volume = (volume:len() == 3) and tonumber(volume/10) or tonumber(volume)
			if ((string.find(data, "MAX"))) then
				log(self.description..": Setting MAX_VOL: " .. volume)
				MAX_VOL = volume
				return true
			end
			debug(self.description..": Volume: " .. volume .. " db: " .. (volume-80))
			luup.variable_set(DEN_SID,"VolumeDecibel",volume-80,msgZone)
			luup.variable_set(DEN_SID,"Volume",volume,msgZone)
			return true
		end
    },

		["MU"] = {
		description = "MUTE status change",
		handlerFunc = function (self, data, msgZone)
			log(self.description..": Mute: " .. data)
			if (data == "OFF") then
				luup.variable_set(VOL_SID,"Mute","0",msgZone)
			elseif (data == "ON") then
				luup.variable_set(VOL_SID,"Mute","1",msgZone)
			else
				log("response: unkown mute command" .. data .. " " .. self.description)
			end
			log("response: data received MU " .. data .. " " .. self.description)
			return true
		end
    },

    ["PW"] = {
    description = "Power status change",
		handlerFunc = function (self, data, msgZone)
			log(self.description ..": Power: " .. data)
			if (string.find(data, "STANDBY")) then
				setMasterPower("0")
			elseif (string.find(data, "ON")) then
				setMasterPower("1")
			else
			end
			log("response: data received PW " .. data .. " " .. self.description)
			return true
		end
    },

    ["PZ"] = {
    description = "Power status change",
		handlerFunc = function (self, data, msgZone)
			log(self.description ..": Power: " .. data)
			if (string.find(data, "OFF")) then
				luup.variable_set(SWP_SID,SWP_STATUS,"0",msgZone)
			elseif (string.find(data, "ON")) then
				luup.variable_set(SWP_SID,SWP_STATUS,"1",msgZone)
			else
			end
			log("response: data received PW " .. data .. " " .. self.description)
			return true
		end
    },

    ["SI"] = {
    description = "INPUT source change",
    handlerFunc = function (self, data, msgZone)
			log(self.description..": Input Source: " .. data)
			luup.variable_set(DEN_SID,"Input",data,msgZone)
			log("response: data received SI " .. data .. " " .. self.description)
			return true
			end
    },

    ["SV"] = {
    description = "VIDEO source change",
    handlerFunc = function (self, data, msgZone)
			log(self.description..": Video Source: " .. data)
			luup.variable_set(DEN_SID,"Video",data,msgZone)
			log("response: data received SV " .. data .. " " .. self.description)
			return true
			end
    },

    ["MS"] = {
    description = "SURROUND mode change",
    handlerFunc = function (self, data, msgZone)
			log(self.description..": Surround: " .. data)
			luup.variable_set(DEN_SID,"Surround",data,msgZone)
			log("response: data received MS " .. data .. " " .. self.description)
			return true
			end
    },

    ["SS"] = {
    description = "SETUP function name",
    handlerFunc = function (self, data, msgZone)
			if (data:sub(1,3) == "FUN") then
				data = data:sub(4)
				local source, name = data:match("^(.-)%s(.+)$")
				name = trim(name):gsub("\\","\\\\")
				log("handlerFunction: data received SS source:" .. source .. ":source name:" .. name ..":")
				if (not tostring(source):find("^%s*$")) then
					table.insert(g_sourceName,({["source"] = source,["name"] = name}))
					debug(self.description..": Length of table: " .. #g_sourceName .. " Source name: " .. source)
				end
			end
			if (data:sub(1,3) == "TPN") then
				local source = data:sub(4,5)
				local name = trim((data:sub(6)))
				log("handlerFunction: data received SS tuner preset:" .. source .. ":tuner freq:" .. name ..":")
				if (not tostring(source):find("^%s*$")) then
					g_tuner[source] = name
					debug(self.description  .. ": Preset name: " .. source .. " Freq: _" .. name .. "_.")
				end
			end
			if (data:sub(1,3) == "XPN") then
				local source = data:sub(4,5)
				local name = trim((data:sub(6)))
				log("handlerFunction: data received SS XM preset:" .. source .. ":XM name:" .. name ..":")
				if (not tostring(source):find("^%s*$")) then
					g_xm[source] = name
					debug(self.description ..  ": Preset name: " .. source .. " XM Channel: _" .. name .. "_.")
				end
			end
			return true
		end
    },

    ["SY"] = {
    description = "Model number",
    handlerFunc = function (self, data, msgZone)
			if (data:sub(1,2) == "MO") then
				local modelName = (data:sub(3)):gsub("(%s+)$", "")
				luup.attr_set("model", modelName, avr_rec_dev)
			end
			return true
		end
    },

    ["RR"] = {
    description = "zone names",
    handlerFunc = function (self, data, msgZone)
			data = trim(data)
			local zone = tonumber(data:sub(2,2))
			local zonePrefix = data:sub(1,2)
			local zoneName = trim(data:sub(3))
			zoneName = zoneName ~= '' and zoneName or zonePrefix
			debug(self.description .. ": Zone Prefix:_" .. zonePrefix .. "_ Zone Name:_".. zoneName .. "_.")
			g_zones[zone] = zoneName
			--listTable(g_zones)
			return true
		end
    },

    ["TF"] = {
    description = "tuner frequency",
    handlerFunc = function (self, data, msgZone)
			data = trim(data)
			local zonePrefix = data:sub(1,2)
			local zoneName = trim(data:sub(3))
			debug(self.description .. ": Freq1:_" .. zonePrefix .. "_ Freq2:_".. zoneName .. "_.")
			return true
		end
    },

    ["TM"] = {
    description = "tuner mode",
    handlerFunc = function (self, data, msgZone)
			data = trim(data)
			local zonePrefix = data:sub(1,2)
			local zoneName = trim(data:sub(3))
			debug(self.description .. ": Mode1:_" .. zonePrefix .. "_ Mode2:_".. zoneName .. "_.")
			return true
		end
    },

    ["TP"] = {
    description = "tuner preset",
    handlerFunc = function (self, data, msgZone)
			data = trim(data)
			local zonePrefix = data:sub(1,2)
			local zoneName = trim(data:sub(3))
			debug(self.description .. ": Preset1:_" .. zonePrefix .. "_ Preset2:_".. zoneName .. "_.")
			return true
		end
    }

}

------------------------------------------------------------------------------------------
function processMessage (data, msgType, msgZone)

    log("processMessage: Data:" .. data .. ' Type:' .. msgType .. ' Zone:' .. msgZone)

    if (not msgType) then
        msgType, data = checkMessage (data)
        if (not msgType or tostring (msgType) == "") then
            return false
        end
    end

    local response = RECEIVER_RESPONSES[msgType]

    if (response == nil) then
        log("processMessage: Unhandled message type '" .. msgType .. "'")
        return false
    end

    if (type (response.handlerFunc) ~= "function") then
        log("processMessage: ERROR: Unknown message type, or message type handled incorrectly.")
        return false
    end

    return response:handlerFunc (data, msgZone)

end

------------------------------------------------------------------------------------------

local function checkMessage (msg)
    if (not msg or msg == "") then
        log("checkMessage: ERROR: Empty message.")
        return nil
    end
end

------------------------------------------------------------------------------------------
function findZone (lul_device)
    log("Trying to find zone for device: " .. lul_device)
    local DeviceAltId = tostring(luup.devices[lul_device].id)
    local ParentDevice = tostring(luup.devices[lul_device].device_num_parent)
    debug("DeviceID: " .. lul_device .. ", Parent:"..ParentDevice .. ", Zone: " .. DeviceAltId)
    return DeviceAltId
end
------------------------------------------------------------------------------------------
local function setInitialParameters(avr_rec_dev)

	luup.variable_set(DEN_SID,"Version",VERSION,avr_rec_dev)
	AVRReceiverSendIntercept("MS?")
	AVRReceiverSendIntercept("SI?")
	AVRReceiverSendIntercept("SV?")
	AVRReceiverSendIntercept("MU?")
	AVRReceiverSendIntercept("ZM?")
	AVRReceiverSendIntercept("MV?")

end
------------------------------------------------------------------------------------------
function findChild(label)

	if(label == "ZM") then return avr_rec_dev end

	for k, v in pairs(luup.devices) do
		if(v.device_num_parent == avr_rec_dev and v.id == label) then
			debug("findChild: " .. v.device_num_parent  .. " " .. avr_rec_dev  .. " " ..  v.id  .. " " ..  label,1)
			return k
		end
	end

	return false
end
------------------------------------------------------------------------------------------
function get_source(input_source)
	for k, v in pairs(g_sourceName) do
		local source = (g_sourceName[k]["source"])
		debug("get_source: " .. input_source  .. " " .. k .. " " .. source,1)
		if source == input_source then
			return k
		end
	end
	return false
end

------------------------------------------------------------------------------------------
function processInterceptedMessage(command)
	command = (command:sub(1,2) == "RR") and command:sub(1,1) or command:sub(1,2)

  while true do
		data = luup.io.read()
		if (data ~= nil) then
			local result = (data:sub(1,1) == 'R') and data:sub(1,1) or data:sub(1,2)
			if (command ~= result) then
				handleResponse(data)
				luup.io.intercept()
			else
				return handleResponse(data)
			end
		end
	end
	return false

end
------------------------------------------------------------------------------------------
function AVRReceiverSendIntercept(command)
	luup.sleep(200)
    local dataSize = string.len(command)
    assert(dataSize <= 135)
    luup.sleep(200)
    luup.io.intercept()
    if (luup.io.write(command) == false) then
        log("AVRReceiverSend: cannot send command " .. command .. " communications error", 1)
        luup.set_failure(true)
        return false
    end
    log("AVRReceiverSend: command sent " .. command .. ".", 1)

    return processInterceptedMessage(command)
end
------------------------------------------------------------------------------------------
--Zone Creation
------------------------------------------------------------------------------------------
local function createZones(avr_rec_dev)

	log("createZones: Starting")

	child_devices = luup.chdev.start(avr_rec_dev)

	local detected_model = luup.attr_get("model", avr_rec_dev)
	local modelNumber = string.match(detected_model, "%d+")
	local manual_zones = luup.variable_get(DEN_SID, "Zones", avr_rec_dev)

	if (not manual_zones or manual_zones == "") then
		luup.variable_set(DEN_SID, "Zones",  "none", avr_rec_dev)
	end

	local zones = (MODEL[modelNumber] ~= nil) and MODEL[modelNumber].zones or manual_zones

	luup.attr_set("name", (detected_model or "AVR") .. '_' ..(g_zones[1]), avr_rec_dev)

	for zone_num in zones:gmatch("%d+") do
		local autoName = g_zones[tonumber(zone_num)]
		zoneName = (detected_model or 'AVR') .. '_' .. autoName
		DEVICEFILE_DENON_AVR_CONTROL = luup.attr_get("device_file", avr_rec_dev)
		luup.chdev.append(avr_rec_dev,child_devices, "Z" .. zone_num,zoneName,DEVICETYPE_DENON_AVR_CONTROL,DEVICEFILE_DENON_AVR_CONTROL,"I_DenonReceiver1.xml","",true)
		debug("createZone: Zone number:" .. zone_num .. " Zone name:" .. zoneName .. ".",1)
	end

    luup.chdev.sync(avr_rec_dev,child_devices)

	for k, v in pairs(luup.devices) do
		if((v.device_num_parent == avr_rec_dev) or (tonumber(avr_rec_dev) == k)) then
			AVRReceiverSendIntercept(v.id .. "?")
			AVRReceiverSendIntercept(v.id .. "MU?")
			debug("createZone: Device number:" .. k .. " Device name:" .. v.id .. ".",1)
		end
	end

  return true

end
------------------------------------------------------------------------------------------
--misc
------------------------------------------------------------------------------------------
local function miscSetup(avr_rec_dev)

	log("miscSetup: Starting")

  --[[
	if(modelNumber ~= "4520") then
		AVRReceiverSendIntercept("SSTPN ?")  --preset info (tuner)
		AVRReceiverSendIntercept("SSXPN ?")  --preset info (XM)
	end

			AVRReceiverSendIntercept("NSE")  --Display info ASCII
  ]]--

	return true

end
------------------------------------------------------------------------------------------
--Connection Setup
------------------------------------------------------------------------------------------
local function connectionType()
	local ip = luup.devices[avr_rec_dev].ip or ""
	if (ip == "") then
		log("connectionType: Running on Serial.")
	else
		local ipAddress, port = ip:match("^([^:]+):?(%d-)$")
		if (ipAddress and ipAddress ~= "") then
			if (not port or port == "") then
        port = 23
      else
        port = tonumber(port, 10)
      end
			log("connectionType: ipAddress = "..(ipAddress or "nil")..", port = "..(port or "nil")..".")
    	luup.io.open(avr_rec_dev, ipAddress, port)

			if( luup.io.is_connected(avr_rec_dev)==false ) then
				return false
			end

		end
    return true
	end
end
------------------------------------------------------------------------------------------
--Start Up
------------------------------------------------------------------------------------------
function receiverStartup(lul_device)

  log(":AVR Plugin version " .. VERSION .. ".")
	avr_rec_dev = lul_device

	luup.attr_set("altid", "ZM", avr_rec_dev)

	local cj = require("createJSON")

	if (not connectionType()) then
		return false, "Communications error", "AVR Receiver"
	end

	--Set initial power status
	luup.variable_set(SWP_SID,SWP_STATUS,"0",avr_rec_dev)

	--Returns power status.
	if (not AVRReceiverSendIntercept("PW?")) then
		return false, "Device not currently available", "AVR Receiver"
	end

	AVRReceiverSendIntercept("RR?")
	AVRReceiverSendIntercept("SSFUN ?")
	AVRReceiverSendIntercept("SYMO")

	--main zone initial parameters
	setInitialParameters(avr_rec_dev)

	createZones(avr_rec_dev)

	local setupStatus = luup.variable_get(DEN_SID, "Setup", avr_rec_dev) or ""
	if (setupStatus == "" or setupStatus == "0") then
		local status = cj.create_static_json(g_sourceName, avr_rec_dev)
		if (status == true) then
			luup.variable_set(DEN_SID, "Setup",  "1", avr_rec_dev)
		end
	end

	luup.register_handler("callbackHandler", "tuner")
	luup.register_handler("callbackHandler", "xm")
    luup.variable_set("urn:micasaverde-com:serviceId:HaDevice1","CommFailure","0", avr_rec_dev)

	return true, "Startup successful.", "AVR Receiver"

end

