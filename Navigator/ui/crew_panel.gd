class_name CrewPanel
extends Control

## PARALLAX — crew telemetry: the six expedition members, their roles, station
## and communication status. No fabricated biometric readings.

var _col: VBoxContainer


func _ready() -> void:
	if MissionBus != null:
		MissionBus.progression_changed.connect(_refresh)
		MissionBus.communication_received.connect(_on_comm)
	_build()
	_refresh()


func _on_comm(_message: Dictionary) -> void:
	_refresh()


func _build() -> void:
	var frame: PanelFrame = PanelFrame.new("CREW & COMMUNICATIONS", ParallaxPalette.CYAN)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.set_hint("CREW · LINK · COMMS LOG")
	add_child(frame)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.get_content().add_child(scroll)

	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 4)
	_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_col)


func _refresh() -> void:
	var col: VBoxContainer = _col
	if col == null:
		return
	for c in col.get_children():
		c.queue_free()

	var header: HBoxContainer = _row("MEMBER", "ROLE & STATION", "", ParallaxPalette.TEXT_FAINT, 0)
	col.add_child(header)
	col.add_child(_rule())

	for member in MissionDefinitions.CREW_ROSTER as Array:
		var m: Dictionary = member
		var status: Array = _member_status(str(m.get("id", "")))
		col.add_child(_member_row(m, str(status[0]), status[1]))

	col.add_child(_rule())
	col.add_child(_section("COMMUNICATION LINKS"))
	var link: Dictionary = CommunicationManager.surface_link_status(MissionState)
	col.add_child(_link_row("ORBITAL ↔ SURFACE", str(link["state"]), link["colour"], str(link["detail"])))
	var earth: Dictionary = CommunicationManager.earth_link_status(MissionState)
	col.add_child(_link_row("EARTH — DEEP SPACE NET", str(earth["state"]), earth["colour"], str(earth["detail"])))

	col.add_child(_rule())
	col.add_child(_section("COMMUNICATION LOG"))
	var comms: Array = MissionState.recent_communications(12) if MissionState != null else []
	if comms.is_empty():
		var empty: Label = ParallaxPalette.caption("NO COMMUNICATIONS LOGGED — mission-control directives and crew reports appear here.")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(empty)
	else:
		for msg in comms:
			col.add_child(_message_row(msg))


func _section(text: String) -> Label:
	return ParallaxPalette.label(text, ParallaxPalette.F_LABEL, ParallaxPalette.CYAN_SOFT)


func _link_row(link: String, state: String, color: Color, detail: String) -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var key: Label = ParallaxPalette.caption(link)
	key.custom_minimum_size.x = 190
	top.add_child(key)
	var val: Label = ParallaxPalette.label(state, ParallaxPalette.F_LABEL + 1, color)
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(val)
	box.add_child(top)
	var d: Label = ParallaxPalette.caption(detail)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(d)
	return box


func _message_row(msg: Dictionary) -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.add_child(ParallaxPalette.label(str(msg.get("subject", "MESSAGE")), ParallaxPalette.F_LABEL + 1, ParallaxPalette.CYAN_SOFT))
	var from: Label = ParallaxPalette.caption(CommunicationManager.source_label(str(msg.get("source", ""))))
	from.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	from.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(from)
	box.add_child(top)
	var body: Label = ParallaxPalette.label(str(msg.get("body", "")), ParallaxPalette.F_LABEL + 1, ParallaxPalette.TEXT_DIM)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	return box


func _member_row(m: Dictionary, status: String, color: Color) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var dot: Label = ParallaxPalette.label("●", ParallaxPalette.F_LABEL + 2, color)
	row.add_child(dot)

	var name_label: Label = ParallaxPalette.label(str(m.get("name", "")), ParallaxPalette.F_HEAD, ParallaxPalette.TEXT)
	name_label.custom_minimum_size.x = 130
	row.add_child(name_label)

	var role_col: VBoxContainer = VBoxContainer.new()
	role_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	role_col.add_theme_constant_override("separation", 0)
	row.add_child(role_col)
	role_col.add_child(ParallaxPalette.label(str(m.get("role", "")), ParallaxPalette.F_LABEL + 1, ParallaxPalette.TEXT_DIM))
	role_col.add_child(ParallaxPalette.caption(str(m.get("station", ""))))

	var status_label: Label = ParallaxPalette.label(status, ParallaxPalette.F_LABEL + 1, color)
	status_label.custom_minimum_size.x = 180
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(status_label)
	return row


func _row(a: String, b: String, _c: String, color: Color, _d: int) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var l1: Label = ParallaxPalette.label(a, ParallaxPalette.F_SMALL, color)
	l1.custom_minimum_size.x = 150
	row.add_child(l1)
	row.add_child(ParallaxPalette.label(b, ParallaxPalette.F_SMALL, color))
	return row


func _member_status(id: String) -> Array:
	if id == "SRI_KALYAN" or id == "VARUN":
		return ["ON STATION · ORBITAL", ParallaxPalette.CYAN]
	if MissionState != null and MissionState.has_event("SURFACE_CONTACT_CONFIRMED"):
		return ["SURFACE · ACTIVE", ParallaxPalette.GREEN]
	return ["ORBITAL · PRE-LANDING", ParallaxPalette.TEXT_DIM]


func _rule() -> ColorRect:
	var line: ColorRect = ColorRect.new()
	line.color = ParallaxPalette.BORDER
	line.custom_minimum_size.y = 1
	return line