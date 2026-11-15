class_name AlertIndicator
extends Control

## PARALLAX — the mission alert lamp in the top status bar. Idle it reads a dim
## "NONE"; when the shared event bus raises an alert it blinks for a moment and
## then holds a steady amber (WARNING) or red (CRITICAL) lamp until cleared.

const BLINK_S: float = 1.4

var _label: Label
var _lamp: ColorRect
var _color: Color = ParallaxPalette.AMBER
var _timer: float = 0.0
var _blink: float = 0.0
var _active: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_build()
	set_process(false)


func _build() -> void:
	custom_minimum_size = Vector2(128, 0)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	_lamp = ColorRect.new()
	_lamp.color = ParallaxPalette.TEXT_FAINT
	_lamp.custom_minimum_size = Vector2(10, 10)
	_lamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_lamp)

	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", -2)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	col.add_child(ParallaxPalette.caption("ALERT"))
	_label = ParallaxPalette.label("NONE", ParallaxPalette.F_LABEL + 1, ParallaxPalette.TEXT_DIM)
	_label.clip_text = true
	_label.custom_minimum_size.x = 116
	col.add_child(_label)


## Raise (or update) the alert lamp.
func set_alert(level: String, text: String) -> void:
	if _label == null:
		return
	var upper: String = level.to_upper()
	_active = true
	_color = ParallaxPalette.RED if upper == "CRITICAL" else ParallaxPalette.AMBER
	_label.text = ("%s  ·  %s" % [upper, text]) if text != "" else upper
	_label.add_theme_color_override("font_color", _color)
	if _lamp != null:
		_lamp.color = _color
	_timer = BLINK_S
	_blink = 0.0
	set_process(true)


func clear_alert() -> void:
	_active = false
	_timer = 0.0
	set_process(false)
	if _lamp != null:
		_lamp.color = ParallaxPalette.TEXT_FAINT
	if _label != null:
		_label.text = "NONE"
		_label.add_theme_color_override("font_color", ParallaxPalette.TEXT_DIM)


func is_active() -> bool:
	return _active


func alert_text() -> String:
	return _label.text if _label != null else ""


func _process(delta: float) -> void:
	_blink += delta
	_timer -= delta
	if _timer > 0.0:
		# Blink phase.
		if _lamp != null:
			_lamp.color = _color if fmod(_blink, 0.3) < 0.15 else Color(0.0, 0.0, 0.0, 0.0)
	else:
		# Settle to a steady lamp and stop ticking.
		if _lamp != null:
			_lamp.color = _color
		set_process(false)