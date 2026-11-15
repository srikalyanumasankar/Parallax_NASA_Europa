class_name OrbitalInfoPanel
extends PanelFrame

## PARALLAX — information panel for the object selected in the orbital display.

var _col: VBoxContainer


func _init() -> void:
	super("ORBIT OBJECT", ParallaxPalette.CYAN)
	mouse_filter = Control.MOUSE_FILTER_PASS
	fill = Color(0.03, 0.055, 0.10, 0.82)


func _ready() -> void:
	super._ready()
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	get_content().add_child(scroll)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 4)
	_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_col)


func show_body(data: Dictionary) -> void:
	set_title(str(data.get("name", "—")).to_upper())
	if _col == null:
		return
	for c in _col.get_children():
		c.queue_free()

	_col.add_child(ParallaxPalette.caption(str(data.get("designation", ""))))
	_col.add_child(ParallaxPalette.label(str(data.get("type", "—")), ParallaxPalette.F_LABEL + 1, ParallaxPalette.CYAN_SOFT))

	_show_real_data(str(data.get("id", "")))

	_col.add_child(_rule())
	_col.add_child(_section("MAP GEOMETRY (SCHEMATIC)"))
	var orbit_r: float = float(data.get("orbit_radius", 0.0))
	var orbit_text: String = "PRIMARY BODY" if orbit_r <= 0.0 else "%s u  (schematic)" % String.num(orbit_r, 1)
	_col.add_child(_kv("MAP ORBIT", orbit_text))
	var desc: Label = ParallaxPalette.label(str(data.get("description", "")), ParallaxPalette.F_LABEL + 1, ParallaxPalette.TEXT_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_col.add_child(desc)


func _show_real_data(body_id: String) -> void:
	var registry: CelestialData = CelestialData.instance()
	if not registry.is_available(body_id):
		_col.add_child(_section("PHYSICAL DATA"))
		var none: Label = ParallaxPalette.caption("REAL DATA UNAVAILABLE")
		none.add_theme_color_override("font_color", ParallaxPalette.RED)
		_col.add_child(none)
		return

	var body: Dictionary = registry.get_body(body_id)
	_col.add_child(_section("PHYSICAL DATA (NASA/JPL)"))
	if body.has("radius_equatorial_km"):
		_col.add_child(_kv("EQ. RADIUS", "%s km" % ParallaxFormat.thousands(float(body["radius_equatorial_km"]))))
	if body.has("radius_mean_km"):
		_col.add_child(_kv("MEAN RADIUS", "%s km" % ParallaxFormat.thousands(float(body["radius_mean_km"]))))
	if body.has("mass_kg"):
		_col.add_child(_kv("MASS", "%s kg" % String.num_scientific(float(body["mass_kg"]))))
	if body.has("semi_major_axis_km"):
		_col.add_child(_kv("SEMI-MAJ. AXIS", "%s km" % ParallaxFormat.thousands(float(body["semi_major_axis_km"]))))
	if body.has("orbital_period_days"):
		_col.add_child(_kv("ORBITAL PERIOD", "%s d" % String.num(float(body["orbital_period_days"]), 3)))
	if body.has("sidereal_rotation_period_hours"):
		_col.add_child(_kv("ROTATION", "%s h" % String.num(float(body["sidereal_rotation_period_hours"]), 3)))

	var src: DataSource = registry.source_for(body_id)
	if src != null:
		var status: Label = ParallaxPalette.caption(src.status_line())
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status.add_theme_color_override("font_color", ParallaxPalette.GREEN if src.verified else ParallaxPalette.AMBER)
		_col.add_child(status)
		var cite: Label = ParallaxPalette.caption(src.source)
		cite.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_col.add_child(cite)


func _section(text: String) -> Label:
	var l: Label = ParallaxPalette.caption(text)
	l.add_theme_color_override("font_color", ParallaxPalette.CYAN_SOFT)
	return l


func _kv(key: String, value: String) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var k: Label = ParallaxPalette.caption(key)
	k.custom_minimum_size.x = 92
	row.add_child(k)
	row.add_child(ParallaxPalette.label(value, ParallaxPalette.F_LABEL + 1, ParallaxPalette.TEXT))
	return row


func _rule() -> ColorRect:
	var line: ColorRect = ColorRect.new()
	line.color = ParallaxPalette.BORDER
	line.custom_minimum_size.y = 1
	return line