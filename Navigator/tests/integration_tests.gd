extends Node

## PARALLAX — Phase 8 integration tests (integration_tests.gd).
## Verifies the hosted-navigator open/close contract, the console prompt toggle,
## and the interaction-range gate used by the 3D ship.

func test_navigator_hosted_open_close() -> void:
	var nav: NavigatorScreen = load("res://PARALLAX/Navigator/navigator.tscn").instantiate()
	add_child(nav)
	nav.hosted = true
	var closed: Array = [false]
	nav.closed.connect(func() -> void: closed[0] = true)
	nav.open()
	_ok(nav.is_open(), "open() marks the console open")
	nav.close()
	_ok(not nav.is_open(), "close() marks the console closed")
	_ok(closed[0], "close() emits 'closed' so the host can restore control")
	remove_child(nav)
	nav.free()


func test_console_prompt_toggle() -> void:
	var console: NavigationConsole = load("res://PARALLAX/Spaceship/navigation_console.tscn").instantiate()
	add_child(console)
	console.set_prompt_visible(true)
	_ok(console.prompt.visible, "prompt is shown when the player is in range")
	console.set_prompt_visible(false)
	_ok(not console.prompt.visible, "prompt is hidden when out of range")
	remove_child(console)
	console.free()


func test_interaction_range() -> void:
	_ok(ParallaxShip.within_range(Vector3.ZERO, Vector3(3, 0, 0), 3.5), "3 m is within a 3.5 m range")
	_ok(not ParallaxShip.within_range(Vector3.ZERO, Vector3(4, 0, 0), 3.5), "4 m is outside a 3.5 m range")
	_ok(ParallaxShip.within_range(Vector3.ZERO, Vector3(0, 95, 0), 100.0), "95 m is within a 100 m range")
	_ok(not ParallaxShip.within_range(Vector3(1, 1, 1), Vector3(1, 1, 1) + Vector3(10, 0, 0), 3.5), "10 m is outside")


## NOTE: the full ship scene embeds the kit interior, whose own materials emit
## PRE-EXISTING engine warnings when loaded, so the ship scene is verified by
## RUNNING it live (prompt → open → exit) rather than instantiating it in a test.


# --------------------------------------------------------------------------- #

func _ok(condition: bool, message: String) -> void:
	print(("PASS  | " if condition else "FAIL  | ") + message)
	assert(condition, message)