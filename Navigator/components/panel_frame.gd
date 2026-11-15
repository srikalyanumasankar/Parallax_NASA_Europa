class_name PanelFrame
extends Control

## PARALLAX — reusable framed panel: near-black surface, thin technical border,
## an accent tab, a header rule and corner brackets. Add content to
## `get_content()` (a MarginContainer).

const HEADER_H: float = 27.0

var title: String = ""
var hint: String = ""
var accent: Color = ParallaxPalette.CYAN
var fill: Color = ParallaxPalette.PANEL_FILL

var _content: MarginContainer
var _hint_label: Label
var _title_label: Label


func _init(title_text: String = "", accent_color: Color = ParallaxPalette.CYAN) -> void:
	title = title_text
	accent = accent_color
	mouse_filter = Control.MOUSE_FILTER_PASS


func _ready() -> void:
	_ensure_build()
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)


func _ensure_build() -> void:
	if _content == null:
		_build()


func get_content() -> MarginContainer:
	_ensure_build()
	return _content


func set_hint(text: String) -> void:
	hint = text
	if _hint_label != null:
		_hint_label.text = text


func set_title(text: String) -> void:
	title = text
	if _title_label != null:
		_title_label.text = text
		queue_redraw()


func _build() -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	var header: HBoxContainer = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, HEADER_H)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(header)

	_title_label = ParallaxPalette.label(title, ParallaxPalette.F_LABEL + 1, ParallaxPalette.TEXT)
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_constant_override("outline_size", 0)
	_title_label.custom_minimum_size.x = 4
	header.add_child(_title_label)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(spacer)

	_hint_label = ParallaxPalette.caption(hint)
	_hint_label.name = "Hint"
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_hint_label)

	_content = MarginContainer.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("margin_left", 11)
	_content.add_theme_constant_override("margin_right", 11)
	_content.add_theme_constant_override("margin_top", 8)
	_content.add_theme_constant_override("margin_bottom", 10)
	box.add_child(_content)


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	# Surface
	var sb: StyleBoxFlat = ParallaxPalette.panel_style(fill, ParallaxPalette.BORDER, 3, 1)
	draw_style_box(sb, Rect2(Vector2.ZERO, Vector2(w, h)))
	# Header rule
	if title != "" or hint != "":
		draw_line(Vector2(0.0, HEADER_H), Vector2(w, HEADER_H), ParallaxPalette.BORDER_BRIGHT, 1.0)
		# Accent tab on the far left of the header
		draw_rect(Rect2(0.0, 7.0, 2.0, HEADER_H - 14.0), accent, true)
	# Corner brackets
	var c: float = 7.0
	var col: Color = ParallaxPalette.BORDER_BRIGHT
	draw_line(Vector2(0.5, c), Vector2(0.5, 0.5), col, 1.0)
	draw_line(Vector2(0.5, 0.5), Vector2(c, 0.5), col, 1.0)
	draw_line(Vector2(w - c, 0.5), Vector2(w - 0.5, 0.5), col, 1.0)
	draw_line(Vector2(w - 0.5, 0.5), Vector2(w - 0.5, c), col, 1.0)
	draw_line(Vector2(0.5, h - c), Vector2(0.5, h - 0.5), col, 1.0)
	draw_line(Vector2(0.5, h - 0.5), Vector2(c, h - 0.5), col, 1.0)
	draw_line(Vector2(w - c, h - 0.5), Vector2(w - 0.5, h - 0.5), col, 1.0)
	draw_line(Vector2(w - 0.5, h - 0.5), Vector2(w - 0.5, h - c), col, 1.0)