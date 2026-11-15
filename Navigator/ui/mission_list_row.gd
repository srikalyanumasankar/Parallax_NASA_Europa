class_name MissionListRow
extends Button

## PARALLAX — one clickable row in the mission list: stable id, status and title.

var mission_id: String = ""
var title: String = ""
var state: String = MissionDefinitions.STATUS_LOCKED
var selected: bool = false


func _init(id: String = "", row_title: String = "") -> void:
	mission_id = id
	title = row_title


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size.y = 46.0
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_restyle()


func set_row_state(new_state: String) -> void:
	state = new_state
	_restyle()
	queue_redraw()


func set_selected(is_selected: bool) -> void:
	selected = is_selected
	_restyle()
	queue_redraw()


func _restyle() -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.07, 0.19, 0.27, 0.55) if selected else Color(0, 0, 0, 0)
	normal.border_width_left = 2 if selected else 0
	normal.border_color = ParallaxPalette.CYAN
	normal.content_margin_left = 10.0
	normal.content_margin_right = 10.0

	var hover: StyleBoxFlat = normal.duplicate()
	if not selected:
		hover.bg_color = Color(0.06, 0.14, 0.20, 0.45)
		hover.border_width_left = 2
		hover.border_color = ParallaxPalette.CYAN_DIM
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", normal)


func _draw() -> void:
	var font: Font = get_theme_default_font()
	var fs: int = ParallaxPalette.F_SMALL + 1
	draw_string(font, Vector2(12.0, 18.0), mission_id, HORIZONTAL_ALIGNMENT_LEFT, size.x - 110.0, fs, ParallaxPalette.TEXT_FAINT)
	var scol: Color = ParallaxPalette.status_color(state)
	draw_string(font, Vector2(size.x - 110.0, 18.0), state, HORIZONTAL_ALIGNMENT_RIGHT, 98.0, fs, scol)
	var tcol: Color = ParallaxPalette.TEXT_DIM if state == MissionDefinitions.STATUS_LOCKED else ParallaxPalette.TEXT
	draw_string(font, Vector2(12.0, 36.0), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 20.0, ParallaxPalette.F_LABEL + 1, tcol)
	draw_line(Vector2(0.0, size.y - 0.5), Vector2(size.x, size.y - 0.5), ParallaxPalette.BORDER_FAINT, 1.0)