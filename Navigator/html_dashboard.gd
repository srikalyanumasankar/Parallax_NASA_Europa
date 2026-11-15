class_name HtmlConsoleDashboard
extends Control

## PARALLAX — native Godot recreation of the "SRI KALYAN · Orbital Flight Command"
## dashboard (originally authored as europa_orbital_command_enhanced.html).
##
## Godot cannot render an .html file directly, so this scene rebuilds that
## dashboard out of native Control nodes: the header, the ten tab screens, the
## KPI tiles, the live charts, the orbital / surface maps and the overlays.
##
## Opened from the 3D ship's navigation console (press E) and left again with
## ESC, which hands off to the standby screen.

signal closed

const STANDBY_SCENE: String = "res://scenes/missions/interplanetary_navigation/InterplanetaryNavigation.tscn"

const TABS: Array = [
	{"id": "overview", "label": "◈ Mission overview"},
	{"id": "flight", "label": "✥ Flight dynamics"},
	{"id": "power", "label": "⚡ Power & thermal"},
	{"id": "crew", "label": "⌘ Crew network"},
	{"id": "archive", "label": "⌕ Mission archive"},
	{"id": "library", "label": "▤ NASA database"},
	{"id": "logs", "label": "▣ Flight recorder"},
	{"id": "navigation", "label": "◎ Europa navigation"},
	{"id": "surface", "label": "⌖ Surface tracking"},
	{"id": "engineering", "label": "⚙ Engineering bay"},
]

# ---- Fictional console palette (mirrors the HTML theme) ------------------- #
const C_BG := Color("050b18")
const C_PANEL := Color(0.043, 0.090, 0.169, 0.92)
const C_PANEL2 := Color(0.063, 0.137, 0.267, 1.0)
const C_LINE := Color("1d3d67")
const C_CYAN := Color("57e7ff")
const C_BLUE := Color("6d9cff")
const C_GREEN := Color("5af0b1")
const C_AMBER := Color("ffc66d")
const C_RED := Color("ff647c")
const C_MUTED := Color("91a9c9")
const C_TXT := Color("eaf5ff")

const CREW: Array = [
	{"name": "Sri Kalyan", "role": "Orbital pilot & flight dynamics", "station": "Karadi · Flight Deck", "icon": "SK"},
	{"name": "Varun", "role": "Radio astronomer & signal intelligence", "station": "Karadi · Radio Observatory", "icon": "VR"},
	{"name": "Manic", "role": "Base commander & systems operations", "station": "Karadi Kutty · Base Control", "icon": "MN"},
	{"name": "Amrish", "role": "Astrobiologist & xenobiology lead", "station": "Karadi Kutty · Astrobiology Lab", "icon": "AM"},
	{"name": "Krish", "role": "Rover scientist & surface mobility lead", "station": "KANDAM · Rover Command", "icon": "KR"},
	{"name": "Dhanush", "role": "Oceanographer & subsurface systems lead", "station": "KADAL · Cryobot & Ocean Lab", "icon": "DH"},
]

const SOURCES: Array = [
	["NASA Europa Clipper mission hub", "Mission overview, objectives, current mission status", "mission"],
	["Europa Clipper spacecraft — NASA/JPL", "Spacecraft bus, solar arrays, propulsion, thermal systems", "spacecraft"],
	["Europa Clipper quick facts — JPL", "Dimensions, mass, instrument suite, power system", "spacecraft"],
	["Europa Clipper mission overview — NASA", "Flyby strategy, science goals, radar and magnetometer", "science"],
	["Europa Clipper instruments — JPL", "EIS, E-THEMIS, REASON, MISE, MASPEX, SUDA, UVS, ECM, PIMS", "instruments"],
	["NASA Planetary Data System (PDS)", "Long-term archive for planetary mission datasets", "archive"],
	["NASA Eyes on the Solar System", "Interactive 3D visualization of missions", "visualization"],
	["JPL Horizons System", "Solar-system ephemerides, geometry and observer calculations", "navigation"],
	["NASA Deep Space Network", "Global ground antenna network for deep-space comms", "communications"],
	["Europa Clipper press kit (PDF)", "Detailed mission and spacecraft technical reference", "documents"],
	["NASA Solar System Exploration — Europa", "Europa overview, surface, interior and ocean science", "science"],
]

const ARCHIVE: Array = [
	["Amrish — Astrobiology Lab dossier", "crew", "Xenobiology, microscopy, biosignature screening, KADAL/KANDAM sample analysis."],
	["Dhanush — Oceanography & Cryobot operations", "crew", "Subsurface ocean probes, cryobot health, pressure-temperature profiles, sample custody."],
	["Krish — KANDAM rover command", "crew", "Six-rover fleet, terrain mapping, mobility diagnostics, sample-vault transfer."],
	["Manic — Karadi Kutty base operations", "crew", "Habitat systems, power, environmental controls, server routing, sample intake."],
	["Varun — Radio astronomy observatory", "crew", "Radio signal monitoring, pulsar timing, interference analysis and anomaly reports."],
	["Sri Kalyan — Orbital flight operations", "crew", "Flight dynamics, spacecraft attitude, orbital manoeuvres, power and thermal balance."],
	["KADAL sample custody protocol", "science", "Ocean sample chain-of-custody, sterile handling, timestamping, temperature history."],
	["KANDAM terrain and mobility atlas", "science", "Rover terrain classifications, slope risks, surface hazards and route safety."],
	["Jovian radiation operations memo", "engineering", "Radiation exposure constraints, shielding, safe-mode planning, duty cycles."],
	["Deep Space Network communications window", "comms", "Ground-station visibility, link budgets and data relay scheduling."],
	["Europa Clipper REASON radar reference", "science", "Ice-penetrating radar investigation of Europa's ice shell."],
	["Europa Clipper power system reference", "engineering", "Solar array architecture, load planning and thermal management at Jupiter."],
]

# ---- Live state (fictional) ----------------------------------------------- #
var _alt: float = 100.0
var _power: float = 1.84
var _fuel: float = 82.0
var _tick: int = 0
var _sound_on: bool = false
var _accum: float = 0.0
var _hist: Array = []

var _tabs: Dictionary = {}
var _sections: Dictionary = {}
var _content: Control
var _current: String = "overview"

var _clock_label: Label
var _stamp_label: Label
var _alt_kpi: Array = []
var _log: RichTextLabel
var _plots: Array = []
var _alarm_layer: Control
var _alarm_title: Label
var _alarm_text: Label
var _toast: Panel
var _toast_label: Label
var _archive_results: VBoxContainer
var _archive_filter: String = "all"
var _source_list: VBoxContainer


# =========================================================================== #
#  Custom drawing controls
# =========================================================================== #

## A framed panel: dark surface, thin border, and a padded content VBox in `.box`.
class PanelBox extends PanelContainer:
	var box: VBoxContainer

	func _init() -> void:
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color(0.043, 0.090, 0.169, 0.92)
		sb.border_color = Color("1d3d67")
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 10
		sb.content_margin_bottom = 12
		add_theme_stylebox_override("panel", sb)
		box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(box)


class HBar extends Control:
	var frac: float = 0.0
	var col: Color = Color("57e7ff")

	func _init(f: float = 0.0, c: Color = Color("57e7ff")) -> void:
		frac = f
		col = c
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(0, 5)

	func set_frac(f: float, c: Color = col) -> void:
		frac = clampf(f, 0.0, 1.0)
		col = c
		queue_redraw()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		draw_rect(Rect2(0, 0, w, h), Color(0.09, 0.17, 0.29), true)
		var fw: float = w * clampf(frac, 0.0, 1.0)
		if fw > 0.5:
			draw_rect(Rect2(0, 0, fw, h), col, true)


class Plot extends Control:
	var series: Array = []
	var colors: Array = [Color("53e6ff"), Color("9b9cff"), Color("5af0b1"), Color("ffc66d")]

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(0, 150)

	func set_series(s: Array) -> void:
		series = s
		queue_redraw()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w < 8.0 or h < 8.0:
			return
		var font: Font = get_theme_default_font()
		for i in range(5):
			var y: float = 10.0 + float(i) * (h - 25.0) / 4.0
			draw_line(Vector2(35, y), Vector2(w - 8, y), Color("1b385d"), 1.0)
		draw_string(font, Vector2(6, 11), "LIVE SIMULATION", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("829fbd"))
		for j in range(series.size()):
			var s: PackedFloat32Array = series[j]
			if s.size() < 2:
				continue
			var col: Color = colors[j % colors.size()]
			var pts: PackedVector2Array = PackedVector2Array()
			for i in range(s.size()):
				var x: float = 36.0 + float(i) * (w - 48.0) / float(s.size() - 1)
				var y: float = h - 15.0 - clampf(s[i], 0.0, 1.0) * (h - 35.0)
				pts.append(Vector2(x, y))
			draw_polyline(pts, col, 2.0, true)


class Gauge extends Control:
	var pitch: float = 2.4

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(210, 210)

	func set_pitch(p: float) -> void:
		pitch = p
		queue_redraw()

	func _draw() -> void:
		var c: Vector2 = Vector2(size.x * 0.5, size.y * 0.5)
		var r: float = minf(size.x, size.y) * 0.5 - 8.0
		draw_circle(c, r, Color("071326"))
		draw_arc(c, r, 0.0, TAU, 64, Color("315d87"), 3.0, true)
		draw_arc(c, r * 0.8, 0.0, TAU, 64, Color("1f4168"), 1.0, true)
		draw_line(Vector2(c.x - r, c.y), Vector2(c.x + r, c.y), Color("829fbd"), 1.0)
		draw_line(Vector2(c.x, c.y - r), Vector2(c.x, c.y + r), Color("829fbd"), 1.0)
		var ang: float = deg_to_rad(pitch)
		var tip: Vector2 = c + Vector2(0, -r * 0.78).rotated(ang)
		var back: Vector2 = c + Vector2(0, r * 0.7).rotated(ang)
		draw_line(c, tip, Color("55e7ff"), 2.0)
		draw_line(c, back, Color("55e7ff"), 1.0)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-7, 12).rotated(ang), tip + Vector2(7, 12).rotated(ang)]), Color("55e7ff"))
		draw_circle(c, 4.0, Color.WHITE)
		var font: Font = get_theme_default_font()
		draw_string(font, Vector2(c.x - 30, c.y - r - 2), "NOSE", HORIZONTAL_ALIGNMENT_CENTER, 60, 10, Color("9ecce9"))
		draw_string(font, Vector2(c.x - 30, c.y + r + 12), "NADIR", HORIZONTAL_ALIGNMENT_CENTER, 60, 10, Color("9ecce9"))


class MapView extends Control:
	var kind: String = "jupiter"
	var phase: float = 42.0
	var t: float = 0.0
	var _stars: Array = []

	func _init(k: String = "jupiter", min_h: float = 300.0) -> void:
		kind = k
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true
		custom_minimum_size = Vector2(0, min_h)

	func _ready() -> void:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 20260815
		for i in range(70):
			_stars.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.6, 1.6)))
		resized.connect(queue_redraw)
		set_process(true)

	func _process(delta: float) -> void:
		t += delta
		phase = fmod(phase + delta * 6.0, 360.0)
		queue_redraw()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		for i in range(6, 0, -1):
			var rr: float = float(i) / 6.0
			draw_circle(Vector2(w * 0.55, h * 0.5), minf(w, h) * 0.6 * rr, Color(0.07, 0.14, 0.26, 0.10))
		for s in _stars:
			var st: Vector3 = s
			draw_circle(Vector2(st.x * w, st.y * h), st.z, Color(0.78, 0.88, 1.0, 0.5))
		match kind:
			"jupiter": _draw_jupiter(w, h)
			"europa": _draw_europa(w, h)
			"surface": _draw_surface(w, h)
		var font: Font = get_theme_default_font()
		var label: String = {
			"jupiter": "JOVIAN TRANSFER NAVIGATION DISPLAY / TRAINING SIMULATION",
			"europa": "KARADI ORBITAL TRACK · EUROPA / JUPITER SYSTEM",
			"surface": "HABITAT LOCAL POSITIONING NETWORK · LIVE SIMULATION",
		}.get(kind, "")
		draw_string(font, Vector2(12, 18), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("87dff7"))

	func _draw_jupiter(w: float, h: float) -> void:
		var pc: Vector2 = Vector2(w * 0.80, h * 0.48)
		var pr: float = minf(w, h) * 0.34
		draw_circle(pc, pr, Color("51364a"))
		draw_circle(pc, pr * 0.9, Color("8a5c52"))
		draw_circle(pc, pr * 0.72, Color("b98268"))
		draw_arc(pc, pr * 0.5, -0.4, 1.0, 40, Color("f0c89b"), 6.0, true)
		_dashed_ellipse(pc, pr * 2.05, pr * 0.7, Color(0.29, 0.62, 0.82, 0.6), 1.0, 12.0)
		_dashed_ellipse(pc, pr * 2.6, pr * 1.0, Color(0.22, 0.46, 0.65, 0.45), 1.0, 16.0)
		var path: PackedVector2Array = PackedVector2Array()
		for i in range(41):
			var u: float = float(i) / 40.0
			var x: float = lerpf(w * 0.11, pc.x - pr * 0.2, u)
			var y: float = lerpf(h * 0.78, pc.y, ease(u, 1.8)) - sin(u * PI) * h * 0.24
			path.append(Vector2(x, y))
		_dashed_path(path, Color("55e7ff"), 2.0, 10.0)
		draw_circle(path[0], 7.0, C_GREEN)
		var mid: Vector2 = path[int(path.size() / 2.0)]
		draw_circle(mid, 6.0, C_AMBER)
		var ship: Vector2 = path[int(fmod(t * 6.0, 40.0))]
		_draw_ship(ship, Color("67efff"))
		var font: Font = get_theme_default_font()
		draw_string(font, Vector2(w * 0.09, h * 0.86), "KARADI", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("a6c5e5"))
		draw_string(font, Vector2(mid.x - 40, mid.y - 12), "TRANSFER CORRIDOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("a6c5e5"))
		draw_string(font, Vector2(pc.x - 45, h * 0.94), "JUPITER", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("a6c5e5"))

	func _draw_europa(w: float, h: float) -> void:
		var c: Vector2 = Vector2(w * 0.5, h * 0.5)
		var r: float = minf(w, h) * 0.24
		draw_circle(c, r, Color("345a79"))
		draw_circle(c, r * 0.92, Color("8ebbd0"))
		draw_circle(c, r * 0.7, Color("d9f5ff").lerp(Color("8ebbd0"), 0.4))
		for i in range(4):
			var yy: float = c.y - r * 0.5 + float(i) * r * 0.35
			draw_line(Vector2(c.x - r * 0.75, yy), Vector2(c.x + r * 0.75, yy + 6), Color(0.31, 0.49, 0.61, 0.55), 4.0)
		_dashed_ellipse(c, r * 3.1, r * 1.45, Color("57e7ff"), 2.0, 12.0)
		_dashed_ellipse(c, r * 3.9, r * 1.8, Color(0.32, 0.48, 0.64, 0.5), 1.0, 10.0)
		var ang: float = deg_to_rad(phase)
		var ship: Vector2 = c + Vector2(cos(ang), 0.47 * sin(ang)) * (r * 3.1)
		draw_arc(ship, 15.0, 0.0, TAU, 24, Color(0.34, 0.91, 1.0, 0.6), 1.0, true)
		_draw_ship(ship, Color.WHITE)
		var jc: Vector2 = Vector2(w * 0.88, h * 0.22)
		draw_circle(jc, minf(w, h) * 0.11, Color("61445a"))
		draw_circle(jc, minf(w, h) * 0.09, Color("b77d63"))
		draw_circle(jc, minf(w, h) * 0.06, Color("e8c9a1"))
		var font: Font = get_theme_default_font()
		draw_string(font, Vector2(c.x - 24, c.y + 4), "EUROPA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("c6e8ff"))
		draw_string(font, Vector2(jc.x - 30, jc.y + minf(w, h) * 0.11 + 14), "JUPITER", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("c6e8ff"))
		draw_string(font, Vector2(20, h - 16), "THERA MACULA · SURFACE BASE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("c6e8ff"))

	func _draw_surface(w: float, h: float) -> void:
		var step: float = 46.0
		var x: float = 0.0
		while x < w:
			draw_line(Vector2(x, 0), Vector2(x, h), Color(0.23, 0.39, 0.51, 0.4), 1.0)
			x += step
		var y: float = 0.0
		while y < h:
			draw_line(Vector2(0, y), Vector2(w, y), Color(0.23, 0.39, 0.51, 0.4), 1.0)
			y += step
		_dashed_path(PackedVector2Array([Vector2(w * 0.05, h * 0.78), Vector2(w * 0.18, h * 0.55), Vector2(w * 0.3, h * 0.66), Vector2(w * 0.44, h * 0.3), Vector2(w * 0.62, h * 0.44)]), Color(0.48, 0.64, 0.72, 0.5), 12.0, 40.0)
		var hb: Rect2 = Rect2(Vector2(w * 0.44, h * 0.38), Vector2(w * 0.13, h * 0.24))
		draw_rect(hb, Color("173d59"), true)
		draw_rect(hb, Color("57e7ff"), false, 2.0)
		var font: Font = get_theme_default_font()
		draw_string(font, Vector2(hb.position.x + 8, hb.position.y + hb.size.y * 0.6), "HABITAT", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("dffaff"))
		draw_arc(hb.get_center(), (hb.get_center() - hb.position).length() * 1.05, 0.0, TAU, 48, Color(0.34, 0.91, 1.0, 0.35), 1.0, true)
		var dots: Array = [
			[Vector2(w * 0.33, h * 0.27), C_GREEN, "KRISH · KANDAM"],
			[Vector2(w * 0.63, h * 0.70), C_AMBER, "DHANUSH · KADAL"],
			[Vector2(w * 0.53, h * 0.70), C_BLUE, "MANIC"],
			[Vector2(w * 0.48, h * 0.33), Color("ff8ba1"), "AMRISH"],
		]
		for d in dots:
			var arr: Array = d
			draw_circle(arr[0], 8.0, arr[1])
			draw_string(font, Vector2(arr[0].x + 14, arr[0].y + 4), str(arr[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, C_TXT)

	func _draw_ship(p: Vector2, col: Color) -> void:
		var pts: PackedVector2Array = PackedVector2Array([p + Vector2(0, -11), p + Vector2(8, 9), p + Vector2(0, 5), p + Vector2(-8, 9)])
		draw_colored_polygon(pts, col)
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color.WHITE, 1.0, true)

	func _dashed_ellipse(c: Vector2, rx: float, ry: float, col: Color, width: float, _dash: float) -> void:
		var steps: int = 72
		var prev: Vector2 = c + Vector2(rx, 0)
		for i in range(1, steps + 1):
			var a: float = TAU * float(i) / float(steps)
			var p: Vector2 = c + Vector2(cos(a) * rx, sin(a) * ry)
			if i % 2 == 0:
				draw_line(prev, p, col, width)
			prev = p

	func _dashed_path(path: PackedVector2Array, col: Color, width: float, _dash: float) -> void:
		for i in range(path.size() - 1):
			if i % 2 == 0:
				draw_line(path[i], path[i + 1], col, width)


# =========================================================================== #
#  Lifecycle
# =========================================================================== #

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	for i in range(40):
		_hist.append(0.48 + sin(float(i) / 5.0) * 0.08 + randf() * 0.035)
	_build()
	_select("overview", false)


func _process(delta: float) -> void:
	_accum += delta
	if _accum >= 1.0:
		_accum = 0.0
		_tick_once()


func _tick_once() -> void:
	_tick += 1
	_alt += randf_range(-0.08, 0.08)
	if _tick % 35 == 0:
		_fuel = maxf(10.0, _fuel - 0.05)
	for lbl in _alt_kpi:
		var l: Label = lbl
		l.text = "%.1f" % _alt
	if _clock_label != null:
		var now: Dictionary = Time.get_time_dict_from_system()
		_clock_label.text = "MISSION CLOCK %02d:%02d:%02d" % [now.hour, now.minute, now.second]
	if _stamp_label != null:
		_stamp_label.text = "STREAM %04d" % _tick
	_hist.append(clampf(0.48 + (_alt - 100.0) / 420.0 + randf() * 0.025, 0.08, 0.92))
	if _hist.size() > 55:
		_hist.pop_front()
	var s1: PackedFloat32Array = PackedFloat32Array()
	for v in _hist:
		s1.append(float(v))
	var s2: PackedFloat32Array = PackedFloat32Array()
	for v in _hist:
		s2.append(minf(0.95, float(v) * 0.8 + 0.1))
	var s3: PackedFloat32Array = PackedFloat32Array()
	for v in _hist:
		s3.append(minf(0.95, _power / 3.0 + randf() * 0.03))
	for plot in _plots:
		var p: Plot = plot
		p.set_series([s1, s2, s3])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("nav_exit"):
		get_viewport().set_input_as_handled()
		InterfaceSfx.play(self, "click")
		closed.emit()
		var flow := get_node_or_null("/root/SceneFlow")
		if flow != null:
			flow.go_to_stage("interplanetary")
		elif ResourceLoader.exists(STANDBY_SCENE):
			get_tree().change_scene_to_file(STANDBY_SCENE)


# =========================================================================== #
#  Shared builders
# =========================================================================== #

func _lbl(text: String, fs: int = 12, color: Color = C_TXT) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	return l


func _row(sep: int = 8) -> HBoxContainer:
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


func _vbox(sep: int = 8) -> VBoxContainer:
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


func _spacer() -> Control:
	var c: Control = Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


func _panel() -> PanelBox:
	return PanelBox.new()


func _titled(pb: PanelBox, title: String) -> void:
	pb.box.add_child(_lbl(title, 12, Color("cfe7ff")))


func _button(text: String, primary: bool = false, danger: bool = false) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 12)
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color("0b2350") if primary else Color(0.078, 0.169, 0.302)
	sb.border_color = C_CYAN if primary else Color("2c5787")
	if danger:
		sb.bg_color = Color("451c32")
		sb.border_color = Color("a8485e")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(7)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	var hover: StyleBoxFlat = sb.duplicate()
	hover.border_color = C_CYAN
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", sb)
	b.add_theme_color_override("font_color", C_TXT)
	b.add_theme_color_override("font_hover_color", C_CYAN)
	b.pressed.connect(func() -> void: InterfaceSfx.play(self, "click"))
	return b


func _kv(parent: PanelBox, key: String, value: String, value_color: Color = C_TXT) -> Label:
	var h: HBoxContainer = _row(6)
	h.add_child(_lbl(key, 11, C_MUTED))
	h.add_child(_spacer())
	var v: Label = _lbl(value, 11, value_color)
	h.add_child(v)
	parent.box.add_child(h)
	return v


func _meter(parent: PanelBox, label: String, frac: float, value: String, color: Color = C_CYAN) -> void:
	var h: HBoxContainer = _row(6)
	h.add_child(_lbl(label, 11, C_MUTED))
	h.add_child(_spacer())
	h.add_child(_lbl(value, 11, C_CYAN))
	parent.box.add_child(h)
	parent.box.add_child(HBar.new(frac, color))


func _slider_row(parent: PanelBox, label: String, mn: float, mx: float, val: float, step: float = 1.0) -> Label:
	var h: HBoxContainer = _row(6)
	h.add_child(_lbl(label, 11, C_MUTED))
	h.add_child(_spacer())
	var readout: Label = _lbl("%d" % int(val), 11, C_CYAN)
	h.add_child(readout)
	parent.box.add_child(h)
	var s: HSlider = HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = step
	s.value = val
	s.custom_minimum_size = Vector2(0, 16)
	s.value_changed.connect(func(x: float) -> void: readout.text = "%.0f" % x)
	parent.box.add_child(s)
	return readout


func _note(parent: PanelBox, text: String) -> void:
	var l: Label = _lbl(text, 10, C_MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.box.add_child(l)


func _set_flex(node: Control, factor: float) -> void:
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_stretch_ratio = factor


# =========================================================================== #
#  Build
# =========================================================================== #

func _build() -> void:
	_build_background()
	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	root.add_child(_build_header())
	root.add_child(_build_nav())

	_content = Control.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(_content)

	_build_section_overview()
	_build_section_flight()
	_build_section_power()
	_build_section_crew()
	_build_section_archive()
	_build_section_library()
	_build_section_logs()
	_build_section_navigation()
	_build_section_surface()
	_build_section_engineering()

	_build_overlays()


func _build_background() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.color = C_BG
	var mat: ShaderMaterial = ShaderMaterial.new()
	var shader_path: String = "res://PARALLAX/Navigator/theme/grid_background.gdshader"
	if ResourceLoader.exists(shader_path):
		mat.shader = load(shader_path) as Shader
	bg.material = mat
	add_child(bg)


func _build_header() -> Control:
	var holder: Control = Control.new()
	holder.custom_minimum_size.y = 70.0
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.027, 0.075, 0.149, 0.85)
	sb.border_color = C_LINE
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	holder.add_child(panel)

	var row: HBoxContainer = _row(14)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(row)

	var sigil: Panel = Panel.new()
	var sig_sb: StyleBoxFlat = StyleBoxFlat.new()
	sig_sb.bg_color = Color("0a5f78")
	sig_sb.set_corner_radius_all(10)
	sigil.add_theme_stylebox_override("panel", sig_sb)
	sigil.custom_minimum_size = Vector2(44, 44)
	sigil.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sig_lbl: Label = _lbl("✦", 22, C_TXT)
	sig_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sig_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sig_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sigil.add_child(sig_lbl)
	row.add_child(sigil)

	var brand: VBoxContainer = _vbox(0)
	brand.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	brand.add_child(_lbl("KARADI DEEP-SPACE OPERATIONS // NODE SRI-K", 9, C_CYAN))
	brand.add_child(_lbl("SRI KALYAN · ORBITAL FLIGHT COMMAND", 16, C_TXT))
	row.add_child(brand)
	row.add_child(_spacer())

	var status: HBoxContainer = _row(8)
	status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status.add_child(_pill("KARADI LINK NOMINAL", C_GREEN))
	var clock_pill: PanelContainer = _pill_wrap()
	_clock_label = _lbl("MISSION CLOCK --:--:--", 10, C_MUTED)
	clock_pill.add_child(_clock_label)
	status.add_child(clock_pill)
	var audio: Button = _button("🔊 Audio OFF")
	audio.pressed.connect(func() -> void: _toggle_audio(audio))
	status.add_child(audio)
	row.add_child(status)
	return holder


func _pill(text: String, dot_color: Color) -> PanelContainer:
	var p: PanelContainer = _pill_wrap()
	var h: HBoxContainer = _row(6)
	var dot: ColorRect = ColorRect.new()
	dot.color = dot_color
	dot.custom_minimum_size = Vector2(7, 7)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(dot)
	h.add_child(_lbl(text, 10, C_MUTED))
	p.add_child(h)
	return p


func _pill_wrap() -> PanelContainer:
	var p: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.10, 0.17, 0.85)
	sb.border_color = C_LINE
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", sb)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


func _toggle_audio(btn: Button) -> void:
	_sound_on = not _sound_on
	btn.text = "🔊 Audio ON" if _sound_on else "🔊 Audio OFF"
	InterfaceSfx.play(self, "confirm")


func _build_nav() -> Control:
	var holder: Control = Control.new()
	holder.custom_minimum_size.y = 40.0
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.add_child(scroll)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	scroll.add_child(margin)
	var hb: HBoxContainer = _row(6)
	margin.add_child(hb)
	for t in TABS:
		var d: Dictionary = t
		var tab: SectionTab = SectionTab.new(str(d["label"]))
		tab.pressed.connect(_select.bind(str(d["id"])))
		hb.add_child(tab)
		_tabs[str(d["id"])] = tab
	return holder


func _new_section(id: String) -> VBoxContainer:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.visible = false
	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(margin)
	var v: VBoxContainer = _vbox(12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(v)
	_content.add_child(scroll)
	_sections[id] = scroll
	return v


func _select(id: String, with_sound: bool = true) -> void:
	_current = id
	if with_sound:
		InterfaceSfx.play(self, "click")
	for key in _tabs.keys():
		(_tabs[key] as SectionTab).set_active(str(key) == id)
	for key2 in _sections.keys():
		var sc: ScrollContainer = _sections[key2]
		var on: bool = str(key2) == id
		sc.visible = on
		if on:
			ParallaxMotion.fade_in(sc, 0.16, 0.4)


# ---- Overview ------------------------------------------------------------- #

func _build_section_overview() -> void:
	var v: VBoxContainer = _new_section("overview")

	var metrics: HBoxContainer = _row(12)
	metrics.add_child(_metric_tile("ORBITAL ALTITUDE", "100.0", " km", 0.62, C_CYAN))
	metrics.add_child(_metric_tile("ATTITUDE / PITCH", "+2.4", "°", 0.51, C_BLUE))
	metrics.add_child(_metric_tile("BUS POWER", "1.84", " kW", 0.73, C_GREEN))
	metrics.add_child(_metric_tile("THERMAL BALANCE", "+18.2", "°C", 0.48, C_AMBER))
	metrics.add_child(_metric_tile("PROPULSION RESERVE", "82", "%", 0.82, C_CYAN))
	v.add_child(metrics)

	var mid: HBoxContainer = _row(12)
	var chart_p: PanelBox = _panel()
	_titled(chart_p, "ORBITAL TELEMETRY · LIVE FLIGHT PROFILE")
	var plot: Plot = Plot.new()
	chart_p.box.add_child(plot)
	_plots.append(plot)
	var stamp_row: HBoxContainer = _row(6)
	stamp_row.add_child(_lbl("ALTITUDE / ATTITUDE / POWER NORMALISED", 9, C_MUTED))
	stamp_row.add_child(_spacer())
	_stamp_label = _lbl("STREAM 0000", 9, C_MUTED)
	stamp_row.add_child(_stamp_label)
	chart_p.box.add_child(stamp_row)
	mid.add_child(chart_p)
	_set_flex(chart_p, 2.0)

	var board_p: PanelBox = _panel()
	_titled(board_p, "MISSION DIRECTOR'S BOARD")
	var alert_box: Label = _lbl("All flight constraints nominal. Navigation solution converged.", 10, C_GREEN)
	alert_box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board_p.box.add_child(alert_box)
	_kv(board_p, "Next manoeuvre", "Europa transfer trim")
	_kv(board_p, "Command window", "00:18:42")
	_kv(board_p, "Ground relay", "DSN · simulated")
	var btns: HBoxContainer = _row(8)
	var bc: Button = _button("Run flight checklist", true)
	bc.pressed.connect(_run_checklist)
	btns.add_child(bc)
	var br: Button = _button("Request status from Manic")
	br.pressed.connect(func() -> void: _log_line("STATUS REQUEST sent to Manic · reply received", "ok"))
	btns.add_child(br)
	board_p.box.add_child(btns)
	mid.add_child(board_p)
	_set_flex(board_p, 1.0)
	v.add_child(mid)

	var lower: HBoxContainer = _row(12)
	var health_p: PanelBox = _panel()
	_titled(health_p, "SPACECRAFT SYSTEMS HEALTH")
	for h in [["Guidance & navigation", 96], ["Propulsion feed", 89], ["Power management", 94], ["Thermal regulation", 91], ["Communications array", 97], ["Radiation monitor", 88]]:
		var arr: Array = h
		_meter(health_p, str(arr[0]), float(arr[1]) / 100.0, "%d%%" % int(arr[1]))
	lower.add_child(health_p)
	_set_flex(health_p, 1.0)
	var traffic_p: PanelBox = _panel()
	_titled(traffic_p, "RECENT KARADI / KARADI KUTTY TRAFFIC")
	for m in [["Manic", "Karadi Kutty power forecast"], ["Varun", "Jovian carrier anomaly"], ["Amrish", "Priority sample metadata request"]]:
		var arr2: Array = m
		traffic_p.box.add_child(_lbl("%s · %s" % [str(arr2[0]), str(arr2[1])], 11, C_TXT))
		traffic_p.box.add_child(_lbl("Awaiting downlink window.", 10, C_MUTED))
	lower.add_child(traffic_p)
	_set_flex(traffic_p, 1.0)
	v.add_child(lower)

	var map_p: PanelBox = _panel()
	_titled(map_p, "MISSION CONTROL MAP · NOT TO SCALE")
	map_p.box.add_child(MapView.new("jupiter", 260.0))
	_note(map_p, "Illustrative mission display. Position and route are fictional training telemetry, not live NASA tracking.")
	v.add_child(map_p)


func _metric_tile(label: String, value: String, unit: String, frac: float, color: Color) -> PanelBox:
	var p: PanelBox = _panel()
	p.box.add_child(_lbl(label, 10, C_MUTED))
	var h: HBoxContainer = _row(2)
	var val: Label = _lbl(value, 24, C_TXT)
	if label == "ORBITAL ALTITUDE":
		_alt_kpi.append(val)
	h.add_child(val)
	h.add_child(_lbl(unit, 11, C_MUTED))
	p.box.add_child(h)
	p.box.add_child(HBar.new(frac, color))
	_set_flex(p, 1.0)
	return p


# ---- Flight --------------------------------------------------------------- #

func _build_section_flight() -> void:
	var v: VBoxContainer = _new_section("flight")
	var top: HBoxContainer = _row(12)
	var cmd_p: PanelBox = _panel()
	_titled(cmd_p, "FLIGHT DYNAMICS · COMMAND THE VEHICLE")
	var plot: Plot = Plot.new()
	cmd_p.box.add_child(plot)
	_plots.append(plot)
	_slider_row(cmd_p, "Target altitude", 50, 250, 100)
	_slider_row(cmd_p, "Pitch angle", -45, 45, 2.4, 0.1)
	_slider_row(cmd_p, "Yaw angle", -90, 90, 0.0, 0.1)
	_slider_row(cmd_p, "Roll angle", -180, 180, 0.0, 0.1)
	_slider_row(cmd_p, "Thrust vector", 0, 100, 42)
	_slider_row(cmd_p, "Reaction wheel rate", 0, 100, 18)
	var row: HBoxContainer = _row(8)
	var bex: Button = _button("EXECUTE MANOEUVRE", true)
	bex.pressed.connect(_execute_manoeuvre)
	row.add_child(bex)
	var bst: Button = _button("AUTO-STABILISE")
	bst.pressed.connect(func() -> void: _log_line("AUTO-STABILISE engaged · attitude setpoint zeroed", "ok"))
	row.add_child(bst)
	var brst: Button = _button("RESET PROFILE")
	brst.pressed.connect(func() -> void: _log_line("Flight profile reset to nominal training state", "ok"))
	row.add_child(brst)
	cmd_p.box.add_child(row)
	top.add_child(cmd_p)
	_set_flex(cmd_p, 2.0)

	var gauge_p: PanelBox = _panel()
	_titled(gauge_p, "ATTITUDE INDICATOR")
	var gauge: Gauge = Gauge.new()
	gauge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	gauge_p.box.add_child(gauge)
	gauge_p.box.add_child(_lbl("Attitude deviation within tolerance.", 10, C_GREEN))
	top.add_child(gauge_p)
	_set_flex(gauge_p, 1.0)
	v.add_child(top)

	var lower: HBoxContainer = _row(12)
	var queue_p: PanelBox = _panel()
	_titled(queue_p, "MANOEUVRE QUEUE")
	queue_p.box.add_child(_lbl("No manoeuvres submitted.", 10, C_MUTED))
	lower.add_child(queue_p)
	_set_flex(queue_p, 1.0)
	var rules_p: PanelBox = _panel()
	_titled(rules_p, "FLIGHT RULES / SAFETY INTERLOCKS")
	for r in ["• Pitch excursion above ±25° triggers caution siren.", "• Altitude command delta above 120 km triggers major-change alarm.", "• Thrust command above 85% requires confirmation.", "• Emergency hold freezes simulated attitude commands.", "• All actions are local training simulation; no spacecraft is controlled."]:
		rules_p.box.add_child(_lbl(str(r), 10, C_MUTED))
	lower.add_child(rules_p)
	_set_flex(rules_p, 1.0)
	v.add_child(lower)


func _execute_manoeuvre() -> void:
	_log_line("MANOEUVRE EXECUTED · guidance solution updated", "ok")
	_show_toast("Manoeuvre accepted · guidance solution updated")


# ---- Power ---------------------------------------------------------------- #

func _build_section_power() -> void:
	var v: VBoxContainer = _new_section("power")
	var top: HBoxContainer = _row(12)
	var loads_p: PanelBox = _panel()
	_titled(loads_p, "POWER DISTRIBUTION · BUS LOAD MANAGER")
	var loads: Array = [["Guidance & navigation", 0.42, true], ["Communications / HGA", 0.38, true], ["Thermal control", 0.31, true], ["Science payload", 0.46, false], ["Habitat / crew support", 0.18, true], ["Imaging & data storage", 0.09, false]]
	for l in loads:
		var arr: Array = l
		_meter(loads_p, str(arr[0]), float(arr[1]) / 0.55, "%.2f kW" % float(arr[1]))
	var row: HBoxContainer = _row(8)
	var bb: Button = _button("AUTO-BALANCE LOADS", true)
	bb.pressed.connect(func() -> void: _log_line("POWER AUTO-BALANCE · noncritical loads throttled", "ok"))
	row.add_child(bb)
	var bs: Button = _button("SHED NON-CRITICAL")
	bs.pressed.connect(func() -> void: _log_line("NON-CRITICAL LOAD SHED · duty cycles reduced", "warn"))
	row.add_child(bs)
	loads_p.box.add_child(row)
	top.add_child(loads_p)
	_set_flex(loads_p, 1.0)

	var thermal_p: PanelBox = _panel()
	_titled(thermal_p, "THERMAL CONTROL LOOP")
	_slider_row(thermal_p, "Radiator aperture", 0, 100, 58)
	_slider_row(thermal_p, "Heater duty", 0, 100, 24)
	_slider_row(thermal_p, "Coolant pump", 0, 100, 62)
	thermal_p.box.add_child(_lbl("Thermal loop stable. Radiator and coolant pump nominal.", 10, C_GREEN))
	top.add_child(thermal_p)
	_set_flex(thermal_p, 1.0)
	v.add_child(top)

	var lower: HBoxContainer = _row(12)
	var chart_p: PanelBox = _panel()
	_titled(chart_p, "LOAD PROFILE · POWER GENERATION VS CONSUMPTION")
	var plot: Plot = Plot.new()
	chart_p.box.add_child(plot)
	_plots.append(plot)
	lower.add_child(chart_p)
	_set_flex(chart_p, 2.0)
	var strat_p: PanelBox = _panel()
	_titled(strat_p, "POWER STRATEGY")
	_note(strat_p, "Europa Clipper is powered by large solar arrays, not an RTG. Its arrays supply at least 700 W through the prime mission at Jupiter. This station models a fictional Karadi power bus with adjustable subsystem priorities.")
	_note(strat_p, "RTGs convert heat from radioactive decay into electricity and are not used by Europa Clipper.")
	lower.add_child(strat_p)
	_set_flex(strat_p, 1.0)
	v.add_child(lower)


# ---- Crew ----------------------------------------------------------------- #

func _build_section_crew() -> void:
	var v: VBoxContainer = _new_section("crew")
	var top: HBoxContainer = _row(12)
	var cards_p: PanelBox = _panel()
	_titled(cards_p, "KARADI CREW NETWORK · PEOPLE, ROLES & LIVE REQUESTS")
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	cards_p.box.add_child(grid)
	for c in CREW:
		var d: Dictionary = c
		grid.add_child(_crew_card(str(d["icon"]), str(d["name"]), str(d["role"]), str(d["station"])))
	top.add_child(cards_p)
	_set_flex(cards_p, 2.0)

	var inbox_p: PanelBox = _panel()
	_titled(inbox_p, "INBOX · INCOMING TRANSMISSIONS")
	inbox_p.box.add_child(_lbl("Manic — Karadi Kutty power forecast", 11, C_TXT))
	inbox_p.box.add_child(_lbl("Varun — Jovian carrier anomaly", 11, C_TXT))
	inbox_p.box.add_child(_lbl("Amrish — Priority sample metadata request", 11, C_TXT))
	var irow: HBoxContainer = _row(8)
	var bn: Button = _button("Simulate incoming packet")
	bn.pressed.connect(func() -> void: _log_line("INCOMING TRANSMISSION · base energy update", "warn"))
	irow.add_child(bn)
	var bm: Button = _button("Mark all read")
	bm.pressed.connect(func() -> void: _show_toast("All transmissions marked read"))
	irow.add_child(bm)
	inbox_p.box.add_child(irow)
	top.add_child(inbox_p)
	_set_flex(inbox_p, 1.0)
	v.add_child(top)

	var lower: HBoxContainer = _row(12)
	var dm_p: PanelBox = _panel()
	_titled(dm_p, "DIRECT MESSAGE COMPOSER")
	_kv(dm_p, "Recipient", "Manic")
	_kv(dm_p, "Priority", "ROUTINE")
	var msg: LineEdit = LineEdit.new()
	msg.placeholder_text = "Type a flight update or request..."
	dm_p.box.add_child(msg)
	var bs: Button = _button("TRANSMIT MESSAGE", true)
	bs.pressed.connect(func() -> void:
		_log_line("OUTGOING MESSAGE → relay", "ok")
		_show_toast("Message packet queued for relay")
		msg.text = "")
	dm_p.box.add_child(bs)
	lower.add_child(dm_p)
	_set_flex(dm_p, 1.0)

	var manic_p: PanelBox = _panel()
	_titled(manic_p, "MANIC · BASE OPERATIONS CROSS-LINK")
	var reply: Label = _lbl("MANIC: Karadi Kutty base reports stable environmental systems. Awaiting your orbital power forecast.", 10, C_GREEN)
	reply.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	manic_p.box.add_child(reply)
	var mrow: HBoxContainer = _row(8)
	for a in [["power", "Request base power forecast"], ["weather", "Request surface weather"], ["samples", "Request sample inventory"]]:
		var arr: Array = a
		var b: Button = _button(str(arr[1]))
		b.pressed.connect(func() -> void:
			reply.text = "MANIC: %s report received." % str(arr[0]).capitalize()
			_log_line("MANIC CROSS-LINK · %s report received" % str(arr[0]), "ok"))
		mrow.add_child(b)
	manic_p.box.add_child(mrow)
	lower.add_child(manic_p)
	_set_flex(manic_p, 1.0)
	v.add_child(lower)


func _crew_card(icon: String, cname: String, role: String, station: String) -> PanelContainer:
	var p: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = C_PANEL2
	sb.border_color = C_LINE
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", sb)
	var v: VBoxContainer = _vbox(4)
	p.add_child(v)
	var h: HBoxContainer = _row(8)
	var av: Panel = Panel.new()
	var asb: StyleBoxFlat = StyleBoxFlat.new()
	asb.bg_color = Color("164f70")
	asb.set_corner_radius_all(9)
	av.add_theme_stylebox_override("panel", asb)
	av.custom_minimum_size = Vector2(36, 36)
	var al: Label = _lbl(icon, 13, C_CYAN)
	al.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	al.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av.add_child(al)
	h.add_child(av)
	var names: VBoxContainer = _vbox(0)
	names.add_child(_lbl(cname, 12, C_TXT))
	names.add_child(_lbl(role, 9, C_MUTED))
	h.add_child(names)
	v.add_child(h)
	var st: Label = _lbl(station, 10, C_MUTED)
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(st)
	return p


# ---- Archive -------------------------------------------------------------- #

func _build_section_archive() -> void:
	var v: VBoxContainer = _new_section("archive")
	var search_p: PanelBox = _panel()
	_titled(search_p, "MISSION ARCHIVE SEARCH · CREW RECORDS, REPORTS & FILES")
	var row: HBoxContainer = _row(8)
	var field: LineEdit = LineEdit.new()
	field.placeholder_text = "Search: Amrish, xenobiology, KADAL, rover, radio astronomy..."
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.text_changed.connect(func(_t: String) -> void: _refresh_archive(field.text))
	row.add_child(field)
	var bs: Button = _button("SEARCH ARCHIVE", true)
	bs.pressed.connect(func() -> void: _refresh_archive(field.text))
	row.add_child(bs)
	var bc: Button = _button("CLEAR")
	bc.pressed.connect(func() -> void:
		field.text = ""
		_refresh_archive(""))
	row.add_child(bc)
	search_p.box.add_child(row)

	var filters: HBoxContainer = _row(8)
	for f in [["all", "All records"], ["crew", "Crew dossiers"], ["science", "Science"], ["engineering", "Engineering"], ["comms", "Communications"]]:
		var arr: Array = f
		var fb: Button = _button(str(arr[1]))
		fb.pressed.connect(func() -> void:
			_archive_filter = str(arr[0])
			_refresh_archive(field.text))
		filters.add_child(fb)
	search_p.box.add_child(filters)
	v.add_child(search_p)

	var lower: HBoxContainer = _row(12)
	var res_p: PanelBox = _panel()
	_archive_results = _vbox(6)
	res_p.box.add_child(_archive_results)
	lower.add_child(res_p)
	_set_flex(res_p, 2.0)
	var file_p: PanelBox = _panel()
	_titled(file_p, "FILE OPERATIONS")
	_note(file_p, "Create a local mission note, export it, or attach it to the flight recorder.")
	var note: TextEdit = TextEdit.new()
	note.custom_minimum_size = Vector2(0, 90)
	note.placeholder_text = "Enter flight observation..."
	file_p.box.add_child(note)
	var fr: HBoxContainer = _row(8)
	var fs: Button = _button("SAVE TO ARCHIVE", true)
	fs.pressed.connect(func() -> void:
		_log_line("PILOT NOTE saved to local mission archive", "ok")
		_show_toast("Note saved in this session"))
	fr.add_child(fs)
	var fe: Button = _button("EXPORT ARCHIVE CSV")
	fe.pressed.connect(func() -> void: _show_toast("Export is a session-only demo action"))
	fr.add_child(fe)
	file_p.box.add_child(fr)
	lower.add_child(file_p)
	_set_flex(file_p, 1.0)
	v.add_child(lower)
	_refresh_archive("")


func _refresh_archive(query: String) -> void:
	if _archive_results == null:
		return
	for c in _archive_results.get_children():
		c.queue_free()
	var q: String = query.to_lower()
	for a in ARCHIVE:
		var arr: Array = a
		if _archive_filter != "all" and str(arr[1]) != _archive_filter:
			continue
		if q != "" and not ("%s %s %s" % [str(arr[0]), str(arr[1]), str(arr[2])]).to_lower().contains(q):
			continue
		_archive_results.add_child(_lbl(str(arr[0]), 11, C_TXT))
		var d: Label = _lbl(str(arr[2]), 10, C_MUTED)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_archive_results.add_child(d)


# ---- Library -------------------------------------------------------------- #

func _build_section_library() -> void:
	var v: VBoxContainer = _new_section("library")
	var src_p: PanelBox = _panel()
	_titled(src_p, "EXTERNAL KNOWLEDGE GATEWAY · NASA / JPL / PDS")
	_note(src_p, "Curated public mission references. This offline dashboard does not fetch live NASA data.")
	var row: HBoxContainer = _row(8)
	var field: LineEdit = LineEdit.new()
	field.placeholder_text = "Filter sources: instruments, spacecraft, trajectory, archive..."
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.text_changed.connect(func(_t: String) -> void: _refresh_sources(field.text))
	row.add_child(field)
	var bf: Button = _button("FILTER")
	bf.pressed.connect(func() -> void: _refresh_sources(field.text))
	row.add_child(bf)
	src_p.box.add_child(row)
	_source_list = _vbox(6)
	src_p.box.add_child(_source_list)
	v.add_child(src_p)

	var lower: HBoxContainer = _row(12)
	var intel_p: PanelBox = _panel()
	_titled(intel_p, "SPACECRAFT INTELLIGENCE · EUROPA CLIPPER")
	_kv(intel_p, "Launch", "14 October 2024")
	_kv(intel_p, "Jupiter arrival", "2030 (planned)")
	_kv(intel_p, "Science instruments", "9 + gravity/radio")
	_kv(intel_p, "Power source", "Solar arrays")
	_kv(intel_p, "Propulsion", "24 engines")
	_kv(intel_p, "Europa close flybys", "~49 planned")
	_note(intel_p, "NASA mission reference facts. Karadi's orbital telemetry remains fictional.")
	lower.add_child(intel_p)
	_set_flex(intel_p, 1.0)
	var route_p: PanelBox = _panel()
	_titled(route_p, "DATA ARCHIVE ROUTING")
	_note(route_p, "NASA PDS — NASA's long-term archive for planetary science data.")
	_note(route_p, "NASA Eyes — interactive mission visualization.")
	_note(route_p, "JPL Horizons — ephemerides and geometry for solar-system bodies.")
	lower.add_child(route_p)
	_set_flex(route_p, 1.0)
	v.add_child(lower)
	_refresh_sources("")


func _refresh_sources(query: String) -> void:
	if _source_list == null:
		return
	for c in _source_list.get_children():
		c.queue_free()
	var q: String = query.to_lower()
	for s in SOURCES:
		var arr: Array = s
		if q != "" and not ("%s %s" % [str(arr[0]), str(arr[1])]).to_lower().contains(q):
			continue
		var h: HBoxContainer = _row(6)
		h.add_child(_lbl(str(arr[0]), 11, C_TXT))
		h.add_child(_spacer())
		h.add_child(_lbl(str(arr[2]).to_upper(), 9, C_CYAN))
		_source_list.add_child(h)
		var d: Label = _lbl(str(arr[1]), 10, C_MUTED)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_source_list.add_child(d)


# ---- Logs ----------------------------------------------------------------- #

func _build_section_logs() -> void:
	var v: VBoxContainer = _new_section("logs")
	var top: HBoxContainer = _row(12)
	var rec_p: PanelBox = _panel()
	_titled(rec_p, "FLIGHT RECORDER · EVENT STREAM")
	var row: HBoxContainer = _row(8)
	var bc: Button = _button("CLEAR DISPLAY")
	bc.pressed.connect(func() -> void:
		if _log != null:
			_log.text = "")
	row.add_child(bc)
	var be: Button = _button("EXPORT LOG CSV")
	be.pressed.connect(func() -> void: _show_toast("Export is a session-only demo action"))
	row.add_child(be)
	var bd: Button = _button("RUN FULL DIAGNOSTIC")
	bd.pressed.connect(_run_checklist)
	row.add_child(bd)
	rec_p.box.add_child(row)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.custom_minimum_size = Vector2(0, 340)
	_log.add_theme_font_size_override("normal_font_size", 11)
	rec_p.box.add_child(_log)
	top.add_child(rec_p)
	_set_flex(rec_p, 2.0)

	var status_p: PanelBox = _panel()
	_titled(status_p, "RECORDER STATUS")
	_kv(status_p, "Buffer occupancy", "14%")
	_kv(status_p, "Packet integrity", "99.98%")
	_kv(status_p, "Clock sync", "±0.8 ms")
	_kv(status_p, "Last checksum", "A71C-90D2")
	status_p.box.add_child(_lbl("Recorder online · local session storage enabled.", 10, C_GREEN))
	top.add_child(status_p)
	_set_flex(status_p, 1.0)
	v.add_child(top)

	_log_line("KARADI FLIGHT COMMAND online · pilot console authenticated", "ok")
	_log_line("MISSION SIMULATION initialized · NASA reference gateway loaded", "ok")
	_log_line("EUROPA ORBITAL NAVIGATION online · relative position solution acquired", "ok")
	_log_line("SURFACE TRACKING online · Thera Macula crew telemetry linked", "ok")
	_log_line("ENGINEERING BAY online · thruster, power source and avionics controls ready", "ok")


func _log_line(msg: String, kind: String = "ok") -> void:
	if _log == null:
		return
	var col: String = {"ok": "5af0b1", "warn": "ffc66d", "err": "ff647c"}.get(kind, "9ed6c9")
	var stamp: Dictionary = Time.get_time_dict_from_system()
	_log.append_text("[color=#55789e][%02d:%02d:%02d][/color] [color=#%s]%s[/color]\n" % [stamp.hour, stamp.minute, stamp.second, col, msg])


func _run_checklist() -> void:
	for item in ["GNC star tracker solution: PASS", "Reaction wheel momentum: PASS", "Propellant feed pressure: PASS", "High-gain antenna pointing: PASS", "Power bus isolation: PASS", "Thermal loop setpoints: PASS", "Crew relay schedule: PASS"]:
		_log_line("CHECKLIST · " + item, "ok")
	_show_toast("Flight checklist running · results in recorder")


# ---- Navigation ----------------------------------------------------------- #

func _build_section_navigation() -> void:
	var v: VBoxContainer = _new_section("navigation")
	var top: HBoxContainer = _row(12)
	var map_p: PanelBox = _panel()
	_titled(map_p, "EUROPA ORBITAL NAVIGATION · RELATIVE POSITION")
	map_p.box.add_child(MapView.new("europa", 340.0))
	_note(map_p, "Illustrative orbital geometry. Europa's orbital period around Jupiter is ~3.55 Earth days; Europa is tidally locked.")
	top.add_child(map_p)
	_set_flex(map_p, 2.0)

	var sol_p: PanelBox = _panel()
	_titled(sol_p, "ORBIT SOLUTION")
	_kv(sol_p, "Altitude above surface", "100.0 km")
	_kv(sol_p, "Orbital velocity", "1.37 km/s")
	_kv(sol_p, "Europa orbital phase", "042.0°")
	_kv(sol_p, "Ground track", "THERA MACULA")
	sol_p.box.add_child(_lbl("Navigation solution converged · orbit stable", 10, C_GREEN))
	var br: Button = _button("RECALCULATE ORBIT", true)
	br.pressed.connect(func() -> void: _log_line("ORBIT SOLUTION RECALCULATED · Europa phase updated", "ok"))
	sol_p.box.add_child(br)
	top.add_child(sol_p)
	_set_flex(sol_p, 1.0)
	v.add_child(top)

	var lower: HBoxContainer = _row(12)
	var params_p: PanelBox = _panel()
	_titled(params_p, "ORBITAL PARAMETERS")
	var plot: Plot = Plot.new()
	plot.custom_minimum_size = Vector2(0, 120)
	params_p.box.add_child(plot)
	_plots.append(plot)
	_note(params_p, "Altitude and velocity trend · simulated telemetry history")
	lower.add_child(params_p)
	_set_flex(params_p, 1.0)
	var approach_p: PanelBox = _panel()
	_titled(approach_p, "RELATIVE POSITION / APPROACH")
	_meter(approach_p, "Orbital insertion progress", 0.86, "86%")
	_meter(approach_p, "Surface relay geometry", 0.91, "GOOD", C_GREEN)
	_note(approach_p, "The orbital spacecraft remains the relay hub between Varun, mission control and the Thera Macula habitat.")
	lower.add_child(approach_p)
	_set_flex(approach_p, 1.0)
	v.add_child(lower)


# ---- Surface -------------------------------------------------------------- #

func _build_section_surface() -> void:
	var v: VBoxContainer = _new_section("surface")
	var top: HBoxContainer = _row(12)
	var map_p: PanelBox = _panel()
	_titled(map_p, "THERA MACULA · ASTRONAUT SURFACE TRACKING")
	map_p.box.add_child(MapView.new("surface", 330.0))
	_note(map_p, "Relative positions are simulated. Crew movement, suit telemetry and task status update during the session.")
	top.add_child(map_p)
	_set_flex(map_p, 2.0)

	var crew_p: PanelBox = _panel()
	_titled(crew_p, "CREW TELEMETRY · SURFACE TEAM")
	for c in [["Manic", "BASE", 91], ["Krish", "EVA", 76], ["Dhanush", "EVA", 68], ["Amrish", "EVA", 96]]:
		var arr: Array = c
		_meter(crew_p, "%s · suit oxygen" % str(arr[0]), float(arr[2]) / 100.0, "%d%%" % int(arr[2]), C_GREEN if str(arr[1]) == "BASE" else C_CYAN)
	top.add_child(crew_p)
	_set_flex(crew_p, 1.0)
	v.add_child(top)

	var lower: HBoxContainer = _row(12)
	var base_p: PanelBox = _panel()
	_titled(base_p, "BASE ENVIRONMENT & SUPPLIES")
	for b in [["Oxygen reserve", 88], ["Water reserve", 72], ["Food reserve", 81], ["Habitat pressure", 96], ["CO₂ scrubber efficiency", 67], ["Base power reserve", 74]]:
		var arr: Array = b
		_meter(base_p, str(arr[0]), float(arr[1]) / 100.0, "%d%%" % int(arr[1]))
	lower.add_child(base_p)
	_set_flex(base_p, 1.0)
	var ops_p: PanelBox = _panel()
	_titled(ops_p, "FIELD OPERATIONS / REQUESTS")
	ops_p.box.add_child(_lbl("Krish · KANDAM route hazard", 11, C_TXT))
	ops_p.box.add_child(_lbl("A fresh fracture has opened 140 m east of waypoint K-04.", 10, C_MUTED))
	ops_p.box.add_child(_lbl("Dhanush · KADAL power fluctuation", 11, C_TXT))
	ops_p.box.add_child(_lbl("Drill motor current is oscillating; need a stable power allocation.", 10, C_MUTED))
	var row: HBoxContainer = _row(8)
	var bs: Button = _button("SEND SUPPORT WINDOW", true)
	bs.pressed.connect(func() -> void:
		_log_line("SURFACE SUPPORT WINDOW transmitted to Thera Macula", "ok")
		_show_toast("Support window sent to surface team"))
	row.add_child(bs)
	var br: Button = _button("REFRESH TELEMETRY")
	br.pressed.connect(func() -> void: _log_line("SURFACE SUIT TELEMETRY refreshed", "ok"))
	row.add_child(br)
	ops_p.box.add_child(row)
	lower.add_child(ops_p)
	_set_flex(ops_p, 1.0)
	v.add_child(lower)


# ---- Engineering ---------------------------------------------------------- #

func _build_section_engineering() -> void:
	var v: VBoxContainer = _new_section("engineering")
	var r1: HBoxContainer = _row(12)
	var thr_p: PanelBox = _panel()
	_titled(thr_p, "THRUSTER MAINTENANCE · VECTOR CONTROL")
	thr_p.box.add_child(_lbl("Thruster bank A nominal · bank B nominal", 10, C_GREEN))
	_slider_row(thr_p, "Bank A valve aperture", 0, 100, 72)
	_slider_row(thr_p, "Bank B valve aperture", 0, 100, 68)
	_slider_row(thr_p, "Ignition timing offset", -50, 50, 0)
	var row: HBoxContainer = _row(8)
	var bd: Button = _button("RUN THRUSTER DIAGNOSTIC", true)
	bd.pressed.connect(func() -> void: _log_line("Thruster diagnostic PASS", "ok"))
	row.add_child(bd)
	var bc: Button = _button("CALIBRATE / REPAIR")
	bc.pressed.connect(func() -> void: _log_line("Thruster calibration complete · vector control restored", "ok"))
	row.add_child(bc)
	thr_p.box.add_child(row)
	r1.add_child(thr_p)
	_set_flex(thr_p, 1.0)

	var src_p: PanelBox = _panel()
	_titled(src_p, "POWER SOURCE CONFIGURATION")
	_slider_row(src_p, "Solar array contribution", 0, 240, 145)
	_slider_row(src_p, "Battery discharge", 0, 150, 39)
	_slider_row(src_p, "Backup fuel-cell contribution", 0, 100, 20)
	_kv(src_p, "Available generation", "2.04 kW")
	src_p.box.add_child(_lbl("Generation margin positive", 10, C_GREEN))
	r1.add_child(src_p)
	_set_flex(src_p, 1.0)
	v.add_child(r1)

	var r2: HBoxContainer = _row(12)
	var sw_p: PanelBox = _panel()
	_titled(sw_p, "FLIGHT SOFTWARE / AVIONICS")
	_kv(sw_p, "GNC firmware", "v4.8.2 · verified")
	_kv(sw_p, "Navigation kernel", "RUNNING", C_GREEN)
	_kv(sw_p, "Thruster controller", "RUNNING", C_GREEN)
	_kv(sw_p, "Telemetry checksum", "A91F-20C4")
	var bp: Button = _button("VERIFY & PATCH SOFTWARE", true)
	bp.pressed.connect(func() -> void:
		_log_line("Flight software integrity verified · GNC firmware v4.8.3", "ok")
		_show_toast("Software verification complete"))
	sw_p.box.add_child(bp)
	r2.add_child(sw_p)
	_set_flex(sw_p, 1.0)
	var hist_p: PanelBox = _panel()
	_titled(hist_p, "ENGINEERING EVENT HISTORY")
	hist_p.box.add_child(_lbl("No events recorded this session.", 10, C_MUTED))
	r2.add_child(hist_p)
	_set_flex(hist_p, 1.0)
	v.add_child(r2)


# ---- Overlays ------------------------------------------------------------- #

func _build_overlays() -> void:
	_alarm_layer = ColorRect.new()
	_alarm_layer.color = Color(0.01, 0.03, 0.08, 0.85)
	_alarm_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_alarm_layer.visible = false
	add_child(_alarm_layer)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_alarm_layer.add_child(center)
	var card: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color("251329")
	sb.border_color = C_RED
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", sb)
	center.add_child(card)
	var cv: VBoxContainer = _vbox(10)
	cv.custom_minimum_size.x = 380
	card.add_child(cv)
	cv.add_child(_lbl("⚠", 34, C_RED))
	_alarm_title = _lbl("FLIGHT CONSTRAINT ALERT", 16, Color("ff8092"))
	cv.add_child(_alarm_title)
	_alarm_text = _lbl("Flight parameter outside nominal envelope.", 11, C_MUTED)
	_alarm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cv.add_child(_alarm_text)
	var ack: Button = _button("ACKNOWLEDGE ALARM", false, true)
	ack.pressed.connect(func() -> void: _alarm_layer.visible = false)
	cv.add_child(ack)

	_toast = Panel.new()
	var tsb: StyleBoxFlat = StyleBoxFlat.new()
	tsb.bg_color = Color("12324b")
	tsb.border_color = C_CYAN
	tsb.set_border_width_all(1)
	tsb.set_corner_radius_all(10)
	_toast.add_theme_stylebox_override("panel", tsb)
	_toast.anchor_left = 1.0
	_toast.anchor_right = 1.0
	_toast.anchor_top = 1.0
	_toast.anchor_bottom = 1.0
	_toast.offset_left = -340
	_toast.offset_right = -20
	_toast.offset_top = -70
	_toast.offset_bottom = -20
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)
	_toast_label = _lbl("", 11, C_TXT)
	_toast_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast.add_child(_toast_label)


func _show_toast(message: String) -> void:
	if _toast == null:
		return
	_toast_label.text = message
	var tw: Tween = create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.15)
	tw.tween_interval(2.2)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)


func _show_alarm(title: String, text: String) -> void:
	if _alarm_layer == null:
		return
	_alarm_title.text = title
	_alarm_text.text = text
	_alarm_layer.visible = true
	InterfaceSfx.play(self, "warning")