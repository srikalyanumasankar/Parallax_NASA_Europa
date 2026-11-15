class_name OrbitalMap
extends Control

## PARALLAX — the interactive top-down orbital display.
##
## Supports zoom (scroll wheel, cursor-anchored), pan (drag), celestial-body and
## spacecraft selection, orbit/trajectory/grid/label overlays, and a schematic
## scale bar. The geometry is a labelled schematic until Phase 3 supplies real
## NASA/JPL ephemerides.

signal selection_changed(body_id: String)
signal view_changed

const MIN_ZOOM: float = 1.5
const MAX_ZOOM: float = 60.0
const TEX_PATH: String = "res://assets/generated/jupiter_planet.png"

var zoom: float = 7.0
var pan: Vector2 = Vector2.ZERO          # world point shown at the view centre
var selected_id: String = "EUROPA"
var hover_id: String = ""

var show_orbits: bool = true
var show_labels: bool = true
var show_trajectory: bool = true
var show_grid: bool = true

var _tex: Texture2D
var _t: float = 0.0
var _dragging: bool = false
var _fitted: bool = false
var _stars: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	focus_mode = Control.FOCUS_ALL


func _ready() -> void:
	if ResourceLoader.exists(TEX_PATH):
		_tex = load(TEX_PATH) as Texture2D
	_build_stars()
	resized.connect(_on_resized)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func fit_view() -> void:
	var max_r: float = 1.0
	for b in OrbitalSchematic.all():
		max_r = maxf(max_r, float(b.get("orbit_radius", 0.0)))
	max_r += 2.0
	zoom = clampf(minf(size.x, size.y) * 0.5 / max_r, MIN_ZOOM, MAX_ZOOM)
	pan = Vector2.ZERO
	_fitted = true
	view_changed.emit()
	queue_redraw()


func select(body_id: String) -> void:
	if body_id == "" or body_id == selected_id:
		return
	selected_id = body_id
	selection_changed.emit(body_id)
	queue_redraw()


func _on_resized() -> void:
	if not _fitted and size.x > 16.0 and size.y > 16.0:
		fit_view()
	queue_redraw()


# --------------------------------------------------------------------------- #
#  Input
# --------------------------------------------------------------------------- #

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(mb.position, 1.18)
			accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(mb.position, 1.0 / 1.18)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				grab_focus()
				_dragging = true
				if mb.button_index == MOUSE_BUTTON_LEFT:
					var hit: String = _pick(mb.position)
					if hit != "":
						select(hit)
			else:
				_dragging = false
			accept_event()
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if _dragging:
			pan -= mm.relative / zoom
			_fitted = true
			view_changed.emit()
			queue_redraw()
		else:
			var h: String = _pick(mm.position)
			if h != hover_id:
				hover_id = h
				queue_redraw()
		accept_event()


func _zoom_at(pos: Vector2, factor: float) -> void:
	var before: Vector2 = _s2w(pos)
	zoom = clampf(zoom * factor, MIN_ZOOM, MAX_ZOOM)
	var after: Vector2 = _s2w(pos)
	pan += before - after
	_fitted = true
	view_changed.emit()
	queue_redraw()


# --------------------------------------------------------------------------- #
#  Coordinate helpers
# --------------------------------------------------------------------------- #

func _w2s(w: Vector2) -> Vector2:
	return size * 0.5 + (w - pan) * zoom


func _s2w(s: Vector2) -> Vector2:
	return pan + (s - size * 0.5) / zoom


func _world_pos(body_id: String) -> Vector2:
	if body_id == "JUPITER":
		return Vector2.ZERO
	var b: Dictionary = OrbitalSchematic.body(body_id)
	if b.is_empty():
		return Vector2.ZERO
	var parent: String = str(b.get("orbit_of", ""))
	var center: Vector2 = Vector2.ZERO if parent == "JUPITER" else _world_pos(parent)
	var speed: float = 0.05 if str(b.get("type", "")) == "MOON" else 0.45
	var ang: float = float(b.get("phase", 0.0)) + _t * speed
	return center + Vector2(cos(ang), sin(ang)) * float(b.get("orbit_radius", 0.0))


func _pick(pos: Vector2) -> String:
	var best: String = ""
	var best_d: float = 1.0e20
	var candidates: Array = OrbitalSchematic.all()
	candidates.append(OrbitalSchematic.SPACECRAFT)
	for body in candidates:
		var b: Dictionary = body
		var sp: Vector2 = _w2s(_world_pos(str(b["id"])))
		var d: float = sp.distance_to(pos)
		var grab: float = maxf(11.0, float(b.get("radius", 0.0)) * zoom * 1.6)
		if d < grab and d < best_d:
			best_d = d
			best = str(b["id"])
	return best


# --------------------------------------------------------------------------- #
#  Drawing
# --------------------------------------------------------------------------- #

func _draw() -> void:
	_draw_stars()
	if show_grid:
		_draw_grid()
	if show_orbits:
		_draw_orbits()
	if show_trajectory:
		_draw_trajectory()
	_draw_bodies()
	_draw_spacecraft()
	_draw_selection()
	_draw_hud()


func _draw_stars() -> void:
	for s in _stars:
		var st: Vector3 = s
		var sp: Vector2 = _w2s(Vector2(st.x, st.y))
		if sp.x < -4.0 or sp.y < -4.0 or sp.x > size.x + 4.0 or sp.y > size.y + 4.0:
			continue
		draw_circle(sp, st.z, Color(0.7, 0.8, 1.0, 0.35))


func _draw_grid() -> void:
	var origin: Vector2 = _w2s(Vector2.ZERO)
	var step: float = 5.0 * zoom
	if step < 22.0:
		step *= 2.0
	var col: Color = ParallaxPalette.BORDER_FAINT
	var x: float = origin.x - ceilf(origin.x / step) * step
	while x < size.x:
		if x >= 0.0:
			draw_line(Vector2(x, 0), Vector2(x, size.y), col, 1.0)
		x += step
	var y: float = origin.y - ceilf(origin.y / step) * step
	while y < size.y:
		if y >= 0.0:
			draw_line(Vector2(0, y), Vector2(size.x, y), col, 1.0)
		y += step
	# Centre axes through Jupiter
	draw_line(Vector2(origin.x, 0), Vector2(origin.x, size.y), ParallaxPalette.BORDER, 1.0)
	draw_line(Vector2(0, origin.y), Vector2(size.x, origin.y), ParallaxPalette.BORDER, 1.0)


func _draw_orbits() -> void:
	for m in OrbitalSchematic.MOONS:
		var b: Dictionary = m
		var c: Vector2 = _w2s(_world_pos(str(b.get("orbit_of", "JUPITER"))))
		var r: float = float(b.get("orbit_radius", 0.0)) * zoom
		if r < 2.0:
			continue
		draw_arc(c, r, 0.0, TAU, 96, ParallaxPalette.BORDER, 1.0, true)
	# Spacecraft orbit around Europa
	var europa: Vector2 = _w2s(_world_pos("EUROPA"))
	draw_arc(europa, float(OrbitalSchematic.SPACECRAFT["orbit_radius"]) * zoom, 0.0, TAU, 64, ParallaxPalette.CYAN_DIM, 1.0, true)


func _draw_trajectory() -> void:
	# A transfer arc from Europa's orbit out toward the Ganymede ring.
	var c: Vector2 = _w2s(Vector2.ZERO)
	var transfer_r: float = (14.5 + 20.5) * 0.5 * zoom
	_dashed_arc(c, transfer_r, -2.4, 0.9, ParallaxPalette.AMBER, 1.5, 9.0)
	var start: Vector2 = c + Vector2(cos(-2.4), sin(-2.4)) * transfer_r
	var end: Vector2 = c + Vector2(cos(0.9), sin(0.9)) * transfer_r
	_arrow(start, (end - start).normalized(), ParallaxPalette.AMBER)
	var mid: Vector2 = c + Vector2(cos(-0.75), sin(-0.75)) * transfer_r
	_text("PLANNED TRAJECTORY", mid + Vector2(8, -6), ParallaxPalette.AMBER, 9)


func _draw_bodies() -> void:
	for b in OrbitalSchematic.all():
		var body: Dictionary = b
		var sp: Vector2 = _w2s(_world_pos(str(body["id"])))
		if sp.x < -80.0 or sp.y < -80.0 or sp.x > size.x + 80.0 or sp.y > size.y + 80.0:
			continue
		var col: Color = body.get("colour", ParallaxPalette.CYAN)
		if str(body["id"]) == "JUPITER" and _tex != null:
			var pr: float = float(body["radius"]) * zoom
			draw_texture_rect(_tex, Rect2(sp - Vector2(pr, pr), Vector2(pr * 2.0, pr * 2.0)), false)
			draw_arc(sp, pr, 0.0, TAU, 64, Color(1.0, 0.88, 0.66, 0.45), 1.0, true)
		else:
			var r: float = maxf(float(body["radius"]) * zoom, 3.0)
			draw_circle(sp, r, col)
			draw_circle(sp - Vector2(r * 0.3, r * 0.3), r * 0.6, col.lightened(0.25))
			draw_arc(sp, r, 0.0, TAU, 32, col.darkened(0.4), 1.0, true)
		if body["id"] == selected_id or body["id"] == hover_id:
			draw_arc(sp, maxf(float(body.get("radius", 0.0)) * zoom, 4.0) + 5.0, 0.0, TAU, 40, ParallaxPalette.CYAN_SOFT, 1.5, true)
		if show_labels:
			var off: float = maxf(float(body.get("radius", 0.0)) * zoom, 4.0) + 10.0
			_text(str(body["name"]).to_upper(), sp + Vector2(off, -off * 0.4), ParallaxPalette.TEXT)


func _draw_spacecraft() -> void:
	var sc: Dictionary = OrbitalSchematic.SPACECRAFT
	var sp: Vector2 = _w2s(_world_pos("AETHER"))
	var d: PackedVector2Array = PackedVector2Array([sp + Vector2(0, -7), sp + Vector2(7, 0), sp + Vector2(0, 7), sp + Vector2(-7, 0)])
	draw_colored_polygon(d, ParallaxPalette.CYAN)
	draw_polyline(PackedVector2Array([d[0], d[1], d[2], d[3], d[0]]), ParallaxPalette.WHITE, 1.0, true)
	if sc["id"] == selected_id or sc["id"] == hover_id:
		draw_arc(sp, 12.0, 0.0, TAU, 32, ParallaxPalette.CYAN_SOFT, 1.5, true)
	# Velocity direction hint
	var vel_dir: Vector2 = Vector2(-sin(_t * 0.45 + float(sc["phase"])), cos(_t * 0.45 + float(sc["phase"]))).normalized()
	_arrow(sp + vel_dir * 9.0, vel_dir, ParallaxPalette.CYAN_SOFT)
	if show_labels:
		_text("AETHER", sp + Vector2(10, 4), ParallaxPalette.CYAN_SOFT)


func _draw_selection() -> void:
	if selected_id == "":
		return
	var sp: Vector2 = _w2s(_world_pos(selected_id))
	var b: Dictionary = OrbitalSchematic.body(selected_id)
	var rr: float = maxf(float(b.get("radius", 0.0)) * zoom, 6.0) + 12.0
	var pulse: float = 0.6 + 0.4 * sin(_t * 2.5)
	var col: Color = Color(ParallaxPalette.CYAN.r, ParallaxPalette.CYAN.g, ParallaxPalette.CYAN.b, pulse)
	var arm: float = rr * 0.5
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var p: Vector2 = sp + corner * rr
		draw_line(p, p + Vector2(-corner.x * arm, 0), col, 1.5)
		draw_line(p, p + Vector2(0, -corner.y * arm), col, 1.5)


func _draw_hud() -> void:
	var font: Font = get_theme_default_font()
	_text("ZOOM  x%s" % String.num(zoom, 1), Vector2(12, 20), ParallaxPalette.CYAN_SOFT, 11)
	_text("DRAG TO PAN · SCROLL TO ZOOM · CLICK AN OBJECT", Vector2(12, 36), ParallaxPalette.TEXT_FAINT, 10)
	if _tex == null:
		_text("JUPITER TEXTURE UNAVAILABLE", Vector2(12, 52), ParallaxPalette.RED, 10)

	# Scale bar (schematic units)
	var world_len: float = _nice_length(110.0 / zoom)
	var px: float = world_len * zoom
	var bx: float = size.x - px - 26.0
	var by: float = size.y - 22.0
	draw_line(Vector2(bx, by), Vector2(bx + px, by), ParallaxPalette.TEXT_DIM, 1.5)
	draw_line(Vector2(bx, by - 4), Vector2(bx, by + 4), ParallaxPalette.TEXT_DIM, 1.5)
	draw_line(Vector2(bx + px, by - 4), Vector2(bx + px, by + 4), ParallaxPalette.TEXT_DIM, 1.5)
	draw_string(font, Vector2(bx, by - 8), "%s u" % String.num(world_len, 0), HORIZONTAL_ALIGNMENT_CENTER, px, 10, ParallaxPalette.TEXT_DIM)
	draw_string(font, Vector2(size.x - 360.0, size.y - 40.0), "SCHEMATIC — NOT TO SCALE", HORIZONTAL_ALIGNMENT_RIGHT, 334.0, 10, ParallaxPalette.AMBER)


# --------------------------------------------------------------------------- #
#  Draw helpers
# --------------------------------------------------------------------------- #

func _text(text: String, pos: Vector2, col: Color, fs: int = 10) -> void:
	draw_string(get_theme_default_font(), pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _dashed_arc(c: Vector2, r: float, a0: float, a1: float, col: Color, width: float, dash: float) -> void:
	if r < 4.0:
		return
	var steps: int = maxi(24, int(absf(a1 - a0) * r / dash))
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(steps + 1):
		var a: float = lerpf(a0, a1, float(i) / float(steps))
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	for i in range(pts.size() - 1):
		if i % 2 == 0:
			draw_line(pts[i], pts[i + 1], col, width)


func _arrow(tip: Vector2, dir: Vector2, col: Color) -> void:
	var back: Vector2 = -dir * 8.0
	draw_line(tip, tip + back + Vector2(-dir.y, dir.x) * 4.0, col, 1.5)
	draw_line(tip, tip + back - Vector2(-dir.y, dir.x) * 4.0, col, 1.5)


func _nice_length(approx: float) -> float:
	if approx <= 0.0:
		return 1.0
	var exponent: float = floor(log(approx) / log(10.0))
	var base: float = pow(10.0, exponent)
	var n: float = approx / base
	var nice: float = 1.0
	if n >= 5.0:
		nice = 5.0
	elif n >= 2.0:
		nice = 2.0
	return nice * base


func _build_stars() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260815
	_stars.clear()
	for i in range(220):
		var p: Vector2 = Vector2(rng.randf_range(-90, 90), rng.randf_range(-90, 90))
		var r: float = rng.randf_range(0.4, 1.2)
		_stars.append(Vector3(p.x, p.y, r))