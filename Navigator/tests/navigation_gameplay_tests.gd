extends Node

## PARALLAX — Phase 5 navigation-gameplay tests (navigation_gameplay_tests.gd).
##
## Verifies manoeuvre prediction, execution (which must change the simulation),
## verification, objective recording, and that operations are bound to real
## mission objectives rather than hard-coded into buttons.

func test_prediction_matches_target_altitude() -> void:
	var sim: OrbitalSimulation = _fresh_sim()
	var op: Dictionary = ManeuverDefinitions.get_operation("OP_ORBIT_INSERT")
	var pred: Dictionary = ManeuverManager.predicted(sim, op, 130.0)
	_ok(absf(float(pred["altitude_km"]) - 130.0) < 0.001, "predicted altitude equals the configured target")
	_ok(absf(float(pred["delta_v_ms"])) > 1.0, "reaching a new altitude requires a non-zero Δv")
	_cleanup_sim(sim)


func test_execution_changes_simulation() -> void:
	var sim: OrbitalSimulation = _fresh_sim()
	var state: SharedMissionState = _fresh_state()
	var op: Dictionary = ManeuverDefinitions.get_operation("OP_ORBIT_INSERT")
	var before: float = sim.telemetry()["altitude_km"]
	var report: Dictionary = ManeuverManager.execute(sim, op, 130.0, state, "NAV_002")
	var after: float = sim.telemetry()["altitude_km"]
	_ok(after != before, "executing the operation changes the simulation state")
	_ok(absf(after - 130.0) < 15.0, "the achieved altitude is close to the requested target (got %.1f km)" % after)
	_ok(float(report["period_after_s"]) != float(report["period_before_s"]), "the orbital period changes")
	_cleanup_sim(sim)
	_cleanup_state(state)


func test_execution_records_the_objective() -> void:
	var sim: OrbitalSimulation = _fresh_sim()
	var state: SharedMissionState = _fresh_state()
	var op: Dictionary = ManeuverDefinitions.get_operation("OP_ORBIT_INSERT")
	_ok(not state.is_objective_done("NAV_002", str(op["objective"])), "objective is not done before execution")
	ManeuverManager.execute(sim, op, 110.0, state, "NAV_002")
	_ok(state.is_objective_done("NAV_002", str(op["objective"])), "objective is recorded after execution")
	_cleanup_sim(sim)
	_cleanup_state(state)


func test_verification_reports_success() -> void:
	var sim: OrbitalSimulation = _fresh_sim()
	var state: SharedMissionState = _fresh_state()
	var op: Dictionary = ManeuverDefinitions.get_operation("OP_ORBIT_INSERT")
	var report: Dictionary = ManeuverManager.execute(sim, op, 120.0, state, "NAV_002")
	var res: Dictionary = ManeuverManager.verify(op, report)
	_ok(bool(res["success"]), "verification succeeds within tolerance: %s" % str(res["note"]))
	_cleanup_sim(sim)
	_cleanup_state(state)


func test_verify_kind_makes_no_orbit_change() -> void:
	var sim: OrbitalSimulation = _fresh_sim()
	var state: SharedMissionState = _fresh_state()
	var op: Dictionary = ManeuverDefinitions.get_operation("OP_VERIFY_NAV")
	var before: float = sim.telemetry()["altitude_km"]
	ManeuverManager.execute(sim, op, 0.0, state, "NAV_001")
	_ok(absf(sim.telemetry()["altitude_km"] - before) < 0.0001, "a verification op does not change the orbit")
	_ok(state.is_objective_done("NAV_001", str(op["objective"])), "but it records its mission objective in shared state")
	_ok(not bool(op.get("confirm", false)), "a verification op needs no confirmation")
	_cleanup_sim(sim)
	_cleanup_state(state)


func test_delta_v_operation() -> void:
	var sim: OrbitalSimulation = _fresh_sim()
	var state: SharedMissionState = _fresh_state()
	var op: Dictionary = ManeuverDefinitions.get_operation("OP_DOCK_APPROACH")
	_ok(bool(op.get("confirm", false)), "a burn requires confirmation")
	var pred: Dictionary = ManeuverManager.predicted(sim, op, 5.0)
	_ok(float(pred["altitude_km"]) != sim.telemetry()["altitude_km"], "a Δv operation predicts a changed altitude")
	ManeuverManager.execute(sim, op, 5.0, state, "NAV_008")
	_ok(state.is_objective_done("NAV_008", str(op["objective"])), "Δv op records its objective")
	_cleanup_sim(sim)
	_cleanup_state(state)


func test_objectives_gate_completion() -> void:
	var state: SharedMissionState = _fresh_state()
	_ok(not state.are_objectives_done("NAV_002"), "NAV_002 objectives are incomplete at the start")
	var count: int = state.required_objective_count("NAV_002")
	_ok(count == ManeuverDefinitions.objective_keys("NAV_002").size(), "required objective count matches the operation-backed objectives")
	_ok(count >= 1, "NAV_002 has at least one operation-backed objective")
	_ok(state.required_objective_count("NAV_001") == 1, "NAV_001's single verify operation gates completion")
	for obj in MissionDefinitions.get_mission("NAV_002")["objectives"] as Array:
		state.complete_objective("NAV_002", str(obj))
	_ok(state.are_objectives_done("NAV_002"), "all objectives recorded → mission completion conditions met")
	_ok(state.objectives_done_count("NAV_002") == count, "objective progress counts each completed task once")
	_ok(not state.complete_objective("NAV_002", str(MissionDefinitions.get_mission("NAV_002")["objectives"][0])), "recording an objective twice is ignored")
	_cleanup_state(state)


func test_operations_bind_to_real_objectives() -> void:
	for mission_id in ManeuverDefinitions.OPERATIONS.keys():
		var required: Array = MissionDefinitions.get_mission(str(mission_id)).get("objectives", [])
		for op in ManeuverDefinitions.for_mission(str(mission_id)) as Array:
			_ok(required.has(str(op["objective"])), "%s is bound to a real objective of %s" % [op["id"], mission_id])


# --------------------------------------------------------------------------- #

func _fresh_sim() -> OrbitalSimulation:
	var sim: OrbitalSimulation = OrbitalSimulation.new()
	add_child(sim)
	return sim


func _cleanup_sim(sim: OrbitalSimulation) -> void:
	remove_child(sim)
	sim.free()


func _fresh_state() -> SharedMissionState:
	var s: SharedMissionState = SharedMissionState.new()
	s.auto_save = false
	s.save_path = "user://__parallax_test_unused.json"
	add_child(s)
	return s


func _cleanup_state(s: SharedMissionState) -> void:
	remove_child(s)
	s.free()


func _ok(condition: bool, message: String) -> void:
	print(("PASS  | " if condition else "FAIL  | ") + message)
	assert(condition, message)