class_name OrbitalMapPlaceholder
extends Control

## PARALLAX — Phase 1 schematic of the Jupiter system. This is a CLEARLY LABELLED
## schematic preview, NOT a scale drawing and NOT for navigation; the real
## top-down orbital display with NASA/JPL data arrives in Phase 2.

const TEX_PATH: String = "res://assets/generated/jupiter_planet.png"

var _tex: Texture2D
var _t: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func _ready() -> void:
	if ResourceLoader.exists(TEX_PATH):
		_tex = load(TEX_PATH) as Texture2D
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 8.0 or h < 8.0:
		return
	var center: Vector2 = Vector2(w * 0.42, h * 0.52)

	_draw_grid(w, h, center)

	var planet_r: float = minf(w, h) * 0.20
	if _tex != null:
		draw_texture_rect(_tex, Rect2(center - Vector2(planet_r, planet_r), Vector2(planet_r * 2.0, planet_r * 2.0)), false)
	else:
		draw_circle(center, planet_r, Color(0.55, 0.42, 0.30))
	# Terminator shading
	draw_arc(center, planet_r, 0.0, TAU, 64, Color(1.0, 0.85, 0.6, 0.5), 1.5, true)

	# Moon orbits (schematic, squashed for a tilted top-down view)
	var orbits: Array = [
		{"r": 0.34, "name": "IO", "ang": 2.1, "col": ParallaxPalette.AMBER},
		{"r": 0.48, "name": "EUROPA", "ang": 0.5, "col": ParallaxPalette.CYAN},
		{"r": 0.66, "name": "GANYMEDE", "ang": 3.5, "col": ParallaxPalette.TEXT_DIM},
		{"r": 0.86, "name": "CALLISTO", "ang": 1.3, "col": ParallaxPalette.TEXT_FAINT},
	]
	var base: float = minf(w, h) * 0.52
	for o: Dictionary in orbits:
		var rr: float = base * float(o["r"])
		_draw_ellipse(center, rr, rr * 0.38, ParallaxPalette.BORDER, 1.0)
		var ang: float = float(o["ang"])
		var pos: Vector2 = center + Vector2(cos(ang) * rr, sin(ang) * rr * 0.38)
		draw_circle(pos, 3.0, o["col"])
		_font_text(str(o["name"]), pos + Vector2(7.0, 3.0), ParallaxPalette.TEXT_DIM, 9)

	# Spacecraft marker on the Europa orbit
	var europa_r: float = base * 0.48
	var sc_ang: float = 0.5 + _t * 0.12
	var sc: Vector2 = center + Vector2(cos(sc_ang) * europa_r, sin(sc_ang) * europa_r * 0.38)
	draw_line(center, sc, ParallaxPalette.CYAN_DIM, 1.0)
	# Diamond marker
	var d: PackedVector2Array = PackedVector2Array([sc + Vector2(0, -6), sc + Vector2(6, 0), sc + Vector2(0, 6), sc + Vector2(-6, 0)])
	draw_colored_polygon(d, ParallaxPalette.CYAN)
	_font_text("AETHER", sc + Vector2(9.0, 3.0), ParallaxPalette.CYAN_SOFT, 10)

	# Scale / disclaimer
	_font_text("SCHEMATIC PREVIEW  •  NOT TO SCALE  •  NOT FOR NAVIGATION", Vector2(12.0, h - 12.0), ParallaxPalette.AMBER, 10)
	_font_text("TOP-DOWN SYSTEM VIEW  —  REAL DATA IN PHASE 2", Vector2(12.0, 20.0), ParallaxPalette.TEXT_FAINT, 10)


func _draw_grid(w: float, h: float, _c: Vector2) -> void:
	var step: float = 48.0
	var x: float = 0.0
	while x < w:
		draw_line(Vector2(x, 0), Vector2(x, h), ParallaxPalette.BORDER_FAINT, 1.0)
		x += step
	var y: float = 0.0
	while y < h:
		draw_line(Vector2(0, y), Vector2(w, y), ParallaxPalette.BORDER_FAINT, 1.0)
		y += step


func _draw_ellipse(c: Vector2, rx: float, ry: float, col: Color, width: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(97):
		var a: float = TAU * float(i) / 96.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, col, width, true)


func _font_text(text: String, pos: Vector2, col: Color, fs: int) -> void:
	var font: Font = get_theme_default_font()
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)