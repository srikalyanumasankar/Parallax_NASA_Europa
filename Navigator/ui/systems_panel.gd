class_name SystemsPanel
extends Control

## PARALLAX — the SYSTEMS section: live subsystem meters, status indicators and
## the orbital spacecraft systems verification. Values come from the shared
## SystemsSimulation model; the verification records the active mission's
## maintenance objectives (never a gated manoeuvre objective).

var _meters: Dictionary = {}
var _pills: Dictionary = {}
var _result: Label


func _ready() -> void:
	_build()
	var sys: SystemsSimulation = SystemsSimulation.active()
	if sys != null:
		sys.updated.connect(_on_updated)
		_on_updated(sys.state())


func _build() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 10)
	add_child(row)

	_build_meters(row)
	_build_status(row)
	_build_verification(row)


func _build_meters(row: HBoxContainer) -> void:
	var frame: PanelFrame = PanelFrame.new("SUBSYSTEM METERS", ParallaxPalette.AMBER)
	frame.custom_minimum_size.x = 380
	frame.set_hint("LIVE MODEL")
	row.add_child(frame)

	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	frame.get_content().add_child(col)

	for def in SystemsDefinitions.SUBSYSTEMS:
		var id: String = str(def["id"])
		var meter: BarMeter = BarMeter.new(str(def.get("label", id)), 0.0)
		col.add_child(meter)
		_meters[id] = meter


func _build_status(row: HBoxContainer) -> void:
	var frame: PanelFrame = PanelFrame.new("SUBSYSTEM STATUS", ParallaxPalette.CYAN)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.set_hint("STATUS INDICATORS")
	row.add_child(frame)

	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	frame.get_content().add_child(col)

	for def in SystemsDefinitions.SUBSYSTEMS:
		var id: String = str(def["id"])
		var pill: StatusPill = StatusPill.new(str(def.get("name", id)), "—", ParallaxPalette.TEXT_DIM)
		col.add_child(pill)
		_pills[id] = pill

	var note: Label = ParallaxPalette.caption("Thresholds are the game's own simulation limits for its fictional spacecraft — not engineering or NASA data. Non-nominal states raise a mission alert.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(note)


func _build_verification(row: HBoxContainer) -> void:
	var frame: PanelFrame = PanelFrame.new("SYSTEMS VERIFICATION", ParallaxPalette.GREEN)
	frame.custom_minimum_size.x = 272
	row.add_child(frame)

	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	frame.get_content().add_child(col)

	var desc: Label = ParallaxPalette.label("Run the orbital spacecraft systems check. It records the active mission's maintenance objectives that are not part of the manoeuvre sequence.", ParallaxPalette.F_LABEL + 1, ParallaxPalette.TEXT_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 244
	col.add_child(desc)

	var btn: Button = Button.new()
	btn.text = "RUN SYSTEMS VERIFICATION"
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size.y = 38.0
	btn.add_theme_font_size_override("font_size", ParallaxPalette.F_LABEL + 1)
	btn.pressed.connect(_on_verify)
	col.add_child(btn)

	_result = ParallaxPalette.label("", ParallaxPalette.F_LABEL + 1, ParallaxPalette.TEXT)
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result.custom_minimum_size.x = 244
	col.add_child(_result)


func _on_verify() -> void:
	var sys: SystemsSimulation = SystemsSimulation.active()
	if sys == null:
		return
	var res: Dictionary = sys.verify()
	var ok: bool = bool(res.get("ok", false))
	var lines: Array = []
	if ok:
		lines.append("ALL SUBSYSTEMS NOMINAL.")
	else:
		lines.append("ISSUES: " + ", ".join(res.get("issues", [])))

	var recorded: Array = SectionObjectives.record(SectionObjectives.SYSTEMS)
	if recorded.is_empty():
		lines.append("No objectives recorded — start a mission first, or they are already done.")
	else:
		lines.append("RECORDED: " + ", ".join(recorded))

	_result.text = "\n".join(lines)
	_result.add_theme_color_override("font_color", ParallaxPalette.GREEN if ok else ParallaxPalette.AMBER)
	InterfaceSfx.play(self, "confirm" if ok else "warning")
	ParallaxMotion.flash(_result, ParallaxPalette.CYAN if ok else ParallaxPalette.AMBER, 0.5)


func _on_updated(state: Dictionary) -> void:
	var sys: SystemsSimulation = SystemsSimulation.active()
	if sys == null:
		return
	for def in SystemsDefinitions.SUBSYSTEMS:
		var id: String = str(def["id"])
		var st: String = sys.status(id)
		var col: Color = _status_color(st)
		var meter: BarMeter = _meters.get(id)
		if meter != null:
			meter.set_state(sys.normalised(id), _value_text(id, state), col, st != "NOMINAL")
		var pill: StatusPill = _pills.get(id)
		if pill != null:
			pill.set_state(str(def.get("name", id)), st, col)


func _status_color(st: String) -> Color:
	match st:
		"NOMINAL":
			return ParallaxPalette.GREEN
		"LOW", "HIGH":
			return ParallaxPalette.AMBER
		_:
			return ParallaxPalette.TEXT_DIM


func _value_text(id: String, state: Dictionary) -> String:
	match id:
		"propulsion", "power", "reactor", "structure":
			return "%d %%" % int(round(float(state.get(id, 0.0)) * 100.0))
		"thermal":
			return "%d K" % int(round(float(state.get("thermal", 0.0))))
		"comms":
			return "%.0f Mbps" % float(state.get("comms", 0.0))
		"radiation":
			return "%.2f mSv/h" % float(state.get("radiation", 0.0))
		_:
			return "—"