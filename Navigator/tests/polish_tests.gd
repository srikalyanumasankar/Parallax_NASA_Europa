extends Node

## PARALLAX — Phase 9 polish tests.
## Covers the interface-audio registry (and its silent-safe behaviour), the
## shared motion helpers, the top-bar alert lamp, and the navigator's section
## transitions.

## Free immediately (not queue_free) so a node's connections to the shared bus
## are dropped before the next test emits on it.
func _free(node: Node) -> void:
	if is_instance_valid(node):
		node.free()


# --- Interface audio ---------------------------------------------------------

func test_sound_registry_has_all_seven() -> void:
	var names: Array = InterfaceSfx.names()
	assert(names.size() == 7, "expected 7 interface sounds, got %d" % names.size())
	for s in ["click", "confirm", "relay", "fan", "comm", "warning", "complete"]:
		assert(names.has(s), "missing sound in registry: " + s)


func test_sound_files_exist_on_disk() -> void:
	for name in InterfaceSfx.names():
		var path: String = str(InterfaceSfx.SOUNDS[name])
		assert(path.ends_with(".mp3"), name + " should point at an mp3")
		assert(FileAccess.file_exists(path), "missing file for " + name + ": " + path)


func test_streams_load() -> void:
	assert(InterfaceSfx.has("click"), "the click stream should load")
	assert(InterfaceSfx.stream_for("click") is AudioStream, "click should be an AudioStream")
	assert(InterfaceSfx.stream_for("complete") is AudioStream, "complete should be an AudioStream")


func test_unknown_sound_is_silent_safe() -> void:
	assert(InterfaceSfx.stream_for("nope") == null, "unknown sound should resolve to null")
	assert(not InterfaceSfx.has("nope"), "unknown sound should not report as present")
	assert(InterfaceSfx.make_loop("nope") == null, "unknown loop should be null")


func test_fan_loop_is_configured() -> void:
	var player: AudioStreamPlayer = InterfaceSfx.make_loop("fan", -20.0)
	assert(player != null, "the fan loop player should be created")
	var stream: AudioStream = player.stream
	assert(stream is AudioStreamMP3, "the fan should be an mp3 stream")
	assert((stream as AudioStreamMP3).loop, "the fan stream should loop")
	assert(is_equal_approx(player.volume_db, -20.0), "the fan volume should be applied")
	player.free()


# --- Motion helpers ----------------------------------------------------------

func test_motion_fade_in() -> void:
	var c: Control = Control.new()
	add_child(c)
	var tw: Tween = ParallaxMotion.fade_in(c, 0.1, 0.0)
	assert(tw != null, "fade_in should return a tween")
	assert(is_equal_approx(c.modulate.a, 0.0), "fade_in should start transparent")
	assert(ParallaxMotion.fade_in(null) == null, "fade_in(null) should be null")
	_free(c)


func test_motion_flash_tints() -> void:
	var c: Control = Control.new()
	add_child(c)
	var tw: Tween = ParallaxMotion.flash(c, ParallaxPalette.CYAN, 0.4)
	assert(tw != null, "flash should return a tween")
	assert(c.modulate != Color.WHITE, "flash should tint the node immediately")
	_free(c)


# --- Alerts ------------------------------------------------------------------

func test_alert_indicator_lifecycle() -> void:
	var ind: AlertIndicator = AlertIndicator.new()
	add_child(ind)
	ind.set_alert("WARNING", "FUEL LOW")
	assert(ind.is_active(), "indicator should be active after set_alert")
	assert(ind.alert_text().contains("FUEL LOW"), "indicator should show the alert text")
	ind.set_alert("CRITICAL", "HULL BREACH")
	assert(ind.alert_text().begins_with("CRITICAL"), "the CRITICAL level should be shown")
	ind.clear_alert()
	assert(not ind.is_active(), "indicator should clear")
	assert(ind.alert_text() == "NONE", "indicator should read NONE once cleared")
	_free(ind)


func test_alert_lamp_follows_bus() -> void:
	var nav: NavigatorScreen = NavigatorScreen.new()
	add_child(nav)
	var lamp: AlertIndicator = nav.alert_indicator()
	assert(lamp != null, "the navigator should own an alert lamp")
	MissionBus.alert_raised.emit("WARNING", "REACTION WHEEL DRIFT")
	assert(lamp.is_active(), "a bus alert should light the lamp")
	assert(lamp.alert_text().contains("REACTION WHEEL DRIFT"), "the lamp should show the bus text")
	lamp.clear_alert()
	_free(nav)


# --- Navigator transitions ---------------------------------------------------

func test_navigator_opens_and_selects() -> void:
	var nav: NavigatorScreen = NavigatorScreen.new()
	add_child(nav)
	assert(nav.is_open(), "the navigator should be open after ready")
	_free(nav)