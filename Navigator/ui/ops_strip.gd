class_name OpsStrip
extends Control

## PARALLAX — the persistent "Operations and Mission Control" strip along the
## bottom of the Navigator: objective, phase, next action, recent events and the
## crew communication status.

var _objective: Label
var _phase: Label
var _next: Label
var _events: Label
var _comm_row: HBoxContainer


func _ready() -> void:
	if MissionBus != null:
		MissionBus.progression_changed.connect(_refresh)
	if MissionState != null:
		MissionState.changed.connect(_refresh)
	_build()
	_refresh()


func _build() -> void:
	var frame: PanelFrame = PanelFrame.new("OPERATIONS AND MISSION CONTROL", ParallaxPalette.CYAN)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	frame.get_content().add_child(row)

	_objective = _column(row, "ACTIVE MISSION OBJECTIVE")
	_phase = _column(row, "OPERATIONAL PHASE")
	_next = _column(row, "NEXT REQUIRED ACTION")
	_events = _column(row, "RECENT MISSION EVENTS")

	var comm: VBoxContainer = VBoxContainer.new()
	comm.custom_minimum_size.x = 210
	comm.add_theme_constant_override("separation", 6)
	row.add_child(comm)
	comm.add_child(ParallaxPalette.caption("CREW COMMUNICATION STATUS"))
	_comm_row = HBoxContainer.new()
	_comm_row.add_theme_constant_override("separation", 6)
	comm.add_child(_comm_row)


func _column(row: HBoxContainer, caption: String) -> Label:
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 3)
	row.add_child(col)
	col.add_child(ParallaxPalette.caption(caption))
	var value: Label = ParallaxPalette.label("—", ParallaxPalette.F_HEAD, ParallaxPalette.CYAN_SOFT)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.custom_minimum_size.y = 36
	col.add_child(value)
	return value


func _refresh() -> void:
	if MissionState == null:
		return

	# Objective + phase: the active mission if any, else the first available.
	var focus: String = MissionState.active_mission
	if focus == "":
		var avail: Array = MissionState.available_missions()
		if avail.size() > 0:
			focus = str(avail[0])
	var def: Dictionary = MissionDefinitions.get_mission(focus)
	if _objective != null:
		_objective.text = str(def.get("title", "NO ACTIVE OBJECTIVE"))
	if _phase != null:
		_phase.text = str(def.get("phase", "—"))

	# Next required action
	if _next != null:
		if MissionState.active_mission != "":
			_next.text = "PROCEED — " + str(MissionDefinitions.get_mission(MissionState.active_mission).get("title", ""))
		else:
			var av: Array = MissionState.available_missions()
			if av.size() > 0:
				_next.text = "BEGIN — " + str(MissionDefinitions.get_mission(str(av[0])).get("title", ""))
			else:
				_next.text = "AWAITING MISSION EVENTS"

	# Recent events: last completed missions
	if _events != null:
		var completed: Array = []
		for mid in MissionDefinitions.mission_ids():
			if MissionState.is_completed(str(mid)):
				completed.append(str(MissionDefinitions.get_mission(str(mid)).get("title", "")))
		if completed.is_empty():
			_events.text = "NO MISSION EVENTS LOGGED"
		else:
			var shown: Array = completed.slice(maxi(0, completed.size() - 3), completed.size())
			_events.text = "• " + "\n• ".join(shown)

	_refresh_comm()


func _refresh_comm() -> void:
	if _comm_row == null:
		return
	for c in _comm_row.get_children():
		c.queue_free()
	for member in MissionDefinitions.CREW_ROSTER as Array:
		var m: Dictionary = member
		var id: String = str(m.get("id", ""))
		var col: Color = ParallaxPalette.CYAN
		if id != "SRI_KALYAN" and id != "VARUN":
			col = ParallaxPalette.GREEN if MissionState.has_event("SURFACE_CONTACT_CONFIRMED") else ParallaxPalette.TEXT_FAINT
		var dot: Label = ParallaxPalette.label("●", ParallaxPalette.F_HEAD + 4, col)
		dot.tooltip_text = str(m.get("name", ""))
		_comm_row.add_child(dot)