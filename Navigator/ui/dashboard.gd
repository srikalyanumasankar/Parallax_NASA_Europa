class_name Dashboard
extends Control

## PARALLAX — the main navigation dashboard: navigation-data column, central
## orbital display and the spacecraft systems column. The navigation readouts
## are driven live by the flight simulation model (OrbitalSimulation).

var _readouts: Dictionary = {}
var _elapsed_label: Label


func _ready() -> void:
	_build()


func _build() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 10)
	add_child(row)

	_build_nav_data(row)
	_build_map(row)
	_build_systems(row)


func _build_nav_data(row: HBoxContainer) -> void:
	var frame: PanelFrame = PanelFrame.new("NAVIGATION DATA", ParallaxPalette.CYAN)
	frame.custom_minimum_size.x = 296
	frame.size_flags_horizontal = Control.SIZE_FILL
	row.add_child(frame)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.get_content().add_child(scroll)

	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)

	var awaiting: Label = ParallaxPalette.caption("SIM DRIVEN · KINEMATIC MODEL")
	awaiting.add_theme_color_override("font_color", ParallaxPalette.CYAN)
	col.add_child(awaiting)

	var specs: Array = [
		["position", "Position", true],
		["dj", "Distance from Jupiter", false],
		["de", "Distance from Europa", true],
		["alt", "Altitude above Europa", true],
		["vel", "Velocity", true],
		["acc", "Acceleration", true],
		["att", "Attitude", false],
		["incl", "Orbital Inclination", false],
		["period", "Orbital Period", false],
		["nav", "Navigation Accuracy", true],
	]
	for spec: Array in specs:
		var readout: TelemetryReadout = TelemetryReadout.new(str(spec[1]), "--", "")
		readout.show_spark = bool(spec[2])
		col.add_child(readout)
		_readouts[str(spec[0])] = readout

	var sim: OrbitalSimulation = OrbitalSimulation.active()
	if sim != null:
		sim.telemetry_updated.connect(_on_telemetry)
		_on_telemetry(sim.telemetry())


func _build_sim_controls() -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.add_child(ParallaxPalette.caption("SIMULATION CLOCK"))

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	box.add_child(row)
	var rates: Array = [[0.0, "II"], [1.0, "1x"], [10.0, "10x"], [100.0, "100x"], [1000.0, "1k"]]
	for rate: Array in rates:
		var b: Button = _small_button(str(rate[1]))
		var rate_value: float = float(rate[0])
		b.pressed.connect(func() -> void:
			var s: OrbitalSimulation = OrbitalSimulation.active()
			if s != null:
				s.set_time_scale(rate_value))
		row.add_child(b)

	_elapsed_label = ParallaxPalette.caption("T+ 000d 00h 00m")
	_elapsed_label.add_theme_color_override("font_color", ParallaxPalette.CYAN_SOFT)
	box.add_child(_elapsed_label)

	var burn: Button = _small_button("DEV — PROGRADE BURN +10 m/s")
	burn.pressed.connect(func() -> void:
		var s: OrbitalSimulation = OrbitalSimulation.active()
		if s != null:
			s.apply_manoeuvre(10.0))
	box.add_child(burn)
	return box


func _small_button(text: String) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = 22.0
	b.add_theme_font_size_override("font_size", ParallaxPalette.F_SMALL)
	b.add_theme_stylebox_override("normal", ParallaxPalette.panel_style(Color(0.05, 0.10, 0.17, 0.85), ParallaxPalette.BORDER, 2, 1))
	b.add_theme_stylebox_override("hover", ParallaxPalette.panel_style(Color(0.07, 0.15, 0.22, 0.9), ParallaxPalette.BORDER_BRIGHT, 2, 1))
	b.add_theme_stylebox_override("pressed", ParallaxPalette.panel_style(Color(0.10, 0.30, 0.42, 0.9), ParallaxPalette.CYAN, 2, 1))
	b.add_theme_color_override("font_color", ParallaxPalette.TEXT_DIM)
	b.add_theme_color_override("font_hover_color", ParallaxPalette.CYAN_SOFT)
	return b


func _on_telemetry(snap: Dictionary) -> void:
	if _readouts.is_empty():
		return
	var pos: Vector3 = snap["position"]
	_setv("position", "%s / %s km" % [ParallaxFormat.thousands(pos.x), ParallaxFormat.thousands(pos.y)])
	_setv("dj", "%s km" % ParallaxFormat.thousands(snap["distance_jupiter_km"]))
	_setv("de", "%s km" % ParallaxFormat.thousands(snap["distance_europa_km"]))
	_setv("alt", "%s km" % String.num(snap["altitude_km"], 0))
	_setv("vel", "%s km/s" % String.num(snap["speed_kms"], 3))
	_setv("acc", "%s m/s²" % String.num(snap["accel_ms2"], 2))
	_setv("att", "%s / %s / %s°" % [String.num(snap["pitch_deg"], 1), String.num(snap["yaw_deg"], 1), String.num(snap["roll_deg"], 1)])
	_setv("incl", "%s°" % String.num(snap["inclination_deg"], 1))
	_setv("period", _format_period(float(snap["period_s"])))
	_setv("nav", "%s %%" % String.num(snap["nav_accuracy"], 1))

	var sim: OrbitalSimulation = OrbitalSimulation.active()
	if sim != null:
		_feed_spark("vel", sim.channel("speed"))
		_feed_spark("acc", sim.channel("accel"))
		_feed_spark("alt", sim.channel("altitude"))
		_feed_spark("nav", sim.channel("accuracy"))

	if _elapsed_label != null:
		_elapsed_label.text = "MET %s   T+%s" % [ParallaxFormat.met(float(snap["mission_days"])), _format_elapsed(float(snap["elapsed_s"]))]


func _setv(key: String, text: String) -> void:
	var r: TelemetryReadout = _readouts.get(key)
	if r != null:
		r.set_value(text)


func _feed_spark(key: String, values: PackedFloat32Array) -> void:
	var r: TelemetryReadout = _readouts.get(key)
	if r != null and r.spark != null:
		r.spark.set_values(values)


func _format_period(seconds: float) -> String:
	var h: int = int(floor(seconds / 3600.0))
	var m: int = int(floor(fmod(seconds, 3600.0) / 60.0))
	return "%dh %02dm" % [h, m]


func _format_elapsed(seconds: float) -> String:
	var d: int = int(floor(seconds / 86400.0))
	var h: int = int(floor(fmod(seconds, 86400.0) / 3600.0))
	var m: int = int(floor(fmod(seconds, 3600.0) / 60.0))
	return "%03dd %02dh %02dm" % [d, h, m]


func _build_map(row: HBoxContainer) -> void:
	var frame: PanelFrame = PanelFrame.new("ORBITAL MAP", ParallaxPalette.BLUE)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.set_hint("SCHEMATIC · REAL DATA IN PHASE 3")
	row.add_child(frame)

	var holder: Control = Control.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	frame.get_content().add_child(holder)

	var map: OrbitalMap = OrbitalMap.new()
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(map)

	# Overlay toolbar (top-right)
	var bar: HBoxContainer = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	bar.anchor_left = 1.0
	bar.anchor_right = 1.0
	bar.offset_left = -368.0
	bar.offset_right = -8.0
	bar.offset_top = 8.0
	bar.offset_bottom = 34.0
	bar.alignment = BoxContainer.ALIGNMENT_END
	bar.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.add_child(bar)

	var toggles: Array = [["ORBITS", "show_orbits"], ["LABELS", "show_labels"], ["TRAJECTORY", "show_trajectory"], ["GRID", "show_grid"]]
	for t: Array in toggles:
		var prop: String = str(t[1])
		var toggle: Button = _map_button(str(t[0]), bool(map.get(prop)))
		toggle.toggled.connect(func(on: bool) -> void:
			map.set(prop, on)
			map.queue_redraw())
		bar.add_child(toggle)
	var fit: Button = _map_button("FIT", false)
	fit.toggle_mode = false
	fit.pressed.connect(func() -> void: map.fit_view())
	bar.add_child(fit)

	# Overlay info panel (top-left, below the readouts)
	var info: OrbitalInfoPanel = OrbitalInfoPanel.new()
	info.offset_left = 8.0
	info.offset_right = 236.0
	info.offset_top = 44.0
	info.offset_bottom = 252.0
	holder.add_child(info)
	info.show_body(OrbitalSchematic.body(map.selected_id))
	map.selection_changed.connect(func(id: String) -> void:
		info.show_body(OrbitalSchematic.body(id)))


func _map_button(text: String, pressed: bool) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_pressed = pressed
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = 26.0
	b.add_theme_font_size_override("font_size", ParallaxPalette.F_SMALL)
	b.add_theme_stylebox_override("normal", ParallaxPalette.panel_style(Color(0.05, 0.10, 0.17, 0.85), ParallaxPalette.BORDER, 2, 1))
	b.add_theme_stylebox_override("hover", ParallaxPalette.panel_style(Color(0.07, 0.15, 0.22, 0.9), ParallaxPalette.BORDER_BRIGHT, 2, 1))
	b.add_theme_stylebox_override("pressed", ParallaxPalette.panel_style(Color(0.10, 0.30, 0.42, 0.9), ParallaxPalette.CYAN, 2, 1))
	b.add_theme_color_override("font_color", ParallaxPalette.TEXT_DIM)
	b.add_theme_color_override("font_hover_color", ParallaxPalette.CYAN_SOFT)
	b.add_theme_color_override("font_pressed_color", ParallaxPalette.CYAN_SOFT)
	return b


func _build_systems(row: HBoxContainer) -> void:
	var frame: PanelFrame = PanelFrame.new("SPACECRAFT SYSTEMS", ParallaxPalette.AMBER)
	frame.custom_minimum_size.x = 320
	frame.set_hint("SUMMARY · SEE SYSTEMS SECTION")
	row.add_child(frame)

	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	frame.get_content().add_child(col)

	var meters: Array = [
		["Propulsion — Fuel Level", 0.74, "74 %", ParallaxPalette.CYAN, false],
		["Power — Solar Array", 0.92, "92 %", ParallaxPalette.CYAN, false],
		["Reactor", 1.0, "ACTIVE", ParallaxPalette.GREEN, false],
		["Thermal Regulation", 0.62, "295 K", ParallaxPalette.CYAN, false],
		["Communications — Data Rate", 0.50, "50 Mbps", ParallaxPalette.CYAN, false],
		["Structural Integrity", 0.99, "99 %", ParallaxPalette.GREEN, false],
		["Radiation Dose", 0.12, "0.1 mSv/h", ParallaxPalette.CYAN, false],
	]
	for m: Array in meters:
		var meter: BarMeter = BarMeter.new(str(m[0]), float(m[1]))
		meter.set_state(float(m[1]), str(m[2]), m[3], bool(m[4]))
		col.add_child(meter)