// Device Service
var DEN_DID = "urn:denon-com:serviceId:Receiver1";
//local ip
ipaddress = data_request_url;

function layout()
{
    var html = "";
    html += '<!DOCTYPE html>';
    html += '<head>';
    html += '<style type="text/css">';
    html += 'div#divContainer';
    html += '{';
    html += 'max-width: 800px;';
    html += 'margin: 0 auto;';
    html += 'font-family: Calibri;';
    html += 'font-size:1em;';
    html += 'padding: 0.1em 0.1em 0.1em 0.1em;';
    html += '-moz-border-radius: 10px;';
    html += '-webkit-border-radius: 10px;';
    html += 'border-radius: 10px;';
    html += 'background-color: #00CCEE;';
    html += 'background: -webkit-gradient(linear, left top, left bottom, from(#025CB6), to(#3295F8));';
    html += 'background: -moz-linear-gradient(top, #025CB6, #3295F8);';
    html += '-moz-box-shadow: 5px 5px 10px rgba(0,0,0,0.3);';
    html += '-webkit-box-shadow: 5px 5px 10px rgba(0,0,0,0.3);';
    html += 'box-shadow: 5px 5px 10px rgba(0,0,0,0.3);';
    html += '}';
    html += 'h1 {color:#FFE47A; font-size:1.5em;text-align:center;}';
    html += 'table.formatAVRPanel {';
    html += 'width: 100%;';
    html += 'border-collapse:collapse;';
    html += 'color: #606060;';
    html += '}';
    html += 'table.formatAVRPanel thead tr td';
    html += '{';
    html += 'background-color: White;';
    html += '}';
    html += 'table.formatAVRPanel thead tr th';
    html += '{';
    html += 'text-align:middle;';
    html += 'text-align:center;';
    html += 'background-color: #808080;';
    html += 'background: -webkit-gradient(linear, left top, left bottom, from(#025CB6), to(#909090));';
    html += 'background: -moz-linear-gradient(top, #025CB6, #909090);';
    html += 'color: #dadada;';
    html += '}';
    html += 'table.formatAVRPanel tbody tr:nth-child(odd) {';
    html += 'background-color: #fafafa;';
    html += '}';
    html += 'table.formatAVRPanel tbody tr:nth-child(even) {';
    html += 'background-color: #efefef;';
    html += '}';
    html += 'table.formatAVRPanel tbody tr:last-child {';
    html += 'border-bottom: solid 1px #404040;';
    html += '}';
    html += 'table.formatAVRPanel tbody tr.separator {';
    html += 'background-color: #808080;';
    html += 'background: -webkit-gradient(linear, left top, left bottom, from(#025CB6), to(#909090));';
    html += 'background: -moz-linear-gradient(top, #025CB6, #909090);';
    html += 'color: #dadada;';
    html += '}';
    html += 'table.formatAVRPanel td {';
    html += 'vertical-align:middle;';
    html += '}';
    html += 'table.formatAVRPanel tfoot{';
    html += 'text-align:center;';
    html += 'color:#303030;';
    html += 'text-shadow: 0 1px 1px rgba(255,255,255,0.3);';
    html += '}';
    html += 'btn0';
    html += '{';
    html += 'width: 40px;';
    html += 'height:20px;';
    html += 'font-family: Calibri;';
    html += 'font-size: 0.90em;';
    html += 'vertical-align:middle;';
    html += 'text-align: center;';
    html += '} ';
    html += 'input';
    html += '{';
    html += 'margin: 0;';
    html += 'padding: 0;';
    html += 'width: 50px;';
    html += 'height:15px;';
    html += 'vertical-align:middle;';
    html += 'text-align: center;';
    html += '}';
    html += 'input.btn1';
    html += '{';
    html += 'width: 40px;';
    html += 'height:20px;';
    html += 'font-family: Calibri;';
    html += 'font-size: 0.90em;';
    html += 'vertical-align:middle;';
    html += 'text-align: center;';
    html += '} ';
    html += 'input.btn2';
    html += '{';
    html += 'width: 90px;';
    html += 'height:20px;';
    html += 'font-family: Calibri;';
    html += 'font-size: 0.90em;';
    html += 'vertical-align:middle;';
    html += 'text-align: center;';
    html += '} ';
    html += 'label';
    html += '{';
    html += 'font-family: Calibri;';
    html += 'vertical-align:middle;';
    html += '} ';
    html += '</style>';
    html += '</head>';
    html += '<body>';
    html += '</body>';
    html += '</html>';
    return html;
}
//* Tuner tab *//
//* Tuner tab *//
function tuner(device)
{
    var html = layout();
    html += '<div id="divContainer">';
    html += '<h1>AM/FM TUNER</h1>';
    html += '<table class="formatAVRPanel" >';
    html += '<thead>';
    html += '<tr>';
    //html += '<th colspan="8">TUNER PRESETS</th>';
    html += '</tr>';
    html += '</thead>';
    html += '<tbody id="presetButtons" >';
    html += '</tbody>';
    html += '<tfoot>';
    html += '<tr><td id="statusBarFooter"></td></tr>';
    html += '</tfoot>';
    html += '</table>';
    html += '</div>';
    html += '</body>';
    html += '</html>';
    set_panel_html(html);
    getPresets(device, $('presetButtons'), $('statusBarFooter'));
}

function getPresets(device, presetButtons, statusBarFooter)
{
    new Ajax.Request("../port_3480/data_request",
    {
        method: "get",
        parameters:
        {
            id: "lr_tuner",
            rand: Math.random(),
            output_format: "json"
        },
        onSuccess: function (response)
        {
            //statusBarFooter.innerHTML = '<td colspan="8">Response Received</td>';
            var presetArray = response.responseText.evalJSON()["PRESETS"];
            presetArray.sort(function (a, b)
            {
                return parseInt(a.PRESETNO, 17) - parseInt(b.PRESETNO, 17);
            });
            var j = Object.keys(presetArray).length;
            if (j > 0)
            {
                var x = -1;
                for (var i = 0; i < presetArray.length; i++)
                {
                    var preset = (presetArray[i].PRESETNO);
                    var freq = (presetArray[i].STATION);
                    var xaxis = (((preset.slice(0, 1)).charCodeAt()) - 65);
                    var yaxis = (preset.slice(1) - 1);
                    if (x != (xaxis + 1))
                    {
                        row = presetButtons.insertRow(xaxis);
                    }
                    var presetRow = row.insertCell(yaxis);
                    if (freq < 50000)
                    {
                        var freqPost = "MHz";
                    }
                    else
                    {
                        freqPost = "KHz";
                    }
                    freq = freq / 100;
                    if (isNaN(freq))
                    {
                        freq = "?";
                    }
                    else
                    {
                        freq = freq + freqPost;
                    }
                    presetRow.innerHTML = '<td><input id="presetButton" type="submit" value="' + preset + '" class="btn1" title="Tuner preset ' + freq + '" onclick="tunerPreset(' + device + ',\'TPAN' + preset + '\')"></input></td>';
                    x = presetButtons.rows.length;
                }
                buttonUP = '<td><input id="presetButton" type="submit" value="PRESET UP" class="btn2" title="Next preset up" onclick=tunerPreset(' + device + ',"TPANUP")></input></td>';
                buttonDW = '<td><input id="presetButton" type="submit" value="PRESET DOWN" class="btn2" title="Next preset down" onclick=tunerPreset(' + device + ',"TPANDOWN")></input></td>';
                buttonDS = '<td><input id="presetButton" type="submit" value="PRESET STATUS" class="btn2" title="Next preset down" onclick=tunerPreset(' + device + ',"TPAN?")></input></td>';
                buttonDM = '<td><input id="presetButton" type="submit" value="PRESET MEMORY" class="btn2" title="Next preset down" onclick=tunerPreset(' + device + ',"TPANMEMORY")></input></td>';
                row = presetButtons.insertRow(-1);
                presetRow = row.insertCell(-1);
                presetRow.colSpan = 8;
                presetRow.innerHTML = buttonUP + buttonDW + buttonDS + buttonDM;
                buttonAM = '<td><input id="presetButton" type="submit" value="AM" class="btn2" title="Band set to AM" onclick=tunerPreset(' + device + ',"TMANAM")></input></td>';
                buttonFM = '<td><input id="presetButton" type="submit" value="FM" class="btn2" title="Band set to FM" onclick=tunerPreset(' + device + ',"TMANFM")></input></td>';
                buttonAU = '<td><input id="presetButton" type="submit" value="AUTO" class="btn2" title="Tuner mode set to auto" onclick=tunerPreset(' + device + ',"TMANAUTO")></input></td>';
                buttonMA = '<td><input id="presetButton" type="submit" value="MANUAL" class="btn2" title="Tuner mode set to manual" onclick=tunerPreset(' + device + ',"TMANMANUAL")></input></td>';
                buttonST = '<td><input id="presetButton" type="submit" value="FREQ STATUS" class="btn2" title="Tuner mode set to manual" onclick=tunerPreset(' + device + '"TMAN?")></input></td>';
                buttonFU = '<td><input id="presetButton" type="submit" value="FREQ UP" class="btn2" title="Tuner frequency up" onclick=tunerPreset(' + device + ',"TFANUP")></input></td>';
                buttonFD = '<td><input id="presetButton" type="submit" value="FREQ DOWN" class="btn2" title="Tuner frequency down" onclick=tunerPreset(' + device + ',"TFANDOWN")></input></td>';
                buttonFI = '<td><input id="presetButton" type="submit" value="FREQ DIRECT" class="btn2" title="Tuner frequency down" onclick=tunerPreset(' + device + ',"TFAN")></input></td>';
                buttonFS = '<td><input id="presetButton" type="submit" value="FREQ STATUS" class="btn2" title="Tuner frequency down" onclick=tunerPreset(' + device + ',"TFAN?")></input></td>';
                statusBarFooter.colSpan = 8;
                statusBarFooter.innerHTML = buttonAM + buttonFM + buttonAU + buttonFU + buttonFD + buttonMA + buttonST + buttonFI + buttonFS;
            }
            else
            {
                statusBarFooter.innerHTML = '<td>Completed</td>';
            }
        },
        onFailure: function (response)
        {
            statusBarFooter.innerHTML = '<td colspan="8">Failed To Get Presets</td>';
        }
    });
}

//* Sirius tab *//
//* Sirius tab *//
function sirius(device)
{
    var html = layout();
    html += '<div id="divContainer">';
    html += '<h1>SIRIUS</h1>';
    html += '<table class="formatAVRPanel" >';
    html += '<thead>';
    html += '<tr>';
    //html += '<th colspan="8">XM PRESETS</th>';
    html += '</tr>';
    html += '</thead>';
    html += '<tbody id="presetButtons" >';
    html += '</tbody>';
    html += '<tfoot>';
    html += '<tr><td id="statusBarFooter"></td></tr>';
    html += '</tfoot>';
    html += '</table>';
    html += '</div>';
    html += '</body>';
    html += '</html>';
    set_panel_html(html);
    getXMPresets(device, $('presetButtons'), $('statusBarFooter'));
}

function getXMPresets(device, presetButtons, statusBarFooter)
{
    new Ajax.Request("../port_3480/data_request",
    {
        method: "get",
        parameters:
        {
            id: "lr_xm",
            rand: Math.random(),
            output_format: "json"
        },
        onSuccess: function (response)
        {
            //statusBarFooter.innerHTML = '<td colspan="8">Response Received</td>';
            var presetArray = response.responseText.evalJSON()["PRESETS"];
            presetArray.sort(function (a, b)
            {
                return parseInt(a.PRESETNO, 17) - parseInt(b.PRESETNO, 17);
            });
            var j = Object.keys(presetArray).length;
            if (j > 0)
            {
                var x = -1;
                for (var i = 0; i < presetArray.length; i++)
                {
                    var preset = (presetArray[i].PRESETNO);
                    var freq = (presetArray[i].STATION);
                    var xaxis = (((preset.slice(0, 1)).charCodeAt()) - 65);
                    var yaxis = (preset.slice(1) - 1);
                    if (x != (xaxis + 1))
                    {
                        row = presetButtons.insertRow(xaxis);
                    }
                    var presetRow = row.insertCell(yaxis);

                    presetRow.innerHTML = '<td><input id="presetButton" type="submit" value="' + preset + '" class="btn1" title="XM preset ' + freq + '" onclick="tunerPreset(' + device + ',\'TPXM' + preset + '\')"></input></td>';
                    x = presetButtons.rows.length;
                }
                buttonUP = '<td><input id="presetButton" type="submit" value="PRESET UP" class="btn2" title="Next XM preset up" onclick=tunerPreset(' + device + ',"TPXMUP")></input></td>';
                buttonDW = '<td><input id="presetButton" type="submit" value="PRESET DOWN" class="btn2" title="Next XM preset down" onclick=tunerPreset(' + device + ',"TPXMDOWN")></input></td>';
                buttonDS = '<td><input id="presetButton" type="submit" value="PRESET STATUS" class="btn2" title="Return TPXM Status" onclick=tunerPreset(' + device + ',"TPXM?")></input></td>';
                buttonDM = '<td><input id="presetButton" type="submit" value="PRESET MEMORY" class="btn2" title="XM PRESET MEMORY" onclick=tunerPreset(' + device + ',"TPXMMEM")></input></td>';
                row = presetButtons.insertRow(-1);
                presetRow = row.insertCell(-1);
                presetRow.colSpan = 8;
                presetRow.innerHTML = buttonUP + buttonDW + buttonDS + buttonDM;
                buttonFU = '<td><input id="presetButton" type="submit" value="CHAN UP" class="btn2" title="XM Channel UP" onclick=tunerPreset(' + device + ',"TFXMUP")></input></td>';
                buttonFD = '<td><input id="presetButton" type="submit" value="CHAN DOWN" class="btn2" title="XM Channel DOWN" onclick=tunerPreset(' + device + ',"TFXMDOWN")></input></td>';
                buttonFI = '<td><input id="presetButton" type="submit" value="CHAN DIRECT" class="btn2" title="XM Channel DIRECT" onclick=tunerPreset(' + device + ',"TFXM")></input></td>';
                buttonFS = '<td><input id="presetButton" type="submit" value="CHAN STATUS" class="btn2" title="XM Channel STATUS" onclick=tunerPreset(' + device + ',"TFXM?")></input></td>';
                statusBarFooter.colSpan = 8;
                statusBarFooter.innerHTML = buttonFU + buttonFD + buttonFI + buttonFS;
            }
            else
            {
                statusBarFooter.innerHTML = '<td>Completed</td>';
            }
        },
        onFailure: function (response)
        {
            statusBarFooter.innerHTML = '<td colspan="8">Failed To Get Presets</td>';
        }
    });
}

function tunerPreset(device, command)
{
    new Ajax.Request("../port_3480/data_request",
    {
        method: "get",
        parameters:
        {
            id: "lu_action",
            serviceId: DEN_DID,
            action: "SendCommand",
            DeviceNum: device,
            Command: command,
            output_format: "json"
        },
        onSuccess: function (response) {},
        onFailure: function () {}
    });
}
