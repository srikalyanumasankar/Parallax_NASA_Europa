class_name Emblem
extends Control

## PARALLAX mission emblem: a ringed planet with an inclined orbit.


func _init() -> void:
	custom_minimum_size = Vector2(40, 40)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.5 - 2.0
	draw_arc(c, r, 0.0, TAU, 48, ParallaxPalette.CYAN, 1.5, true)
	# Inclined orbit ellipse
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(49):
		var a: float = TAU * float(i) / 48.0
		pts.append(c + Vector2(cos(a) * r * 1.06, sin(a) * r * 0.40))
	draw_polyline(pts, ParallaxPalette.BLUE, 1.0, true)
	# Planet
	draw_circle(c, r * 0.33, ParallaxPalette.CYAN_SOFT)
	draw_arc(c, r * 0.33, 0.0, TAU, 24, ParallaxPalette.WHITE, 1.0, true)
	# Moon on orbit
	var ang: float = -0.7
	draw_circle(c + Vector2(cos(ang) * r * 1.06, sin(ang) * r * 0.40), 2.0, ParallaxPalette.WHITE)