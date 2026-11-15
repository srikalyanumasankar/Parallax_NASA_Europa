extends Node

## PARALLAX — Phase 2 orbital display tests (orbital_display_tests.gd).
##
## Tests the map's coordinate transforms, cursor-anchored zoom, framing and
## selection independently of the running game.

func test_round_trip_transform() -> void:
	var m: OrbitalMap = _fresh_map()
	var world: Vector2 = Vector2(3.5, -2.0)
	var back: Vector2 = m._s2w(m._w2s(world))
	_ok(back.distance_to(world) < 0.0005, "world → screen → world round-trips")
	_cleanup(m)


func test_zoom_keeps_cursor_anchor() -> void:
	var m: OrbitalMap = _fresh_map()
	m.zoom = 7.0
	m.pan = Vector2(1.0, 2.0)
	var cursor: Vector2 = Vector2(200.0, 150.0)
	var before: Vector2 = m._s2w(cursor)
	m._zoom_at(cursor, 2.5)
	var after: Vector2 = m._s2w(cursor)
	_ok(before.distance_to(after) < 0.001, "zoom keeps the world point under the cursor fixed")
	_ok(m.zoom > 7.0, "zoom-in increases the zoom factor")
	_cleanup(m)


func test_zoom_is_clamped() -> void:
	var m: OrbitalMap = _fresh_map()
	for i in range(80):
		m._zoom_at(Vector2(300, 200), 2.0)
	_ok(m.zoom <= OrbitalMap.MAX_ZOOM + 0.001, "zoom clamps at max")
	for i in range(80):
		m._zoom_at(Vector2(300, 200), 0.5)
	_ok(m.zoom >= OrbitalMap.MIN_ZOOM - 0.001, "zoom clamps at min")
	_cleanup(m)


func test_fit_view_frames_the_system() -> void:
	var m: OrbitalMap = _fresh_map()
	m.fit_view()
	var max_orbit: float = 0.0
	for b in OrbitalSchematic.all():
		max_orbit = maxf(max_orbit, float(b.get("orbit_radius", 0.0)))
	var needed_px: float = (max_orbit + 2.0) * m.zoom
	_ok(needed_px <= minf(m.size.x, m.size.y) * 0.5 + 0.5, "fit_view frames the whole system inside half the shorter edge")
	_cleanup(m)


func test_pick_returns_body_under_cursor() -> void:
	var m: OrbitalMap = _fresh_map()
	m.fit_view()
	var jupiter_screen: Vector2 = m._w2s(Vector2.ZERO)
	_ok(m._pick(jupiter_screen) == "JUPITER", "picking at Jupiter's screen position selects Jupiter")
	var europa_screen: Vector2 = m._w2s(m._world_pos("EUROPA"))
	_ok(m._pick(europa_screen) == "EUROPA", "picking at Europa's screen position selects Europa")
	_ok(m._pick(Vector2(-500, -500)) == "", "picking empty space selects nothing")
	_cleanup(m)


func test_selection_signal() -> void:
	var m: OrbitalMap = _fresh_map()
	var captured: Array = [""]
	m.selection_changed.connect(func(id: String) -> void: captured[0] = id)
	m.select("GANYMEDE")
	_ok(captured[0] == "GANYMEDE", "select() emits selection_changed with the new id")
	_ok(m.selected_id == "GANYMEDE", "select() updates selected_id")
	_cleanup(m)


func test_schematic_data_integrity() -> void:
	_ok(OrbitalSchematic.celestial_count() == 5, "schematic defines Jupiter + four Galilean moons")
	_ok(not OrbitalSchematic.body("EUROPA").is_empty(), "Europa is defined")
	_ok(OrbitalSchematic.body("AETHER")["orbit_of"] == "EUROPA", "the spacecraft orbits Europa")
	var ids: Array = []
	for b in OrbitalSchematic.all():
		ids.append(b["id"])
	_ok(ids.has("IO") and ids.has("GANYMEDE") and ids.has("CALLISTO"), "all Galilean moons present")


# --------------------------------------------------------------------------- #

func _fresh_map() -> OrbitalMap:
	var m: OrbitalMap = OrbitalMap.new()
	add_child(m)
	m.size = Vector2(640, 420)
	return m


func _cleanup(m: OrbitalMap) -> void:
	remove_child(m)
	m.free()


func _ok(condition: bool, message: String) -> void:
	print(("PASS  | " if condition else "FAIL  | ") + message)
	assert(condition, message)