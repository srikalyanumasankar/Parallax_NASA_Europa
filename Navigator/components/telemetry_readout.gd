class_name TelemetryReadout
extends Control

## PARALLAX — a single telemetry readout: dim label, large value, right-aligned
## unit and an optional inline sparkline.

var label_text: String = ""
var value_text: String = "--"
var unit_text: String = ""
var value_color: Color = ParallaxPalette.CYAN_SOFT
var show_spark: bool = true
var spark: Sparkline


func _init(label: String = "", value: String = "--", unit: String = "", color: Color = ParallaxPalette.CYAN_SOFT) -> void:
	label_text = label
	value_text = value
	unit_text = unit
	value_color = color
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 46)


func _ready() -> void:
	spark = Sparkline.new()
	spark.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	spark.offset_top = -20.0
	spark.offset_left = 0.0
	spark.offset_right = 0.0
	spark.offset_bottom = 0.0
	add_child(spark)
	if not show_spark:
		spark.hide()


func set_value(text: String, color: Color = ParallaxPalette.CYAN_SOFT) -> void:
	value_text = text
	value_color = color
	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var font: Font = get_theme_default_font()
	draw_string(font, Vector2(0.0, 12.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, w, ParallaxPalette.F_SMALL, ParallaxPalette.TEXT_DIM)
	draw_string(font, Vector2(0.0, 31.0), value_text, HORIZONTAL_ALIGNMENT_LEFT, w - 80.0, ParallaxPalette.F_VALUE, value_color)
	if unit_text != "":
		draw_string(font, Vector2(w - 80.0, 31.0), unit_text, HORIZONTAL_ALIGNMENT_RIGHT, 80.0, ParallaxPalette.F_SMALL, ParallaxPalette.TEXT_FAINT)
	if show_spark:
		draw_line(Vector2(0.0, 36.0), Vector2(w, 36.0), ParallaxPalette.BORDER_FAINT, 1.0)