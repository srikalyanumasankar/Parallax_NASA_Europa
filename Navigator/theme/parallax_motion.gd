class_name ParallaxMotion
extends RefCounted

## PARALLAX — shared motion helpers for the console's transitions, so every
## panel and alert animates with the same feel.

const FADE: float = 0.20


## Fades a control in from `from_alpha` to fully opaque. Returns the running
## Tween, or null when the node cannot animate yet.
static func fade_in(node: CanvasItem, duration: float = FADE, from_alpha: float = 0.0) -> Tween:
	if node == null or not is_instance_valid(node) or node.get_tree() == null:
		return null
	node.modulate.a = from_alpha
	var tween: Tween = node.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate:a", 1.0, duration)
	return tween


## Briefly tints a control with `color`, then restores it. Used to draw the eye
## to a value that just changed.
static func flash(node: CanvasItem, color: Color, duration: float = 0.5) -> Tween:
	if node == null or not is_instance_valid(node) or node.get_tree() == null:
		return null
	node.modulate = color
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "modulate", Color.WHITE, duration)
	return tween