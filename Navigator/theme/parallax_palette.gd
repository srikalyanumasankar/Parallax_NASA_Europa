class_name ParallaxPalette
extends RefCounted

## PARALLAX — visual identity for the Navigator interface.
## Dark navy / near-black surfaces, cyan & blue highlights, restrained white,
## thin technical borders. Every panel and component pulls its colours from here
## so the interface stays consistent.

const BG_DEEP: Color = Color("04060c")
const BG_PANEL: Color = Color("070c17")
const PANEL_FILL: Color = Color(0.031, 0.055, 0.098, 0.92)
const PANEL_FILL_SOLID: Color = Color("0a1224")
const PANEL_RAISED: Color = Color("0d1830")
const BORDER: Color = Color("173247")
const BORDER_BRIGHT: Color = Color("2b6488")
const BORDER_FAINT: Color = Color(0.09, 0.20, 0.28, 0.55)
const CYAN: Color = Color("38d2f2")
const CYAN_SOFT: Color = Color("8fe6f8")
const CYAN_DIM: Color = Color(0.22, 0.72, 0.90, 0.35)
const BLUE: Color = Color("4d8ad8")
const TEXT: Color = Color("c6d7e6")
const TEXT_DIM: Color = Color("7c93a8")
const TEXT_FAINT: Color = Color("4a5f74")
const AMBER: Color = Color("e0a63c")
const GREEN: Color = Color("4fd18a")
const RED: Color = Color("e05a5f")
const WHITE: Color = Color("eef5fb")

const F_TITLE: int = 23
const F_HEAD: int = 15
const F_LABEL: int = 11
const F_VALUE: int = 15
const F_SMALL: int = 10


static func panel_style(fill: Color = PANEL_FILL, border: Color = BORDER, radius: int = 3, width: int = 1) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	return sb


static func status_color(state: String) -> Color:
	match state:
		"COMPLETED":
			return GREEN
		"AVAILABLE":
			return CYAN
		"ACTIVE":
			return AMBER
		"LOCKED":
			return TEXT_FAINT
		_:
			return TEXT_DIM


static func label(text: String, size: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## A small dim caption label (used for unit / metadata text).
static func caption(text: String) -> Label:
	var l: Label = label(text, F_SMALL, TEXT_DIM)
	return l


## Applies a nested theme font-size/colour to an existing label.
static func style_label(l: Label, size: int, color: Color) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)