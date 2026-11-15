class_name StandbyScreen
extends Control

## PARALLAX — the hand-off screen shown after the ship's navigation console is
## left. Exiting the HTML console never returns to the 3D ship; control comes
## here instead.
##
## This stands in for the mission's "next scene": give NEXT_SCENE a path once
## that scene exists and ESC from here will continue straight into it.

const NEXT_SCENE: String = ""  # e.g. "res://PARALLAX/Mission/mission_01.tscn"


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("nav_exit"):
		get_viewport().set_input_as_handled()
		_continue()


## Advance to the next scene, or quit cleanly when none is configured yet.
func _continue() -> void:
	if NEXT_SCENE != "" and ResourceLoader.exists(NEXT_SCENE):
		get_tree().change_scene_to_file(NEXT_SCENE)
	else:
		get_tree().quit()