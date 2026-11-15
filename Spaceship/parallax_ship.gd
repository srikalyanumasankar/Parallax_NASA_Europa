class_name ParallaxShip
extends Node3D

## PARALLAX — the playable ship scene. It uses the Sci-Fi Starter Kit interior
## (Example_01) as the ship hull and fits it with the navigation console. Approach
## the console, press the interaction key, and the full-screen in-game browser
## console (html_console.tscn) loads the mission dashboard. Leaving that console
## hands off to the standby screen instead of returning here. Mission state lives
## in the shared autoload, so it survives the change of scene.

const INTERACT_RANGE: float = 4.5
const CONSOLE_DISTANCE: float = 3.0

## Full-screen HTML console opened when the player interacts with the console.
## It is loaded as its own scene (the ship is left behind) and does not return.
const HTML_CONSOLE_SCENE: String = "res://PARALLAX/Navigator/html_console.tscn"

var _player: Node3D
var _console: NavigationConsole
var _is_open: bool = false


static func within_range(a: Vector3, b: Vector3, range_m: float) -> bool:
	return a.distance_to(b) <= range_m


func _ready() -> void:
	_player = _find_player()
	_console = get_node_or_null("NavigationConsole") as NavigationConsole

	_place_console()
	if _console != null:
		_console.set_prompt_visible(false)

	# The player controller captures the mouse on start; make sure our own
	# start-up state wins now that all children are ready.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _find_player() -> Node3D:
	var c: Node = get_node_or_null("Ship/Character")
	if c is Node3D:
		return c as Node3D
	return null


func _place_console() -> void:
	if _player == null or _console == null:
		return
	var forward: Vector3 = -_player.global_transform.basis.z
	forward.y = 0.0
	if forward.length() < 0.05:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var target: Vector3 = _player.global_position + forward * CONSOLE_DISTANCE
	_console.global_position = target
	_console.look_at(Vector3(_player.global_position.x, target.y, _player.global_position.z), Vector3.UP)


func _process(_delta: float) -> void:
	if _is_open or _console == null or _player == null:
		return
	var near: bool = within_range(_player.global_position, _console.global_position, INTERACT_RANGE)
	_console.set_prompt_visible(near)
	# Poll the action so the interaction works with any input source.
	# Poll the held state (not just the press edge) so the interaction is reliable
	# across frame rates and input sources; _is_open guards against repeats.
	if near and Input.is_action_pressed("interact"):
		_open_console()


## Event-driven interaction, complementing the polled check in _process(): opens
## the console from any input source that delivers the "interact" action as an
## event (keyboard, gamepad, replayed input).
func _unhandled_input(event: InputEvent) -> void:
	if _is_open or _console == null or _player == null:
		return
	if event.is_action_pressed("interact") and _in_range():
		# Consume the event before leaving the scene, since _open_console()
		# changes scene and the viewport reference can go away.
		get_viewport().set_input_as_handled()
		_open_console()


func _in_range() -> bool:
	if _player == null or _console == null:
		return false
	return within_range(_player.global_position, _console.global_position, INTERACT_RANGE)


func _open_console() -> void:
	_is_open = true
	if _console != null:
		_console.set_prompt_visible(false)
	if _player != null and "frozen" in _player:
		_player.frozen = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Leave the ship entirely: the in-game browser console becomes the scene.
	if ResourceLoader.exists(HTML_CONSOLE_SCENE):
		get_tree().change_scene_to_file(HTML_CONSOLE_SCENE)


func is_console_open() -> bool:
	return _is_open