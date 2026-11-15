class_name ParallaxFormat
extends RefCounted

## Small formatting helpers so numbers read like real spacecraft telemetry.


static func met(days: float) -> String:
	var d: int = int(floor(days))
	var hours: int = int((days - float(d)) * 24.0)
	var minutes: int = int(((days - float(d)) * 24.0 - float(hours)) * 60.0)
	if d >= 365:
		var years: int = int(floor(float(d) / 365.0))
		var rem_days: int = d % 365
		return "Y%d %03dd %02dh %02dm" % [years, rem_days, hours, minutes]
	return "%03dd %02dh %02dm" % [d, hours, minutes]


static func km(value: float) -> String:
	return "%s km" % thousands(value)


static func thousands(value: float) -> String:
	var whole: int = int(round(abs(value)))
	var s: String = str(whole)
	var out: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return (("-" if value < 0.0 else "") + out)


static func fixed(value: float, digits: int = 2) -> String:
	return String.num(value, digits)