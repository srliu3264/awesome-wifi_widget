# awesome-wifi_widget
Using dbus to efficiently updating wifi status.

This uses same idea as awesome-power_widget. Here is my [forked version](https://github.com/srliu3264/awesome-power_widget),of [stefano-m's original](https://github.com/stefano-m/awesome-power_widget), which further configured text, icons, and some other new features.

After installing awesome-power_widget, one can simply git clone this repo, and add path in your `rc.lua` file of awesomeWM, i.e. `local wifi = require("wifi_widget")`, and then add `wifi` to `s.mywibox:setup` next to the battery power icon.

For example, one can consult and mimic [my awesome configuration](https://github.com/srliu3264/awesome).
