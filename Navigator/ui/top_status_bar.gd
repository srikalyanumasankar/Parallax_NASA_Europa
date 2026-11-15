class_name TopStatusBar
extends Control

## PARALLAX — the top status bar: mission identity, mission-elapsed time, ship
## clock and the primary system/communication status readouts.

var _met_label: Label
var _clock_label: Label
var _status_pill_phr: StatusPill
var _status_pill_prop: StatusPill


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_build()
	if MissionState != null:
		MissionState.changed.connect(_refresh)
	var sim: OrbitalSimulation = OrbitalSimulation.active()
	if sim != null:
		sim.ticked.connect(_refresh)
	_refresh()


func _process(_delta: float) -> void:
	# Ship clock ticks in the fictional simulation only; the MET stays derived
	# from the shared sim day until the Phase 4 simulation drives it.
	pass


func _build() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.02, 0.04, 0.08, 0.85)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var bottom_rule: ColorRect = ColorRect.new()
	bottom_rule.color = ParallaxPalette.BORDER_BRIGHT
	bottom_rule.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_rule.offset_top = -1.0
	bottom_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_rule)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	# Brand
	var emblem: Emblem = Emblem.new()
	emblem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(emblem)
	var brand: VBoxContainer = VBoxContainer.new()
	brand.add_theme_constant_override("separation", -2)
	brand.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(brand)
	var brand_title: Label = ParallaxPalette.label("PARALLAX", ParallaxPalette.F_TITLE, ParallaxPalette.WHITE)
	brand.add_child(brand_title)
	var brand_sub: Label = ParallaxPalette.caption("MISSION CONTROL  ·  FLIGHT & NAVIGATION")
	brand.add_child(brand_sub)

	row.add_child(_divider())
	_met_label = _stat_block(row, "MISSION ELAPSED TIME", ParallaxFormat.met(_met_days()), ParallaxPalette.CYAN_SOFT, 18)
	row.add_child(_divider())
	_clock_label = _stat_block(row, "SHIP CLOCK (SIM)", "—", ParallaxPalette.TEXT, 15)
	row.add_child(_divider())
	_stat_block(row, "SPACECRAFT STATUS", "AETHER : NOMINAL", ParallaxPalette.GREEN, 14)
	row.add_child(_divider())
	_stat_block(row, "COMMUNICATION STATUS", "DEEP SPACE NET : ACTIVE", ParallaxPalette.GREEN, 14)
	row.add_child(_divider())
	_stat_block(row, "NAVIGATION SYSTEM", "NAV CORE : ACTIVE", ParallaxPalette.GREEN, 14)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)

	var pills: VBoxContainer = VBoxContainer.new()
	pills.add_theme_constant_override("separation", 3)
	pills.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pills.custom_minimum_size.x = 132
	row.add_child(pills)
	_status_pill_phr = StatusPill.new("PHR", "STABLE", ParallaxPalette.AMBER)
	_status_pill_prop = StatusPill.new("PROP", "STABLE", ParallaxPalette.AMBER)
	pills.add_child(_status_pill_phr)
	pills.add_child(_status_pill_prop)


func _met_days() -> float:
	var sim: OrbitalSimulation = OrbitalSimulation.active()
	if sim != null:
		return sim.mission_elapsed_days()
	if MissionState != null:
		return MissionState.sim_day
	return SharedMissionState.DEFAULT_MET_DAYS


func _refresh() -> void:
	if _met_label != null:
		_met_label.text = ParallaxFormat.met(_met_days())
	if _clock_label != null:
		var total_s: int = int(_met_days() * 86400.0)
		var hh: int = int(floor(float(total_s) / 3600.0)) % 24
		var mm: int = int(floor(float(total_s) / 60.0)) % 60
		var ss: int = total_s % 60
		_clock_label.text = "%02d:%02d:%02d" % [hh, mm, ss]


func _stat_block(row: HBoxContainer, caption: String, value: String, color: Color, value_size: int) -> Label:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(box)
	var cap: Label = ParallaxPalette.caption(caption)
	box.add_child(cap)
	var val: Label = ParallaxPalette.label(value, value_size, color)
	box.add_child(val)
	return val


func _divider() -> Control:
	var margin_wrap: MarginContainer = MarginContainer.new()
	margin_wrap.add_theme_constant_override("margin_left", 6)
	margin_wrap.add_theme_constant_override("margin_right", 6)
	margin_wrap.add_theme_constant_override("margin_top", 6)
	margin_wrap.add_theme_constant_override("margin_bottom", 6)
	margin_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	margin_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line: ColorRect = ColorRect.new()
	line.color = ParallaxPalette.BORDER
	line.custom_minimum_size = Vector2(1, 30)
	margin_wrap.add_child(line)
	return margin_wrap