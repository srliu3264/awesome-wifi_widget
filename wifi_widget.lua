local wibox = require("wibox")
local awful = require("awful")
local lgi = require("lgi")

-- Try to load NetworkManager (NM). Safely fail if not present.
local NM = nil
local status, result = pcall(function()
	return lgi.require("NM", "1.0")
end)
if status then
	NM = result
end
-- CONFIGURATION: Font and Icons
local icon_font = "Nerd Font 14"

local icon_widget = wibox.widget({
	widget = wibox.widget.textbox,
	font = icon_font,
	align = "center",
	valign = "center",
	forced_width = 90, -- Reserve space for icon
})

local text_widget = wibox.widget({
	widget = wibox.widget.textbox,
	font = "Sans 10",
})

local wifi_widget = wibox.widget({
	layout = wibox.layout.fixed.horizontal,
	spacing = 8,
	icon_widget,
	text_widget,
})

-- Helper: Convert signal strength (0-100) to Icon
local function get_wifi_glyph(strength)
	if strength >= 75 then
		return "  " -- High (f1eb)
	elseif strength >= 50 then
		return "  " -- Medium (f6aa)
	elseif strength >= 25 then
		return " 󰤠 " -- Low (f6aa)
	else
		return " 󰖪 "
	end -- Very Low/None (f6ac)
end

-- Helper: Convert signal strength to Color
local function get_color(strength, is_connected)
	if not is_connected then
		return "#ff6c6b"
	end -- Red

	if strength >= 75 then
		return "#98be65"
	elseif strength >= 50 then
		return "#99ccff"
	else
		return "#ff6c6b"
	end
end

local function ssid_to_string(ssid_bytes)
	if not ssid_bytes then
		return "???"
	end
	local text = ssid_bytes:get_data()
	return text or "Hidden"
end

local function update_wifi(client)
	local glyph = "󰖪 "
	local text = "Offline"
	local color = "#51afef"
	local strength = 0
	local is_connected = false

	local active_conn = client.primary_connection

	if active_conn then
		local dev = active_conn.specific_object_path -- Sometimes implies device, but let's look at devices

		local conn_type = active_conn:get_connection_type()

		if conn_type == "802-11-wireless" then
			is_connected = true
			local device = active_conn.devices and active_conn.devices[1]
			if device and device.active_access_point then
				local ap = device.active_access_point
				local ssid_bytes = ap:get_ssid()

				text = ssid_to_string(ssid_bytes)
				strength = ap.strength
				glyph = get_wifi_glyph(strength)
				color = get_color(strength, true)
			end
		else
			glyph = "󰈀 " -- Ethernet icon
			text = "Eth"
			color = "#98be65"
		end
	else
		color = "#ff6c6b"
	end

	icon_widget.markup = string.format("<span foreground='%s'>%s</span>", color, glyph)
	text_widget.markup = string.format("<span foreground='%s'>%s</span>", color, text)
end

local function init()
	if not NM then
		text_widget.text = "No NM"
		return wifi_widget
	end

	-- Initialize the NetworkManager Client
	local client = NM.Client.new()

	if not client then
		text_widget.text = "Err"
		return wifi_widget
	end

	update_wifi(client)

	client.on_notify = function(c, spec)
		if spec.name == "primary-connection" or spec.name == "state" or spec.name == "activating-connection" then
			update_wifi(c)
		end
	end

	local gears_timer = require("gears").timer
	gears_timer.start_new(5, function()
		update_wifi(client)
		return true
	end)

	return wifi_widget
end

return init()
