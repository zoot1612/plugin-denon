local VERSION = "1.26"

local SWP_SID = "urn:upnp-org:serviceId:SwitchPower1"
local SWP_STATUS = "Status"
local SWP_TARGET = "Target"
local SWP_SET_TARGET = "SetTarget"

local IPS_IID = "urn:micasaverde-com:serviceId:InputSelection1"
local VOL_SID = "urn:micasaverde-com:serviceId:Volume1"
local DEN_SID = "urn:denon-com:serviceId:Receiver1"
local REN_SID = "urn:upnp-org:serviceId:RenderingControl1"

local DEVICETYPE_DENON_AVR_CONTROL = "urn:schemas-denon-com:device:receiver:1"
local DEVICEFILE_DENON_AVR_CONTROL = "D_DenonReceiver1.xml"
--
local MAX_VOL = 98.5
local MIN_VOL = 0
local MIN_VOL_ZONE = 10
local INCR = 0.5
local DEFAULT_VOLUME = 25
local DEFAULT_RAMP_TIME = 17
local DEBUG_MODE = true
local POLL = "5m"
local g_sourceName = {}
local g_zones = {}
local g_tuner = {}
local g_xm = {}

local MODEL = {
    ['300'] = {},
    ['400'] = {zones = "2"},
    ['1000'] = {zones = "2"},
    ['1603'] = {zones = "2"},                  -- Marantz NR1603USA
    ['1713'] = {zones = "2"},
    ['1913'] = {zones = "2"},
    ['2000'] = {zones = "2"},
    ['2106'] = {zones = "2"},
    ['2112'] = {zones = "2"},
    ['2307'] = {zones = "1"},
    ['2803'] = {zones = "1"},
    ['2805'] = {zones = "2"},
    ['2807'] = {zones = "2"},
    ['3000'] = {zones = "2"},
    ['3312'] = {zones = "2,3"},
    ['3313'] = {zones = "2,3"},
    ['3803'] = {zones = "1"},
    ['3805'] = {zones = "1,2"},
    ['3806'] = {zones = "2,3"},
    ['3808'] = {zones = "2,3"},{zoneAutoName}, -- autoName not used
    ['4000'] = {zones = "2,3"},
    ['4306'] = {zones = "2,3"},
    ['4520'] = {zones = "2,3,4"},
    ['4802'] = {zones = "1"},
    ['4806'] = {zones = "2,3"},
    ['5803'] = {zones = "1,2"},
    ['5805'] = {zones = "2,3,4"}
}

local avr_rec_dev = nil

local TASK_ERROR      = 2
local TASK_ERROR_PERM = -2
local TASK_SUCCESS    = 4
local TASK_BUSY       = 1
local g_taskHandle = -1
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
function task (text, mode)

  log("task: ".. text)
  if (mode == TASK_ERROR_PERM) then
    luup.task(text, TASK_ERROR, "AVR Plugin", g_taskHandle)
  else
    luup.task(text, mode, "AVR Plugin", g_taskHandle)

    -- Clear the previous error, since they're all transient
    if (mode ~= TASK_SUCCESS) then
      luup.call_delay("clearStatusMessage", 30)
    end
  end

end
------------------------------------------------------------------------------------------
function clearStatusMessage()

  luup.task("Clearing...", TASK_SUCCESS, "AVR Plugin", g_taskHandle)
  return true

end
------------------------------------------------------------------------------------------
local function trim(s)

  return s:match "^%s*(.-)%s*$"

end
------------------------------------------------------------------------------------------
local function listTable(table)

    for k, v in pairs(table) do
        debug('listTable: key: _' .. k .. ' value: _' .. v .. '.')
    end

end
------------------------------------------------------------------------------------------
local function normaliseVolume(device, volume)

  local current_volume = tonumber(luup.variable_get(REN_SID,"Volume",device),10)
  MIN_VOL = (device == avr_rec_dev) and MIN_VOL or MIN_VOL_ZONE
  volume = (volume >= MIN_VOL and volume <= MAX_VOL) and volume or current_volume

  quant,frac = math.modf(volume)
  frac = ((device == avr_rec_dev) and (string.format("%.1f", frac) == "0.5")) and "5" or ""
  debug("setVolume: current volume: " .. current_volume .. " new volume: " .. volume .. ".")
  return (string.format("%02i", quant)..frac)

end
------------------------------------------------------------------------------------------
function AVRReceiverSend(command)

    local dataSize = string.len(command)
    if(not(assert(dataSize > 0 and dataSize <= 135))) then return false end
    if (luup.io.write(command) == false) then
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
function getMute(device)

    local zone = findZone(device)
    local prefix = (zone ~= "ZM") and zone or ""
    AVRReceiverSend(prefix .. "MU?")

end
------------------------------------------------------------------------------------------
function GetStatus(device)

    local zone = findZone(device)
    local prefix = (zone ~= "ZM") and zone or "ZM"
    AVRReceiverSend(prefix .. "?")

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
function setVolume(device, volume)

    local zone = findZone(device)
    local prefix = (zone ~= "ZM") and zone or "MV"
        if ((tonumber(volume)) ~= nil) then
        volume = normaliseVolume(device, tonumber(volume))
        AVRReceiverSend(prefix .. volume)
    else
        volume = (volume == "UP") and "UP" or "DOWN"
        AVRReceiverSend(prefix .. volume)
    end

end
------------------------------------------------------------------------------------------
function setVolumeDB(device, volumeDB)

    local zone = findZone(device)
    local prefix = (zone ~= "ZM") and zone or "MV"
    local volume = volumeDB + 80
    if ((tonumber(volume)) ~= nil) then
        volume = normaliseVolume(device, tonumber(volume))
        AVRReceiverSend(prefix .. volume)
    end

end
------------------------------------------------------------------------------------------
function rampToVolume(device, settings)

  local desiredVolume = settings.DesiredVolume
  
  local resetVolumeAfter = settings.ResetVolumeAfter
  resetVolumeAfter = (tonumber(resetVolumeAfter) == 0) and "0" or "1"
  luup.variable_set(REN_SID,"A_ARG_TYPE_ResetVolumeAfter", resetVolumeAfter, device)
  
  local programURI = settings.ProgramURI
  luup.variable_set(REN_SID,"A_ARG_TYPE_ProgramURI", programURI, device)
  local programURI = luup.variable_get(REN_SID, "A_ARG_TYPE_ProgramURI", device) or ""
  if (rprogramURI == "") then
    luup.variable_set(REN_SID, "A_ARG_TYPE_ProgramURI",  "0", device)
  end 

  local rampType = settings.RampType
  luup.variable_set(REN_SID,"A_ARG_TYPE_RampType", rampType, device)
    
  if(rampType == "SLEEP_TIMER_RAMP_TYPE") then -- mutes and ups Volume per default within 17 seconds to desiredVolume
    luup.call_action(REN_SID, "SetVolume", 0, device)
  end

  if(rampType == "ALARM_RAMP_TYPE") then  -- Switches audio on and slowly goes to volume
    luup.call_action(REN_SID, "SetVolume", 0, device)
  end
  
  if(rampType == "AUTOPLAY_RAMP_TYPE") then  -- very fast and smooth; Implemented from Sonos for the autoplay feature
      
  end
  
  local rampTimeSeconds = luup.variable_get(REN_SID, "A_ARG_TYPE_RampTimeSeconds", device) or ""
  if (rampTimeSeconds == "" or rampTimeSeconds == "0") then
    luup.variable_set(REN_SID, "A_ARG_TYPE_RampTimeSeconds",  DEFAULT_RAMP_TIME, device)
  end  

  local currentVolume = luup.variable_get(REN_SID, "Volume", device)
  
  if(resetVolumeAfter == 1) then
    local previousVolume = currentVolume
  end
  
  local step = (currentVolume < desiredVolume) and 0.5 or -0.5
  local delta = math.abs(desiredVolume - currentVolume)
  local volumeTimeStep = DEFAULT_RAMP_TIME/delta
    
  for i = currentVolume, desiredVolume, step do
    luup.sleep(volumeTimeStep)
    local lul_arguments = {}
    lul_arguments["DesiredVolume"] = i
    luup.call_action(REN_SID, "SetVolume", lul_arguments, device)
  end

end
------------------------------------------------------------------------------------------
function getVolume(device)

    local zone = findZone(device)
    local prefix = (zone ~= "ZM") and zone or "MV"
    AVRReceiverSend(prefix .. '?')

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
function getInput(device)

    local DeviceAltId = tostring(luup.devices[device].id)
    local prefix = (zone ~= "ZM") and DeviceAltId or "SI"
    AVRReceiverSend(prefix .. '?')

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
      volume = (volume == 99) and 0 or volume
            if ((string.find(data, "MAX"))) then
                log(self.description..": Setting MAX_VOL: " .. volume)
                MAX_VOL = volume
                return true
            end
            debug(self.description..": Volume: " .. volume .. " db: " .. (volume-80))
            luup.variable_set(REN_SID,"VolumeDB",volume-80,msgZone)
            luup.variable_set(REN_SID,"Volume",volume,msgZone)
            return true
        end
    },

        ["MU"] = {
        description = "MUTE status change",
        handlerFunc = function (self, data, msgZone)
            log(self.description..": Mute: " .. data)
            if (data == "OFF") then
                luup.variable_set(REN_SID,"Mute","0",msgZone)
            elseif (data == "ON") then
                luup.variable_set(REN_SID,"Mute","1",msgZone)
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
            local source =get_source(data) or " Unknown"
            luup.variable_set(DEN_SID,"Source","Input"..source,msgZone)
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

    AVRReceiverSendIntercept("MS?")
    AVRReceiverSendIntercept("SI?")
    AVRReceiverSendIntercept("SV?")
    AVRReceiverSendIntercept("MU?")
    AVRReceiverSendIntercept("ZM?")
    AVRReceiverSendIntercept("MV?")

    for k, v in pairs(luup.devices) do
        if(v.device_num_parent == avr_rec_dev) then
          AVRReceiverSendIntercept(v.id .. "?")
          AVRReceiverSendIntercept(v.id .. "MU?")
          debug("createZone: Device number:" .. k .. " Device name:" .. v.id .. ".",1)
        end
    end

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
function processInterceptedMessage(command)

    command = command:sub(1,2)
    while true do
        data = luup.io.read(3,avr_rec_dev)
        if (data ~= nil) then
            local result = (data:sub(1,1) == 'R') and 'RR' or data:sub(1,2)
            if (command ~= result) then
                debug("processInterceptedMessage:(command ~= result)  result:" .. result .. " command:" .. command .. ".",1)
                luup.io.intercept()
                handleResponse(data)
            else
                debug("processInterceptedMessage: result:" .. result .. " command:" .. command .. ".",1)
                return handleResponse(data)
            end
        end
    end
    return false

end
------------------------------------------------------------------------------------------
function AVRReceiverSendIntercept(command)

    local dataSize = string.len(command)
    if(not(assert(dataSize > 0 and dataSize <= 135))) then return false end
    luup.sleep(350)
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
    local zones = ""

    if (not manual_zones or manual_zones == "") then
        luup.variable_set(DEN_SID, "Zones",  "", avr_rec_dev)
    end

    if(manual_zones == "") then
      zones = (MODEL[modelNumber] ~= nil) and MODEL[modelNumber].zones or ""
    else
      zones = manual_zones or ""
    end

    for zone_num in zones:gmatch("%d+") do
        local autoName = g_zones[tonumber(zone_num)]
        zoneName = (detected_model or 'AVR') .. '_' .. (autoName or zone_num)
        DEVICEFILE_DENON_AVR_CONTROL = luup.attr_get("device_file", avr_rec_dev)
        luup.chdev.append(avr_rec_dev,child_devices, "Z" .. zone_num,zoneName,DEVICETYPE_DENON_AVR_CONTROL,DEVICEFILE_DENON_AVR_CONTROL,"I_DenonReceiver1.xml","",false)
        debug("createZone: Zone number:" .. zone_num .. " Zone name:" .. zoneName .. ".",1)
    end

    luup.chdev.sync(avr_rec_dev,child_devices)

  return true

end

------------------------------------------------------------------------------------------
--Connection check
------------------------------------------------------------------------------------------
function checkConnection()

    if (luup.io.is_connected(avr_rec_dev) == false) then
        debug( "io.is_connected is false - AVR no longer connected, attempt to reconnect")
        status = connectionType()
            if (status == true) then
                debug( "Re-connect attempt successful")
                luup.variable_set("urn:micasaverde-com:serviceId:HaDevice1","CommFailure","0", avr_rec_dev)
                clearStatusMessage()
            end
            task("Re-connect attempt un-successful", TASK_ERROR_PERM)
    else
        debug( "Connection currently OK",1)
    end
    luup.call_timer("checkConnection", 1, POLL, "", "")

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
      port = (not port or port == "") and 23 or tonumber(port, 10)
      log("connectionType: ipAddress = "..(ipAddress or "nil")..", port = "..(port or "nil")..".")
      luup.io.open(avr_rec_dev, ipAddress, port)
    end
  end

  if( luup.io.is_connected(avr_rec_dev)==false ) then
    return false
  end

  return true

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
	luup.variable_set("urn:micasaverde-com:serviceId:HaDevice1","CommFailure","0", avr_rec_dev)

    --Set initial power status
    luup.variable_set(SWP_SID,SWP_STATUS,"0",avr_rec_dev)

    --Returns power status.
    if (not AVRReceiverSendIntercept("SSFUN ?")) then
        return false, "Device not currently available", "AVR Receiver"
    end

    AVRReceiverSendIntercept("SYMO")

    local numberOfZones = 0

    local detected_model = luup.attr_get("model", avr_rec_dev)
    local modelNumber =  string.match(detected_model, "%d+")

    if MODEL[modelNumber] ~= nil then
        local zones = MODEL[modelNumber].zones or ""
        for zones in zones:gmatch("%d+") do numberOfZones = numberOfZones + 1 end
        AVRReceiverSendIntercept("PW?")
        createZones(avr_rec_dev)
    else
        AVRReceiverSendIntercept("PW?")
    end
    
    local setupStatus = luup.variable_get(DEN_SID, "Setup", avr_rec_dev) or ""
    local version = luup.variable_get(DEN_SID,"Version",avr_rec_dev) or 0
    if(tonumber(VERSION) > tonumber(version)) then
      setupStatus = "0"
      luup.variable_set(DEN_SID,"Version",VERSION,avr_rec_dev)
    end
    
    setInitialParameters(avr_rec_dev)
        
    if (setupStatus == "" or setupStatus == "0") then
    
    	local ui7Check = luup.variable_get(DEN_SID, "UI7Check", avr_rec_dev) or ""
	    if ui7Check == "" then
		    luup.variable_set(DEN_SID, "UI7Check", "false", avr_rec_dev)
		    ui7Check = "false"
		    debug("UI7 check for device " .. avr_rec_dev)
	    end
	    
	    if( luup.version_branch == 1 and luup.version_major == 7 and ui7Check == "false") then
		    luup.variable_set(DEN_SID, "UI7Check", "true", avr_rec_dev)
		    ui7Check = "true"
	    end
    
      luup.attr_set("name", (detected_model or "AVR") .. '_' .. ((g_zones[1]) or "main"), avr_rec_dev)
      local status = cj.create_static_json(g_sourceName, avr_rec_dev, ui7Check)
      if (status == true) then
        luup.variable_set(DEN_SID, "Setup",  "1", avr_rec_dev)
      end
    end

    local pollFreq = luup.variable_get(DEN_SID, "PollFreq", avr_rec_dev) or ""
    if (pollFreq == "" or pollFreq == "0") then
        luup.variable_set(DEN_SID, "PollFreq",  POLL, avr_rec_dev)
    end

	luup.call_delay("checkConnection", 60, "")

	--luup.variable_set(DEN_SID,"Source","Input"..source,msgZone)
    --luup.register_handler("callbackHandler", "tuner")
    --luup.register_handler("callbackHandler", "xm")

    return true, "Startup successful.", "AVR Receiver"

end

