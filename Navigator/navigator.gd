class_name NavigatorScreen
extends Control

## PARALLAX — the Flight & Navigation Officer console: a full-screen 2D
## spacecraft operating interface. This scene is the module's entry point and
## works standalone or embedded in the 3D ship (Phase 8).
##
## Phase 1 delivers the frame: animated backdrop, top status bar, section
## navigation, the main dashboard, the mission panel and reused components.
## Orbital data, simulation and manoeuvres arrive in later phases.

signal closed

# The shared mission singletons (MissionBus / MissionState) are registered as
# autoloads in project.godot; navigator.gd requires them at parse time.

const BACKGROUND_SHADER: String = "res://PARALLAX/Navigator/theme/grid_background.gdshader"

const SECTIONS: Array = [
	{"id": "navigation", "label": "NAVIGATION"},
	{"id": "telemetry", "label": "TELEMETRY"},
	{"id": "manoeuvres", "label": "MANOEUVRES"},
	{"id": "systems", "label": "SYSTEMS"},
	{"id": "mission", "label": "MISSION"},
	{"id": "crew", "label": "CREW"},
	{"id": "database", "label": "DATABASE"},
]

var _tabs: Dictionary = {}
var _panels: Dictionary = {}
var _content: Control
var _root_box: VBoxContainer
var _offline_hint: Control
var _toasts: VBoxContainer
var _current: String = "navigation"
var _online: bool = true
var _fan: AudioStreamPlayer
var _alert_lamp: AlertIndicator

## When hosted inside the 3D ship, ESC closes the console outright instead of
## toggling the standalone "standing by" state.
var hosted: bool = false


## Prepare the console for display (called by the host before showing it).
func open() -> void:
	_online = true
	if _root_box != null:
		_root_box.visible = true
	if _offline_hint != null:
		_offline_hint.visible = false


## Request that the host close the console.
func close() -> void:
	_online = false
	closed.emit()


func is_open() -> bool:
	return _online


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Auto-log shared events and mission unlocks as communications.
	_build()
	_select("navigation", false)


func _build() -> void:
	# Animated backdrop
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.color = ParallaxPalette.BG_DEEP
	var mat: ShaderMaterial = ShaderMaterial.new()
	if ResourceLoader.exists(BACKGROUND_SHADER):
		mat.shader = load(BACKGROUND_SHADER) as Shader
	bg.material = mat
	add_child(bg)

	# Flight simulation model — created before the panels so they can bind to it.
	var sim: OrbitalSimulation = OrbitalSimulation.new()
	add_child(sim)

	# Spacecraft subsystems model — also created before the panels bind to it.
	var subsystems: SystemsSimulation = SystemsSimulation.new()
	add_child(subsystems)

	_root_box = VBoxContainer.new()
	_root_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_box.add_theme_constant_override("separation", 0)
	_root_box.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_root_box)

	var top: TopStatusBar = TopStatusBar.new()
	top.custom_minimum_size.y = 66.0
	_root_box.add_child(top)

	_root_box.add_child(_build_tab_bar())

	var content_margin: MarginContainer = MarginContainer.new()
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", 12)
	content_margin.add_theme_constant_override("margin_right", 12)
	content_margin.add_theme_constant_override("margin_top", 10)
	content_margin.add_theme_constant_override("margin_bottom", 10)
	_root_box.add_child(content_margin)

	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_PASS
	content_margin.add_child(_content)

	for s: Dictionary in SECTIONS:
		var sid: String = str(s["id"])
		var panel: Control = _create_section(sid)
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.visible = false
		_content.add_child(panel)
		_panels[sid] = panel

	var ops: OpsStrip = OpsStrip.new()
	ops.custom_minimum_size.y = 96.0
	_root_box.add_child(ops)

	_offline_hint = _build_offline_hint()
	add_child(_offline_hint)

	# Lock/unlock notifications — transient toasts fed by the shared event bus.
	_toasts = VBoxContainer.new()
	_toasts.anchor_left = 1.0
	_toasts.anchor_right = 1.0
	_toasts.offset_left = -332.0
	_toasts.offset_right = -16.0
	_toasts.offset_top = 112.0
	_toasts.add_theme_constant_override("separation", 6)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toasts)
	if MissionBus != null:
		MissionBus.mission_unlocked.connect(_on_mission_unlocked)
		MissionBus.mission_completed.connect(_on_mission_completed)
		MissionBus.mission_state_changed.connect(_on_mission_state)
		MissionBus.alert_raised.connect(_on_alert)

	# Ambient cabin sound — a quiet looping fan while the console is on screen.
	_fan = InterfaceSfx.make_loop("fan", -22.0)
	if _fan != null:
		add_child(_fan)
		visibility_changed.connect(_sync_fan)
		_sync_fan()


func _sync_fan() -> void:
	if _fan == null:
		return
	if visible and not _fan.playing:
		_fan.play()
	elif not visible and _fan.playing:
		_fan.stop()


func _on_mission_unlocked(mission_id: String) -> void:
	InterfaceSfx.play(self, "comm")
	_show_toast("MISSION AVAILABLE", _mission_title(mission_id), ParallaxPalette.CYAN)


func _on_mission_completed(mission_id: String) -> void:
	InterfaceSfx.play(self, "complete")
	_show_toast("MISSION COMPLETE", _mission_title(mission_id), ParallaxPalette.GREEN)
	_show_banner("MISSION COMPLETE", _mission_title(mission_id), ParallaxPalette.GREEN)


## A cinematic moment when a mission actually starts.
func _on_mission_state(mission_id: String, state: String) -> void:
	if state == MissionDefinitions.STATUS_ACTIVE:
		InterfaceSfx.play(self, "confirm")
		_show_banner("MISSION LAUNCHED", _mission_title(mission_id), ParallaxPalette.CYAN)


func _on_alert(level: String, text: String) -> void:
	InterfaceSfx.play(self, "warning")
	if _alert_lamp != null:
		_alert_lamp.set_alert(level, text)
	_show_toast("ALERT · " + level, text, ParallaxPalette.AMBER)


## The mission alert lamp (exposed for tests and for other modules).
func alert_indicator() -> AlertIndicator:
	return _alert_lamp


## A large, brief, centred announcement that fades in and out (cinematic moment
## for mission start / completion). Never blocks input.
func _show_banner(kind: String, message: String, color: Color) -> void:
	var layer: CenterContainer = CenterContainer.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)

	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(box)

	var title: Label = ParallaxPalette.label(kind, ParallaxPalette.F_TITLE + 9, color)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub: Label = ParallaxPalette.label(message, ParallaxPalette.F_HEAD + 1, ParallaxPalette.WHITE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	layer.modulate.a = 0.0
	var tw: Tween = layer.create_tween()
	tw.tween_property(layer, "modulate:a", 1.0, 0.4)
	tw.tween_interval(1.4)
	tw.tween_property(layer, "modulate:a", 0.0, 0.6)
	tw.tween_callback(layer.queue_free)


func _mission_title(mission_id: String) -> String:
	var def: Dictionary = MissionDefinitions.get_mission(mission_id)
	return str(def.get("title", mission_id))


func _show_toast(kind: String, message: String, color: Color) -> void:
	if _toasts == null:
		return
	# Keep at most four toasts on screen.
	while _toasts.get_child_count() >= 4:
		_toasts.get_child(0).queue_free()
		_toasts.remove_child(_toasts.get_child(0))
	var toast: NotificationToast = NotificationToast.new()
	toast.setup(kind, message, color)
	_toasts.add_child(toast)


func _build_tab_bar() -> Control:
	var bar: Control = Control.new()
	bar.custom_minimum_size.y = 38.0
	bar.mouse_filter = Control.MOUSE_FILTER_PASS

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 3)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	bar.add_child(margin)

	var hb: HBoxContainer = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	margin.add_child(hb)

	for s: Dictionary in SECTIONS:
		var tab: SectionTab = SectionTab.new(str(s["label"]))
		tab.pressed.connect(_select.bind(str(s["id"])))
		hb.add_child(tab)
		_tabs[s["id"]] = tab

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(spacer)

	_alert_lamp = AlertIndicator.new()
	_alert_lamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(_alert_lamp)

	var hint: Label = ParallaxPalette.caption("ESC — STAND DOWN CONSOLE")
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(hint)

	var rule: ColorRect = ColorRect.new()
	rule.color = ParallaxPalette.BORDER
	rule.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	rule.offset_top = -1.0
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(rule)
	return bar


func _create_section(section_id: String) -> Control:
	match section_id:
		"navigation":
			return Dashboard.new()
		"mission":
			return MissionPanel.new()
		"crew":
			return CrewPanel.new()
		"database":
			return DatabasePanel.new()
		"telemetry":
			return TelemetryPanel.new()
		"manoeuvres":
			return ManeuverPanel.new()
		"systems":
			return SystemsPanel.new()
		_:
			return Control.new()


func _build_offline_hint() -> Control:
	var layer: Control = Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.visible = false
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)

	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	center.add_child(col)
	var title: Label = ParallaxPalette.label("NAVIGATOR STANDING BY", ParallaxPalette.F_TITLE, ParallaxPalette.CYAN_SOFT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var sub: Label = ParallaxPalette.caption("PRESS ESC TO RESUME THE CONSOLE")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	return layer


func _select(section_id: String, with_sound: bool = true) -> void:
	_current = section_id
	if with_sound:
		InterfaceSfx.play(self, "click")
	for key in _tabs.keys():
		(_tabs[key] as SectionTab).set_active(str(key) == section_id)
	for key2 in _panels.keys():
		var panel: Control = _panels[key2] as Control
		var on: bool = str(key2) == section_id
		panel.visible = on
		if on:
			# Smooth transition into the newly selected section.
			ParallaxMotion.fade_in(panel, 0.18, 0.0)
	_online = true
	_root_box.visible = true
	if _offline_hint != null:
		_offline_hint.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("nav_exit"):
		if hosted:
			close()
		else:
			_toggle_offline()
		get_viewport().set_input_as_handled()


func _toggle_offline() -> void:
	_online = not _online
	_root_box.visible = _online
	if _offline_hint != null:
		_offline_hint.visible = not _online
	if not _online:
		closed.emit()
