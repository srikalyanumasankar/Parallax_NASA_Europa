class_name NavigationConsole
extends Node3D

## PARALLAX — the physical navigation console in the 3D ship. It is a proximity
## target: when the player is close, its prompt lights up; the ship controller
## opens the 2D navigator console.

@onready var prompt: Label3D = $Prompt


func set_prompt_visible(value: bool) -> void:
	if prompt != null:
		prompt.visible = value