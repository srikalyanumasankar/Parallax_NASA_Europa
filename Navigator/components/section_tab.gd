class_name SectionTab
extends Button

## PARALLAX — a section-selector tab with an active underline. Used by the
## Navigator's top segment bar and bottom function bar.

var active: bool = false


func _init(tab_text: String = "") -> void:
	text = tab_text


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	custom_minimum_size.y = 32.0
	add_theme_font_size_override("font_size", ParallaxPalette.F_LABEL + 1)
	_apply()


func set_active(is_active: bool) -> void:
	if active == is_active:
		return
	active = is_active
	_apply()


func _apply() -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.09, 0.30, 0.42, 0.55) if active else Color(0, 0, 0, 0)
	normal.border_width_bottom = 2 if active else 1
	normal.border_color = ParallaxPalette.CYAN if active else ParallaxPalette.BORDER_FAINT

	var hover: StyleBoxFlat = StyleBoxFlat.new()
	hover.bg_color = Color(0.10, 0.24, 0.34, 0.45)
	hover.border_width_bottom = 2
	hover.border_color = ParallaxPalette.CYAN_DIM

	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", normal)
	add_theme_stylebox_override("focus", normal)
	add_theme_color_override("font_color", ParallaxPalette.CYAN_SOFT if active else ParallaxPalette.TEXT_DIM)
	add_theme_color_override("font_hover_color", ParallaxPalette.CYAN_SOFT)
	add_theme_color_override("font_pressed_color", ParallaxPalette.CYAN)