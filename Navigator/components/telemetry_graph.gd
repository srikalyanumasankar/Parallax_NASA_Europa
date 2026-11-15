class_name TelemetryGraph
extends Control

## PARALLAX — a readable telemetry history graph: a framed plot with gridlines,
## min/max scale labels, a soft area fill, the trace and the latest sample.

var title: String = ""
var unit: String = ""
var line_color: Color = ParallaxPalette.CYAN
var values: PackedFloat32Array = PackedFloat32Array()


func _init(graph_title: String = "", graph_unit: String = "", color: Color = ParallaxPalette.CYAN) -> void:
	title = graph_title
	unit = graph_unit
	line_color = color
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 96)


func set_values(v: PackedFloat32Array) -> void:
	values = v
	queue_redraw()


func current_value() -> float:
	return values[values.size() - 1] if values.size() > 0 else 0.0


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 10.0 or h < 10.0:
		return
	var font: Font = get_theme_default_font()
	var fs: int = ParallaxPalette.F_SMALL
	var plot: Rect2 = Rect2(Vector2(1.0, 16.0), Vector2(w - 2.0, h - 26.0))

	draw_rect(plot, Color(0.03, 0.06, 0.11, 0.75), true)
	for i in range(1, 4):
		var gy: float = plot.position.y + plot.size.y * (float(i) / 4.0)
		draw_line(Vector2(plot.position.x, gy), Vector2(plot.position.x + plot.size.x, gy), ParallaxPalette.BORDER_FAINT, 1.0)
	draw_rect(plot, ParallaxPalette.BORDER, false, 1.0)

	draw_string(font, Vector2(0.0, 11.0), title, HORIZONTAL_ALIGNMENT_LEFT, w - 96.0, fs, ParallaxPalette.TEXT_DIM)

	if values.size() < 2:
		draw_string(font, Vector2(plot.position.x + 6.0, plot.position.y + 14.0), "AWAITING SAMPLES", HORIZONTAL_ALIGNMENT_LEFT, plot.size.x, fs, ParallaxPalette.TEXT_FAINT)
		return

	var lo: float = values[0]
	var hi: float = values[0]
	for v in values:
		lo = minf(lo, v)
		hi = maxf(hi, v)
	# A flat trace would divide by zero; centre it instead of padding the scale,
	# so the min/max labels keep showing the real values.
	var flat: bool = is_equal_approx(hi, lo)
	var span: float = maxf(hi - lo, 1.0e-9)
	var n: int = values.size()

	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(n):
		var x: float = plot.position.x + (float(i) / float(n - 1)) * plot.size.x
		var t: float = 0.5 if flat else (values[i] - lo) / span
		var y: float = plot.position.y + plot.size.y - 2.0 - t * (plot.size.y - 4.0)
		pts.append(Vector2(x, y))

	var poly: PackedVector2Array = pts.duplicate()
	poly.append(Vector2(plot.position.x + plot.size.x, plot.position.y + plot.size.y))
	poly.append(Vector2(plot.position.x, plot.position.y + plot.size.y))
	draw_colored_polygon(poly, Color(line_color.r, line_color.g, line_color.b, 0.10))
	draw_polyline(pts, line_color, 1.5, true)
	draw_circle(pts[n - 1], 2.5, line_color)

	# Scale labels (max top-left, min bottom-left) and the latest value.
	draw_string(font, Vector2(plot.position.x + 4.0, plot.position.y + 11.0), String.num(hi, 2), HORIZONTAL_ALIGNMENT_LEFT, 60.0, fs, ParallaxPalette.TEXT_FAINT)
	draw_string(font, Vector2(plot.position.x + 4.0, plot.position.y + plot.size.y - 4.0), String.num(lo, 2), HORIZONTAL_ALIGNMENT_LEFT, 60.0, fs, ParallaxPalette.TEXT_FAINT)
	draw_string(font, Vector2(w - 94.0, 11.0), "%s %s" % [String.num(values[n - 1], 2), unit], HORIZONTAL_ALIGNMENT_RIGHT, 94.0, fs, line_color)