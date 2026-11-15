class_name StatusPill
extends Control

## PARALLAX — a compact status chip: a coloured dot, a dim key and a coloured
## value (e.g. "PHR  STABLE").

var key_text: String = ""
var value_text: String = ""
var state_color: Color = ParallaxPalette.GREEN


func _init(key: String = "", value: String = "", color: Color = ParallaxPalette.GREEN) -> void:
	key_text = key
	value_text = value
	state_color = color
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 22)


func set_state(key: String, value: String, color: Color) -> void:
	key_text = key
	value_text = value
	state_color = color
	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var sb: StyleBoxFlat = ParallaxPalette.panel_style(Color(0.05, 0.10, 0.17, 0.85), ParallaxPalette.BORDER, 2, 1)
	draw_style_box(sb, Rect2(Vector2.ZERO, Vector2(w, h)))
	var font: Font = get_theme_default_font()
	var cy: float = h * 0.5 + 3.5
	draw_circle(Vector2(9.0, h * 0.5), 2.5, state_color)
	draw_string(font, Vector2(17.0, cy), key_text, HORIZONTAL_ALIGNMENT_LEFT, w - 22.0, ParallaxPalette.F_SMALL, ParallaxPalette.TEXT_DIM)
	draw_string(font, Vector2(40.0, cy), value_text, HORIZONTAL_ALIGNMENT_RIGHT, w - 46.0, ParallaxPalette.F_SMALL, state_color)