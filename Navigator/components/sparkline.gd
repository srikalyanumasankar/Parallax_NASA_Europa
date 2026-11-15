class_name Sparkline
extends Control

## PARALLAX — a small clean telemetry graph (line + soft fill + baseline).

var line_color: Color = ParallaxPalette.CYAN
var fill_color: Color = Color(0.22, 0.82, 0.95, 0.10)
var values: PackedFloat32Array = PackedFloat32Array()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 22)


func set_values(v: PackedFloat32Array) -> void:
	values = v
	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 4.0 or h < 4.0:
		return
	# Baseline / frame
	draw_line(Vector2(0.0, h - 0.5), Vector2(w, h - 0.5), ParallaxPalette.BORDER_FAINT, 1.0)
	if values.size() < 2:
		return

	var lo: float = values[0]
	var hi: float = values[0]
	for v in values:
		lo = minf(lo, v)
		hi = maxf(hi, v)
	var span: float = maxf(hi - lo, 0.0001)
	var n: int = values.size()
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(n):
		var x: float = (float(i) / float(n - 1)) * w
		var t: float = (values[i] - lo) / span
		var y: float = h - 2.0 - t * (h - 4.0)
		pts.append(Vector2(x, y))

	# Soft area fill
	var poly: PackedVector2Array = pts.duplicate()
	poly.append(Vector2(w, h))
	poly.append(Vector2(0.0, h))
	draw_colored_polygon(poly, fill_color)
	draw_polyline(pts, line_color, 1.5, true)
	# Highlight the latest sample
	draw_circle(pts[n - 1], 2.0, line_color)