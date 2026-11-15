extends Node

## PARALLAX — Phase 4 flight-simulation tests (simulation_tests.gd).
##
## Tests the documented, simplified kinematic model independently of the game:
## circular-orbit speeds/periods, propagation, manoeuvre effects, the telemetry
## history buffer, and that real data (Europa's radius) feeds the model.

func test_setup_uses_real_europa_radius() -> void:
	var sim: OrbitalSimulation = _fresh_sim()
	var europa: Dictionary = CelestialData.instance().get_body("EUROPA")
	_ok(absf(sim.body_radius_km - float(europa["radius_mean_km"])) < 0.001, "model uses the REAL Europa radius from the registry")
	_ok(absf(sim.orbit_radius_km - (sim.body_radius_km + SimulatedMissionData.REFERENCE_ORBIT_ALTITUDE_KM)) < 0.001, "orbit radius = Europa radius + fictional 100 km altitude")
	_cleanup(sim)


func test_circular_speed_and_period() -> void:
	var sim: OrbitalSimulation = _fresh_sim()
	var expected_v: float = sqrt(OrbitalSimulation.EUROPA_GM_KM3_S2 / sim.orbit_radius_km)
	var t: Dictionary = sim.telemetry()
	_ok(absf(float(t["speed_kms"]) - expected_v) < 0.0005, "circular speed = sqrt(GM / r)")
	_ok(absf(float(t["period_s"]) - TAU * sim.orbit_radius_km / expected_v) < 0.5, "period = 2π r / v")
	_ok(float(t["altitude_km"]) > 95.0 and float(t["altitude_km"]) < 105.0, "altitude ≈ 100 km")
	_cleanup(sim)


func test_propagation_stays_on_orbit() -> void:
	var sim: OrbitalSimulation = _fresh_sim()
	var before: float = sim._angle
	for i in range(50):
		sim.step(1.0)
	_ok(sim._angle != before, "stepping advances the orbit angle")
	_ok(absf(sim._position.length() - sim.orbit_radius_km) < 0.01, "position magnitude stays on the orbit radius")
	_ok(absf(sim._velocity.length() - sim.telemetry()["speed_kms"]) < 0.0005, "velocity magnitude equals the circular speed")
	_ok(sim.sim_elapsed_s >= 49.9, "simulation time accumulates")
	_cleanup(sim)


func test_acceleration_is_centripetal() -> void:
	var sim: OrbitalSimulation = _fresh_sim()
	var t: Dictionary = sim.telemetry()
	var v_ms: float = float(t["speed_kms"]) * 1000.0
	var r_m: float = sim.orbit_radius_km * 1000.0
	var expected: float = (v_ms * v_ms) / r_m
	_ok(absf(float(t["accel_ms2"]) - expected) < 0.02, "acceleration = v² / r")
	_cleanup(sim)


func test_manoeuvre_changes_orbit() -> void:
	var sim: OrbitalSimulation = _fresh_sim()
	var alt0: float = sim.telemetry()["altitude_km"]
	var period0: float = sim.telemetry()["period_s"]
	var report: Dictionary = sim.apply_manoeuvre(10.0)
	_ok(float(report["altitude_km"]) > alt0, "prograde burn raises the altitude")
	_ok(sim.telemetry()["period_s"] > period0, "raising the orbit lengthens the period")
	sim.apply_manoeuvre(-20.0)
	_ok(sim.telemetry()["altitude_km"] < float(report["altitude_km"]), "retrograde burn lowers the altitude")
	# Altitude floor is respected
	for i in range(50):
		sim.apply_manoeuvre(-100.0)
	_ok(sim.telemetry()["altitude_km"] >= 4.9, "altitude never falls below the model floor")
	_cleanup(sim)


func test_time_acceleration() -> void:
	var sim: OrbitalSimulation = _fresh_sim()
	sim.set_time_scale(100.0)
	_ok(sim.time_scale == 100.0, "time scale can be set")
	sim.set_time_scale(-5.0)
	_ok(sim.time_scale == 0.0, "time scale clamps at zero (no negative time)")
	_cleanup(sim)


func test_history_buffer_caps() -> void:
	var sim: OrbitalSimulation = _fresh_sim()
	for i in range(OrbitalSimulation.HISTORY_MAX + 60):
		sim.step(1.0)
		sim._sample_history()
	var ch: PackedFloat32Array = sim.channel("speed")
	_ok(ch.size() == OrbitalSimulation.HISTORY_MAX, "history buffer caps at %d samples" % OrbitalSimulation.HISTORY_MAX)
	_ok(ch.size() > 1, "history buffer records samples")
	_cleanup(sim)


func test_telemetry_has_all_fields() -> void:
	var sim: OrbitalSimulation = _fresh_sim()
	var t: Dictionary = sim.telemetry()
	for key in ["altitude_km", "speed_kms", "accel_ms2", "period_s", "distance_europa_km", "distance_jupiter_km", "inclination_deg", "pitch_deg", "yaw_deg", "roll_deg", "nav_accuracy", "mission_days", "position", "velocity"]:
		_ok(t.has(key), "telemetry exposes '%s'" % key)
	_ok(absf(float(t["distance_jupiter_km"]) - 670900.0) < 100.0, "distance from Jupiter uses Europa's REAL semi-major axis")
	_cleanup(sim)


func test_mission_clock_advances() -> void:
	var sim: OrbitalSimulation = _fresh_sim()
	var before: float = sim.mission_elapsed_days()
	for i in range(3600):
		sim.step(1.0)
	_ok(sim.mission_elapsed_days() > before, "mission-elapsed days advance with the simulation")
	_cleanup(sim)


# --------------------------------------------------------------------------- #

func _fresh_sim() -> OrbitalSimulation:
	var sim: OrbitalSimulation = OrbitalSimulation.new()
	add_child(sim)
	return sim


func _cleanup(sim: OrbitalSimulation) -> void:
	remove_child(sim)
	sim.free()


func _ok(condition: bool, message: String) -> void:
	print(("PASS  | " if condition else "FAIL  | ") + message)
	assert(condition, message)