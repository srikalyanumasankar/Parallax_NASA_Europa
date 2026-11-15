class_name TelemetryPanel
extends Control

## PARALLAX — the TELEMETRY section: live flight readouts, historical telemetry
## graphs and the flight-simulation clock, all driven by the shared
## OrbitalSimulation model. The "record telemetry check" action satisfies the
## active mission's navigation observation objectives (never a gated manoeuvre
## objective — see SectionObjectives).

## key, label, unit, show_sparkline
const READOUTS: Array = [
	["position", "Position (Europa frame)", "km", true],
	["orbit_radius", "Orbital radius", "km", true],
	["altitude", "Altitude above Europa", "km", true],
	["speed", "Orbital velocity", "km/s", true],
	["angular", "Angular rate", "°/s", false],
	["accel", "Centripetal acceleration", "m/s²", true],
	["attitude", "Attitude  P / Y / R", "°", false],
	["inclination", "Orbital inclination", "°", false],
	["period", "Orbital period", "h m", false],
	["distance_europa", "Distance from Europa", "km", false],
	["distance_jupiter", "Distance from Jupiter", "km", false],
	["nav", "Navigation accuracy", "%", true],
]

## graph key, title, unit, sim channel
const GRAPHS: Array = [
	["speed", "ORBITAL VELOCITY", "km/s", "speed"],
	["altitude", "ALTITUDE", "km", "altitude"],
	["accel", "ACCELERATION", "m/s²", "accel"],
	["accuracy", "NAV ACCURACY", "%", "accuracy"],
]

var _readouts: Dictionary = {}
var _graphs: Dictionary = {}
var _elapsed: Label
var _result: Label


func _ready() -> void:
	_build()
	var sim: OrbitalSimulation = OrbitalSimulation.active()
	if sim != null:
		sim.telemetry_updated.connect(_on_telemetry)
		_on_telemetry(sim.telemetry())


func _build() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 10)
	add_child(row)

	_build_readouts(row)
	_build_graphs(row)
	_build_clock(row)


func _build_readouts(row: HBoxContainer) -> void:
	var frame: PanelFrame = PanelFrame.new("LIVE TELEMETRY", ParallaxPalette.CYAN)
	frame.custom_minimum_size.x = 312
	frame.set_hint("SIM DRIVEN")
	row.add_child(frame)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.get_content().add_child(scroll)

	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)

	for spec: Array in READOUTS:
		var key: String = str(spec[0])
		var readout: TelemetryReadout = TelemetryReadout.new(str(spec[1]), "--", str(spec[2]))
		readout.show_spark = bool(spec[3])
		readout.custom_minimum_size.y = 48.0
		col.add_child(readout)
		_readouts[key] = readout


func _build_graphs(row: HBoxContainer) -> void:
	var frame: PanelFrame = PanelFrame.new("TELEMETRY HISTORY", ParallaxPalette.BLUE)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.set_hint("LAST %d SAMPLES" % OrbitalSimulation.HISTORY_MAX)
	row.add_child(frame)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.get_content().add_child(scroll)

	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)

	for spec: Array in GRAPHS:
		var key: String = str(spec[0])
		var graph: TelemetryGraph = TelemetryGraph.new(str(spec[1]), str(spec[2]))
		graph.custom_minimum_size = Vector2(0, 104)
		col.add_child(graph)
		_graphs[key] = graph


func _build_clock(row: HBoxContainer) -> void:
	var frame: PanelFrame = PanelFrame.new("FLIGHT SIMULATION", ParallaxPalette.AMBER)
	frame.custom_minimum_size.x = 252
	row.add_child(frame)

	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	frame.get_content().add_child(col)

	col.add_child(ParallaxPalette.caption("SIMULATION CLOCK"))
	var rates: HBoxContainer = HBoxContainer.new()
	rates.add_theme_constant_override("separation", 3)
	col.add_child(rates)
	for rate: Array in [[0.0, "II"], [1.0, "1x"], [10.0, "10x"], [100.0, "100x"], [1000.0, "1k"]]:
		var b: Button = _small_button(str(rate[1]))
		var rate_value: float = float(rate[0])
		b.pressed.connect(func() -> void:
			var s: OrbitalSimulation = OrbitalSimulation.active()
			if s != null:
				s.set_time_scale(rate_value)
			InterfaceSfx.play(self, "click"))
		rates.add_child(b)

	_elapsed = ParallaxPalette.label("MET —", ParallaxPalette.F_LABEL + 1, ParallaxPalette.CYAN_SOFT)
	col.add_child(_elapsed)

	var burn: Button = _small_button("DEV — PROGRADE BURN +10 m/s")
	burn.pressed.connect(func() -> void:
		var s: OrbitalSimulation = OrbitalSimulation.active()
		if s != null:
			s.apply_manoeuvre(10.0)
			InterfaceSfx.play(self, "relay"))
	col.add_child(burn)

	col.add_child(_rule())
	col.add_child(ParallaxPalette.caption("MISSION DECISION"))
	var record: Button = _small_button("RECORD TELEMETRY CHECK")
	record.pressed.connect(_on_record)
	col.add_child(record)

	_result = ParallaxPalette.label("", ParallaxPalette.F_LABEL, ParallaxPalette.TEXT)
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result.custom_minimum_size.x = 220
	col.add_child(_result)


func _on_record() -> void:
	var recorded: Array = SectionObjectives.record(SectionObjectives.TELEMETRY)
	if recorded.is_empty():
		_result.text = "No applicable objectives — start a mission in the MISSION section first."
		_result.add_theme_color_override("font_color", ParallaxPalette.TEXT_DIM)
		InterfaceSfx.play(self, "relay")
	else:
		_result.text = "RECORDED: " + ", ".join(recorded)
		_result.add_theme_color_override("font_color", ParallaxPalette.GREEN)
		InterfaceSfx.play(self, "confirm")
		ParallaxMotion.flash(_result, ParallaxPalette.CYAN, 0.5)


func _on_telemetry(snap: Dictionary) -> void:
	if _readouts.is_empty():
		return
	var pos: Vector3 = snap["position"]
	var radius: float = float(snap["orbit_radius_km"])
	var speed: float = float(snap["speed_kms"])
	var omega_deg: float = rad_to_deg(speed / maxf(radius, 1.0))

	_setv("position", "%s / %s" % [ParallaxFormat.thousands(pos.x), ParallaxFormat.thousands(pos.y)])
	_setv("orbit_radius", "%s" % ParallaxFormat.thousands(radius))
	_setv("altitude", "%s" % String.num(float(snap["altitude_km"]), 0))
	_setv("speed", "%s" % String.num(speed, 3))
	_setv("angular", "%s" % String.num(omega_deg, 4))
	_setv("accel", "%s" % String.num(float(snap["accel_ms2"]), 2))
	_setv("attitude", "%s / %s / %s" % [String.num(float(snap["pitch_deg"]), 1), String.num(float(snap["yaw_deg"]), 1), String.num(float(snap["roll_deg"]), 1)])
	_setv("inclination", "%s" % String.num(float(snap["inclination_deg"]), 1))
	_setv("period", _format_period(float(snap["period_s"])))
	_setv("distance_europa", "%s" % ParallaxFormat.thousands(float(snap["distance_europa_km"])))
	_setv("distance_jupiter", "%s" % ParallaxFormat.thousands(float(snap["distance_jupiter_km"])))
	_setv("nav", "%s" % String.num(float(snap["nav_accuracy"]), 1))

	var sim: OrbitalSimulation = OrbitalSimulation.active()
	if sim != null:
		_feed("speed", sim.channel("speed"))
		_feed("altitude", sim.channel("altitude"))
		_feed("accel", sim.channel("accel"))
		_feed("accuracy", sim.channel("accuracy"))

	if _elapsed != null:
		_elapsed.text = "MET %s   ·   RATE %sx" % [ParallaxFormat.met(float(snap["mission_days"])), String.num(float(snap["time_scale"]), 0)]


func _setv(key: String, text: String) -> void:
	var r: TelemetryReadout = _readouts.get(key)
	if r != null:
		r.set_value(text)


func _feed(key: String, values: PackedFloat32Array) -> void:
	var g: TelemetryGraph = _graphs.get(key)
	if g != null:
		g.set_values(values)


func _small_button(text: String) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = 24.0
	b.add_theme_font_size_override("font_size", ParallaxPalette.F_SMALL)
	b.add_theme_stylebox_override("normal", ParallaxPalette.panel_style(Color(0.05, 0.10, 0.17, 0.85), ParallaxPalette.BORDER, 2, 1))
	b.add_theme_stylebox_override("hover", ParallaxPalette.panel_style(Color(0.07, 0.15, 0.22, 0.9), ParallaxPalette.BORDER_BRIGHT, 2, 1))
	b.add_theme_stylebox_override("pressed", ParallaxPalette.panel_style(Color(0.10, 0.30, 0.42, 0.9), ParallaxPalette.CYAN, 2, 1))
	b.add_theme_color_override("font_color", ParallaxPalette.TEXT_DIM)
	b.add_theme_color_override("font_hover_color", ParallaxPalette.CYAN_SOFT)
	return b


func _format_period(seconds: float) -> String:
	var h: int = int(floor(seconds / 3600.0))
	var m: int = int(floor(fmod(seconds, 3600.0) / 60.0))
	return "%dh %02dm" % [h, m]


func _rule() -> Control:
	var line: ColorRect = ColorRect.new()
	line.color = ParallaxPalette.BORDER
	line.custom_minimum_size.y = 1
	return line