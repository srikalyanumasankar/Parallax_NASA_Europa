class_name PlaceholderSection
extends Control

## PARALLAX — a clearly-labelled stand-in for a section implemented in a later
## phase. Never pretends to be functional.

var section_title: String = ""
var description: String = ""
var phase_text: String = ""


func _init(title: String = "", desc: String = "", phase: String = "") -> void:
	section_title = title
	description = desc
	phase_text = phase


func _ready() -> void:
	var frame: PanelFrame = PanelFrame.new(section_title, ParallaxPalette.BLUE)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.get_content().add_child(center)

	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	center.add_child(col)

	var badge: Label = ParallaxPalette.label(phase_text, ParallaxPalette.F_LABEL + 2, ParallaxPalette.AMBER)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(badge)

	var head: Label = ParallaxPalette.label(section_title, ParallaxPalette.F_TITLE, ParallaxPalette.CYAN_SOFT)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(head)

	var body: Label = ParallaxPalette.label(description, ParallaxPalette.F_HEAD, ParallaxPalette.TEXT_DIM)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 460
	col.add_child(body)