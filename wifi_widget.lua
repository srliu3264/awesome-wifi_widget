local wibox = require("wibox")
local awful = require("awful")
local lgi = require("lgi")
local gears = require("gears")

local NM = nil
local status, result = pcall(function()
	return lgi.require("NM", "1.0")
end)
if status then
	NM = result
end
local icon_font = "Nerd Font 14"

local icon_widget = wibox.widget({
	widget = wibox.widget.textbox,
	font = icon_font,
	align = "center",
	valign = "center",
	forced_width = 90, -- Reserve space for icon WARN: too small will make it show as ...
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

local wifi_tooltip = awful.tooltip({
	objects = { wifi_widget },
	mode = "outside",
	preferred_positions = { "bottom", "left" },
})

-- Helper: Convert signal strength (0-100) to Icon
local function get_wifi_glyph(strength)
	if strength >= 75 then
		return "  "
	elseif strength >= 50 then
		return "  "
	elseif strength >= 25 then
		return " 󰤠 "
	else
		return " 󰖪 "
	end
end

-- Helper: Convert signal strength to Color
local function get_color(strength, is_connected)
	if not is_connected then
		return "#ff6c6b"
	end

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
	local color = "#ff6c6b"
	local strength = 0
	local ip_address = "N/A"
	local tooltip_txt = "Disconnected"

	local active_conn = client.primary_connection

	if active_conn then
		local conn_type = active_conn:get_connection_type()
		local ip4_config = active_conn:get_ip4_config()
		if ip4_config then
			local addrs = ip4_config:get_addresses()
			if addrs and #addrs > 0 then
				ip_address = addrs[1]:get_address()
			end
		end
		if conn_type == "802-11-wireless" then
			local device = active_conn.devices and active_conn.devices[1]
			if device and device.active_access_point then
				local ap = device.active_access_point
				local ssid_bytes = ap:get_ssid()

				text = ssid_to_string(ssid_bytes)
				strength = ap.strength
				glyph = get_wifi_glyph(strength)
				color = get_color(strength, true)
				tooltip_txt = string.format("SSID: %s\nStrength: %d%%\nIP: %s", text, strength, ip_address)
			end
		else
			glyph = "󰈀 "
			text = "Eth"
			color = "#98be65"
			tooltip_txt = string.format("Ethernet Connected\nIP: %s", ip_address)
		end
		-- else
		-- 	color = "#ff6c6b"
	end

	icon_widget.markup = string.format("<span foreground='%s'>%s</span>", color, glyph)
	text_widget.markup = string.format("<span foreground='%s'>%s</span>", color, text)
	wifi_tooltip:set_text(tooltip_txt)
end

local function init()
	if not NM then
		text_widget.text = "No NM"
		return wifi_widget
	end

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
