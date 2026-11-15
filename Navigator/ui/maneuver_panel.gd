class_name ManeuverPanel
extends Control

## PARALLAX — the manoeuvre panel: configure an operation, see the predicted
## outcome, confirm, execute against the simulation, then verify the result.
## Every execution changes the simulation and records the mission objective.

var _col: VBoxContainer
var _header: Label
var _built_mission: String = ""
var _cards: Dictionary = {}


func _ready() -> void:
	if MissionBus != null:
		MissionBus.progression_changed.connect(_on_progress)
	if MissionState != null:
		MissionState.changed.connect(_on_progress)
	_build()
	_rebuild()


func _build() -> void:
	var frame: PanelFrame = PanelFrame.new("MANOEUVRES", ParallaxPalette.AMBER)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.set_hint("CONFIGURE → CONFIRM → EXECUTE → VERIFY")
	add_child(frame)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.get_content().add_child(scroll)

	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 8)
	_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_col)

	_header = ParallaxPalette.label("", ParallaxPalette.F_HEAD, ParallaxPalette.CYAN_SOFT)
	_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _on_progress() -> void:
	if MissionState.active_mission != _built_mission:
		_rebuild()
	else:
		_update_header()


func _rebuild() -> void:
	_built_mission = MissionState.active_mission
	_cards.clear()
	if _header.get_parent() != null:
		_header.get_parent().remove_child(_header)
	for c in _col.get_children():
		c.queue_free()
	_col.add_child(_header)
	_update_header()

	if _built_mission == "":
		var hint: Label = ParallaxPalette.label("NO ACTIVE MISSION — begin a mission in the MISSION section, then return here to configure its operations.", ParallaxPalette.F_HEAD, ParallaxPalette.TEXT_DIM)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_col.add_child(hint)
		return

	var ops: Array = ManeuverDefinitions.for_mission(_built_mission)
	if ops.is_empty():
		var none: Label = ParallaxPalette.label("No navigation operations are defined for this mission.", ParallaxPalette.F_HEAD, ParallaxPalette.TEXT_DIM)
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_col.add_child(none)
		return
	for op in ops:
		_col.add_child(_build_card(op))


func _update_header() -> void:
	if _header == null:
		return
	if _built_mission == "":
		_header.text = "MANOEUVER CONTROL"
		return
	var def: Dictionary = MissionDefinitions.get_mission(_built_mission)
	_header.text = "%s   ·   OBJECTIVES %d / %d" % [
		str(def.get("title", _built_mission)),
		MissionState.objectives_done_count(_built_mission),
		MissionState.required_objective_count(_built_mission),
	]


func _build_card(op: Dictionary) -> Control:
	var card: PanelFrame = PanelFrame.new(str(op.get("name", "OPERATION")), ParallaxPalette.CYAN)
	card.set_hint("REQUIRES CONFIRMATION" if bool(op.get("confirm", false)) else "DIRECT")
	card.custom_minimum_size.x = 0.0

	var body: VBoxContainer = VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	card.get_content().add_child(body)

	body.add_child(ParallaxPalette.label("OBJECTIVE: " + str(op.get("objective", "")), ParallaxPalette.F_LABEL + 1, ParallaxPalette.AMBER))
	var desc: Label = ParallaxPalette.label(str(op.get("description", "")), ParallaxPalette.F_LABEL + 1, ParallaxPalette.TEXT_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(desc)

	var st: Dictionary = {"param": float(op.get("default", 0.0)), "phase": "idle", "report": {}, "verification": {}}
	var refs: Dictionary = {}

	if str(op.get("kind", "")) != "verify":
		var prow: HBoxContainer = HBoxContainer.new()
		prow.add_theme_constant_override("separation", 8)
		body.add_child(prow)
		prow.add_child(ParallaxPalette.caption(str(op.get("param_label", "PARAMETER"))))
		var value_label: Label = ParallaxPalette.label(_param_text(op, float(st["param"])), ParallaxPalette.F_VALUE, ParallaxPalette.CYAN_SOFT)
		value_label.custom_minimum_size.x = 74
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		prow.add_child(value_label)
		var slider: HSlider = HSlider.new()
		slider.min_value = float(op.get("min", 0.0))
		slider.max_value = float(op.get("max", 100.0))
		slider.step = float(op.get("step", 1.0))
		slider.value = float(st["param"])
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.x = 140.0
		slider.value_changed.connect(func(v: float) -> void:
			st["param"] = v
			value_label.text = _param_text(op, v)
			_update_predicted(op, st, refs))
		prow.add_child(slider)
		prow.add_child(ParallaxPalette.caption(str(op.get("unit", ""))))
		refs["value_label"] = value_label
		refs["slider"] = slider

	var pred_label: Label = ParallaxPalette.label("", ParallaxPalette.F_LABEL + 1, ParallaxPalette.TEXT)
	body.add_child(pred_label)
	refs["pred_label"] = pred_label

	var action: Button = Button.new()
	action.focus_mode = Control.FOCUS_NONE
	action.custom_minimum_size.y = 34.0
	action.add_theme_font_size_override("font_size", ParallaxPalette.F_HEAD)
	action.pressed.connect(func() -> void: _on_action(op, st, refs))
	body.add_child(action)
	refs["action"] = action

	var cancel: Button = Button.new()
	cancel.text = "CANCEL"
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.add_theme_font_size_override("font_size", ParallaxPalette.F_SMALL)
	cancel.pressed.connect(func() -> void:
		st["phase"] = "idle"
		_apply_card(op, st, refs))
	body.add_child(cancel)
	refs["cancel"] = cancel

	var result: VBoxContainer = VBoxContainer.new()
	result.add_theme_constant_override("separation", 2)
	result.visible = false
	body.add_child(result)
	refs["result"] = result

	var verify_btn: Button = Button.new()
	verify_btn.text = "VERIFY RESULT"
	verify_btn.focus_mode = Control.FOCUS_NONE
	verify_btn.custom_minimum_size.y = 28.0
	verify_btn.add_theme_font_size_override("font_size", ParallaxPalette.F_LABEL + 1)
	verify_btn.visible = false
	verify_btn.pressed.connect(func() -> void: _on_verify(op, st, refs))
	body.add_child(verify_btn)
	refs["verify"] = verify_btn

	var vres: Label = ParallaxPalette.label("", ParallaxPalette.F_LABEL + 1, ParallaxPalette.GREEN)
	vres.visible = false
	vres.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(vres)
	refs["vres"] = vres

	_cards[str(op.get("id", ""))] = {"op": op, "state": st, "refs": refs}
	_apply_card(op, st, refs)
	return card


func _apply_card(op: Dictionary, st: Dictionary, refs: Dictionary) -> void:
	var action: Button = refs["action"]
	var cancel: Button = refs["cancel"]
	var verify_btn: Button = refs["verify"]
	var phase: String = str(st["phase"])
	match phase:
		"idle":
			action.visible = true
			action.disabled = false
			action.text = "ARM OPERATION" if bool(op.get("confirm", false)) else "EXECUTE OPERATION"
			action.add_theme_color_override("font_color", ParallaxPalette.CYAN)
			cancel.visible = false
			verify_btn.visible = false
		"armed":
			action.visible = true
			action.disabled = false
			action.text = "CONFIRM EXECUTION"
			action.add_theme_color_override("font_color", ParallaxPalette.AMBER)
			cancel.visible = true
		"executed":
			action.visible = false
			cancel.visible = false
			verify_btn.visible = true
		"verified":
			action.visible = false
			cancel.visible = false
			verify_btn.visible = false
	_update_predicted(op, st, refs)


func _update_predicted(op: Dictionary, st: Dictionary, refs: Dictionary) -> void:
	var label: Label = refs.get("pred_label")
	if label == null:
		return
	var sim: OrbitalSimulation = OrbitalSimulation.active()
	if sim == null:
		label.text = ""
		return
	var pred: Dictionary = ManeuverManager.predicted(sim, op, float(st["param"]))
	label.text = "PREDICTED:  %s   ·   %s km   ·   %s" % [
		str(pred.get("summary", "")),
		ParallaxFormat.thousands(float(pred.get("altitude_km", 0.0))),
		_fmt_period(float(pred.get("period_s", 0.0))),
	]


func _on_action(op: Dictionary, st: Dictionary, refs: Dictionary) -> void:
	match str(st["phase"]):
		"idle":
			if bool(op.get("confirm", false)):
				st["phase"] = "armed"
				InterfaceSfx.play(self, "relay")
				_apply_card(op, st, refs)
			else:
				_do_execute(op, st, refs)
		"armed":
			_do_execute(op, st, refs)


func _do_execute(op: Dictionary, st: Dictionary, refs: Dictionary) -> void:
	var sim: OrbitalSimulation = OrbitalSimulation.active()
	if sim == null:
		return
	var report: Dictionary = ManeuverManager.execute(sim, op, float(st["param"]), MissionState, _built_mission)
	st["report"] = report
	st["phase"] = "executed"
	InterfaceSfx.play(self, "confirm")

	var result: VBoxContainer = refs["result"]
	for c in result.get_children():
		c.queue_free()
	result.add_child(_kv("COMMANDED Δv", "%s m/s" % String.num(report["applied_delta_v_ms"], 1)))
	result.add_child(_kv("ALTITUDE BEFORE", "%s km" % String.num(report["altitude_before_km"], 0)))
	result.add_child(_kv("ALTITUDE AFTER", "%s km" % String.num(report["altitude_after_km"], 0)))
	result.add_child(_kv("NEW PERIOD", _fmt_period(float(report["period_after_s"]))))
	result.visible = true

	_update_header()
	_apply_card(op, st, refs)


func _on_verify(op: Dictionary, st: Dictionary, refs: Dictionary) -> void:
	var res: Dictionary = ManeuverManager.verify(op, st["report"])
	st["verification"] = res
	st["phase"] = "verified"
	var vres: Label = refs["vres"]
	var ok: bool = bool(res.get("success", false))
	vres.text = ("VERIFIED · " if ok else "CHECK · ") + str(res.get("note", ""))
	vres.add_theme_color_override("font_color", ParallaxPalette.GREEN if ok else ParallaxPalette.AMBER)
	vres.visible = true
	InterfaceSfx.play(self, "confirm" if ok else "warning")
	ParallaxMotion.flash(vres, ParallaxPalette.CYAN if ok else ParallaxPalette.AMBER, 0.5)
	_apply_card(op, st, refs)


func _kv(key: String, value: String) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var k: Label = ParallaxPalette.caption(key)
	k.custom_minimum_size.x = 150
	row.add_child(k)
	row.add_child(ParallaxPalette.label(value, ParallaxPalette.F_LABEL + 1, ParallaxPalette.TEXT))
	return row


func _param_text(op: Dictionary, value: float) -> String:
	var unit: String = str(op.get("unit", ""))
	if unit == "km":
		return "%d km" % int(value)
	return "%s %s" % [String.num(value, 1), unit]


func _fmt_period(seconds: float) -> String:
	var h: int = int(floor(seconds / 3600.0))
	var m: int = int(floor(fmod(seconds, 3600.0) / 60.0))
	return "%dh %02dm" % [h, m]