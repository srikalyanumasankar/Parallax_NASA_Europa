class_name DatabasePanel
extends Control

## PARALLAX — shared mission database: uploaded observations, scientific data,
## crew reports and mission files. Entries arrive from MissionState; the empty
## state is shown honestly rather than faked.

var _col: VBoxContainer


func _ready() -> void:
	if MissionBus != null:
		MissionBus.database_entry_added.connect(_on_entry)
		MissionBus.progression_changed.connect(_refresh)
	_build()
	_refresh()


func _build() -> void:
	var frame: PanelFrame = PanelFrame.new("MISSION DATABASE", ParallaxPalette.BLUE)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.set_hint("SHARED ACROSS ALL SIX CREW")
	add_child(frame)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.get_content().add_child(scroll)

	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 4)
	_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_col)


func _on_entry(_entry: Dictionary) -> void:
	_refresh()


func _refresh() -> void:
	if _col == null:
		return
	for c in _col.get_children():
		c.queue_free()

	var db: Array = MissionState.database if MissionState != null else []
	if db.is_empty():
		var empty: Label = ParallaxPalette.label("NO ENTRIES UPLOADED — awaiting data from the surface and orbital modules.", ParallaxPalette.F_HEAD, ParallaxPalette.TEXT_DIM)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_col.add_child(empty)
		return

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	header.add_child(_cell("ID", 170.0, ParallaxPalette.TEXT_FAINT))
	header.add_child(_cell("SOURCE", 120.0, ParallaxPalette.TEXT_FAINT))
	header.add_child(_cell("TITLE", 0.0, ParallaxPalette.TEXT_FAINT))
	_col.add_child(header)
	_col.add_child(_rule())

	for entry in db:
		var e: Dictionary = entry
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.add_child(_cell(str(e.get("id", "")), 170.0, ParallaxPalette.CYAN_SOFT))
		row.add_child(_cell(str(e.get("source", "")), 120.0, ParallaxPalette.TEXT_DIM))
		row.add_child(_cell(str(e.get("title", "")), 0.0, ParallaxPalette.TEXT))
		_col.add_child(row)


func _cell(text: String, width: float, color: Color) -> Label:
	var l: Label = ParallaxPalette.label(text, ParallaxPalette.F_LABEL + 1, color)
	if width > 0.0:
		l.custom_minimum_size.x = width
	else:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _rule() -> ColorRect:
	var line: ColorRect = ColorRect.new()
	line.color = ParallaxPalette.BORDER
	line.custom_minimum_size.y = 1
	return line