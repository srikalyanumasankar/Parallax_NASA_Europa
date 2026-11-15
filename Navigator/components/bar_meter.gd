class_name BarMeter
extends Control

## PARALLAX — a labelled horizontal status bar (power, fuel, temperature …).

var label_text: String = ""
var value: float = 0.0          # 0..1 fill
var value_text: String = ""
var bar_color: Color = ParallaxPalette.CYAN
var warn: bool = false


func _init(text: String = "", v: float = 0.0) -> void:
	label_text = text
	value = v
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 26)


func set_state(v: float, text: String, color: Color = ParallaxPalette.CYAN, warning: bool = false) -> void:
	value = clampf(v, 0.0, 1.0)
	value_text = text
	bar_color = color
	warn = warning
	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var font: Font = get_theme_default_font()
	var fs: int = ParallaxPalette.F_SMALL + 1

	draw_string(font, Vector2(0.0, 11.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, w - 90.0, fs, ParallaxPalette.TEXT)
	var vcol: Color = ParallaxPalette.AMBER if warn else ParallaxPalette.CYAN_SOFT
	draw_string(font, Vector2(w - 90.0, 11.0), value_text, HORIZONTAL_ALIGNMENT_RIGHT, 90.0, fs, vcol)

	var bar_y: float = 17.0
	var bar_h: float = 6.0
	draw_rect(Rect2(0.0, bar_y, w, bar_h), Color(0.05, 0.10, 0.17, 0.9), true)
	var fill_w: float = w * clampf(value, 0.0, 1.0)
	if fill_w > 0.5:
		draw_rect(Rect2(0.0, bar_y, fill_w, bar_h), bar_color, true)
	draw_rect(Rect2(0.0, bar_y, w, bar_h), ParallaxPalette.BORDER, false, 1.0)