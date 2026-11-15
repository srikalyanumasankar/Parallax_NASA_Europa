class_name MissionPanel
extends Control

## PARALLAX — mission panel: the full mission list, the selected mission's
## objectives and unlock requirements (with the exact reason it is locked), and
## clearly-labelled development test controls for cross-module events.

const DEV_EVENTS: Array = [
	"LANDING_PREPARATION_CONFIRMED",
	"SURFACE_COMMUNICATION_READY",
	"MANIC_BASE_OPERATIONAL",
	"VARUN_SURFACE_COMMUNICATION_ESTABLISHED",
	"KANDAM_DATA_UPLOADED",
	"KADAL_DATA_UPLOADED",
	"ENVIRONMENTAL_SYSTEMS_VERIFIED",
	"SAMPLE_STORED",
	"SCIENTIFIC_RESULTS_UPLOADED",
	"OBSERVATION_DATA_UPLOADED",
	"SCIENTIFIC_INVESTIGATION_COMPLETE",
	"SAMPLES_PACKAGED",
	"SURFACE_RETURN_READY",
	"COMMUNICATIONS_AVAILABLE",
]

var _selected: String = "NAV_001"
var _rows: Dictionary = {}
var _list_box: VBoxContainer
var _detail_col: VBoxContainer


func _ready() -> void:
	if MissionBus != null:
		MissionBus.progression_changed.connect(_refresh)
	if MissionState != null:
		MissionState.changed.connect(_refresh)
	_build()
	_refresh()


func _build() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 10)
	add_child(row)

	# ---- Mission list -------------------------------------------------------
	var list_frame: PanelFrame = PanelFrame.new("MISSION LIST", ParallaxPalette.CYAN)
	list_frame.custom_minimum_size.x = 340
	row.add_child(list_frame)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_frame.get_content().add_child(scroll)
	_list_box = VBoxContainer.new()
	_list_box.add_theme_constant_override("separation", 0)
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list_box)

	# ---- Mission detail -----------------------------------------------------
	var detail_frame: PanelFrame = PanelFrame.new("MISSION DETAIL", ParallaxPalette.BLUE)
	detail_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail_frame)
	var dscroll: ScrollContainer = ScrollContainer.new()
	dscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_frame.get_content().add_child(dscroll)
	_detail_col = VBoxContainer.new()
	_detail_col.add_theme_constant_override("separation", 8)
	_detail_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dscroll.add_child(_detail_col)


func _refresh() -> void:
	if _list_box == null:
		return
	if MissionDefinitions.get_mission(_selected).is_empty():
		_selected = "NAV_001"
	_rebuild_list()
	_rebuild_detail()


func _rebuild_list() -> void:
	for child in _list_box.get_children():
		child.queue_free()
	_rows.clear()
	for id in MissionDefinitions.mission_ids():
		var mid: String = str(id)
		var def: Dictionary = MissionDefinitions.get_mission(mid)
		var row: MissionListRow = MissionListRow.new(mid, str(def.get("title", mid)))
		row.set_row_state(MissionState.mission_state(mid))
		row.set_selected(mid == _selected)
		row.pressed.connect(_on_selected.bind(mid))
		_list_box.add_child(row)
		_rows[mid] = row


func _on_selected(mid: String) -> void:
	_selected = mid
	for k in _rows.keys():
		(_rows[k] as MissionListRow).set_selected(k == _selected)
	_rebuild_detail()


func _rebuild_detail() -> void:
	for child in _detail_col.get_children():
		child.queue_free()

	var def: Dictionary = MissionDefinitions.get_mission(_selected)
	if def.is_empty():
		return
	var state: String = MissionState.mission_state(_selected)
	var crew: Dictionary = MissionDefinitions.crew_for(str(def.get("character", "")))

	# Header: id + status
	var head: HBoxContainer = HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	_detail_col.add_child(head)
	head.add_child(ParallaxPalette.label(_selected, ParallaxPalette.F_LABEL + 1, ParallaxPalette.TEXT_FAINT))
	var chip: Label = ParallaxPalette.label(state, ParallaxPalette.F_LABEL + 1, ParallaxPalette.status_color(state))
	head.add_child(chip)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	if def.get("mandatory", false):
		head.add_child(ParallaxPalette.label("MANDATORY", ParallaxPalette.F_SMALL, ParallaxPalette.AMBER))

	_detail_col.add_child(ParallaxPalette.label(str(def.get("title", "")), ParallaxPalette.F_TITLE, ParallaxPalette.CYAN_SOFT))
	_detail_col.add_child(ParallaxPalette.caption("%s   ·   %s" % [str(def.get("phase", "")), str(crew.get("name", ""))]))
	var summary: Label = ParallaxPalette.label(str(def.get("summary", "")), ParallaxPalette.F_HEAD, ParallaxPalette.TEXT_DIM)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_col.add_child(summary)

	# Primary action, kept near the top so it is reachable without scrolling.
	_detail_col.add_child(_action_button(state))

	_detail_col.add_child(_rule())

	# Objectives
	_detail_col.add_child(_section_label("REQUIRED TASKS"))
	for obj in def.get("objectives", []) as Array:
		var done: bool = MissionState.is_objective_done(_selected, str(obj))
		_detail_col.add_child(_bullet(str(obj), ParallaxPalette.GREEN if done else ParallaxPalette.TEXT_DIM, "✓" if done else "○"))
	_detail_col.add_child(ParallaxPalette.caption("OBJECTIVES   %d / %d   —   completed via the MANOEUVRES section" % [
		MissionState.objectives_done_count(_selected),
		MissionState.required_objective_count(_selected),
	]))

	_detail_col.add_child(_rule())

	# Unlock requirements (this is the locked-mission reason display)
	_detail_col.add_child(_section_label("UNLOCK REQUIREMENTS"))
	var eval: Dictionary = MissionState.evaluate(_selected)
	var reqs: Array = eval.get("requirements", [])
	if reqs.is_empty():
		_detail_col.add_child(_bullet("No prerequisites — available from mission start.", ParallaxPalette.GREEN, "✓"))
	else:
		for r: Dictionary in reqs:
			var met: bool = bool(r.get("met", false))
			var glyph: String = "✓" if met else "○"
			var col: Color = ParallaxPalette.GREEN if met else ParallaxPalette.AMBER
			var text: String = str(r.get("label", "")) + ("" if met else "   —  WAITING")
			_detail_col.add_child(_bullet(text, col, glyph))

	if state == MissionDefinitions.STATUS_LOCKED:
		_detail_col.add_child(_rule())
		var missing: Array = eval.get("missing", [])
		var lock_msg: Label = ParallaxPalette.label("LOCKED: %d requirement(s) outstanding." % missing.size(), ParallaxPalette.F_HEAD, ParallaxPalette.RED)
		_detail_col.add_child(lock_msg)

	_detail_col.add_child(_rule())
	_detail_col.add_child(ParallaxPalette.caption("COMPLETION EVENT:   " + str(def.get("completion_event", "—"))))

	# Mission history
	_detail_col.add_child(_rule())
	_detail_col.add_child(_section_label("MISSION HISTORY"))
	var history: Array = MissionState.mission_history()
	if history.is_empty():
		_detail_col.add_child(_bullet("No missions completed yet.", ParallaxPalette.TEXT_DIM, "○"))
	else:
		for h in history:
			var rec: Dictionary = h
			_detail_col.add_child(_bullet("%s  —  MET %s" % [str(rec["title"]), ParallaxFormat.met(float(rec["day"]))], ParallaxPalette.GREEN, "✓"))

	# Development test controls
	_detail_col.add_child(_dev_controls())


func _action_button(state: String) -> Control:
	var btn: Button = Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size.y = 38.0
	btn.add_theme_font_size_override("font_size", ParallaxPalette.F_HEAD)
	match state:
		MissionDefinitions.STATUS_AVAILABLE:
			btn.text = "BEGIN MISSION"
			btn.add_theme_color_override("font_color", ParallaxPalette.CYAN)
			btn.pressed.connect(func() -> void:
				MissionState.start_mission(_selected)
				InterfaceSfx.play(self, "confirm")
				_refresh())
		MissionDefinitions.STATUS_ACTIVE:
			if MissionState.are_objectives_done(_selected):
				btn.text = "COMPLETE MISSION"
				btn.add_theme_color_override("font_color", ParallaxPalette.GREEN)
				btn.pressed.connect(func() -> void:
					MissionState.complete_mission(_selected)
					InterfaceSfx.play(self, "complete")
					_refresh())
			else:
				btn.text = "OBJECTIVES INCOMPLETE  (%d / %d)" % [
					MissionState.objectives_done_count(_selected),
					MissionState.required_objective_count(_selected),
				]
				btn.disabled = true
				btn.add_theme_color_override("font_color", ParallaxPalette.AMBER)
		MissionDefinitions.STATUS_COMPLETED:
			btn.text = "MISSION COMPLETE"
			btn.disabled = true
			btn.add_theme_color_override("font_color", ParallaxPalette.GREEN)
		_:
			btn.text = "LOCKED"
			btn.disabled = true
			btn.add_theme_color_override("font_color", ParallaxPalette.TEXT_FAINT)
	return btn


func _dev_controls() -> Control:
	var frame: PanelFrame = PanelFrame.new("DEVELOPMENT TEST CONTROLS", ParallaxPalette.AMBER)
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	frame.get_content().add_child(col)

	var note: Label = ParallaxPalette.caption("Stand-in for the other five character modules. These inject events into the shared state so dependencies can be tested. Not real mission progress.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(note)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	col.add_child(grid)
	for ev in DEV_EVENTS:
		var b: Button = Button.new()
		b.text = str(ev)
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size.y = 26.0
		b.add_theme_font_size_override("font_size", ParallaxPalette.F_SMALL)
		var captured: String = str(ev)
		b.pressed.connect(func() -> void:
			MissionState.publish_event(captured, "DEV_TEST")
			_refresh())
		grid.add_child(b)

	var reset: Button = Button.new()
	reset.text = "RESET NAVIGATOR PROGRESS (DEV)"
	reset.focus_mode = Control.FOCUS_NONE
	reset.add_theme_font_size_override("font_size", ParallaxPalette.F_SMALL)
	reset.pressed.connect(func() -> void:
		MissionState.reset_progress()
		InterfaceSfx.play(self, "relay")
		_refresh())
	col.add_child(reset)
	return frame


func _section_label(text: String) -> Label:
	return ParallaxPalette.label(text, ParallaxPalette.F_LABEL, ParallaxPalette.CYAN_SOFT)


func _bullet(text: String, color: Color, glyph: String) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var gl: Label = ParallaxPalette.label(glyph, ParallaxPalette.F_LABEL + 1, color)
	gl.custom_minimum_size.x = 14
	row.add_child(gl)
	var t: Label = ParallaxPalette.label(text, ParallaxPalette.F_LABEL + 1, color)
	row.add_child(t)
	return row


func _rule() -> Control:
	var line: ColorRect = ColorRect.new()
	line.color = ParallaxPalette.BORDER
	line.custom_minimum_size.y = 1
	return line