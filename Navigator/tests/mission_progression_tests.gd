extends Node

## PARALLAX — the spec's mission-progression suite (mission_progression_tests.gd).
## Implements TEST 1 … TEST 17 from the master specification. Each test is
## self-contained; the persistence tests use a temporary save file that is
## removed afterwards.

const TEST_PATH: String = "user://__parallax_prog_test.json"


func test_01_new_game_only_nav001_available() -> void:
	var s: SharedMissionState = _fresh()
	_ok(s.mission_state("NAV_001") == MissionDefinitions.STATUS_AVAILABLE, "TEST 1: NAV_001 available")
	_ok(s.mission_state("NAV_002") == MissionDefinitions.STATUS_LOCKED, "TEST 1: NAV_002 locked")
	_done(s)


func test_02_nav001_completed_unlocks_nav002() -> void:
	var s: SharedMissionState = _fresh()
	s.complete_mission("NAV_001")
	_ok(s.mission_state("NAV_002") == MissionDefinitions.STATUS_AVAILABLE, "TEST 2: NAV_002 becomes available")
	_done(s)


func test_03_nav002_unlocks_nav003_nav004_locked() -> void:
	var s: SharedMissionState = _fresh()
	_chain(s, ["NAV_001", "NAV_002"])
	_ok(s.mission_state("NAV_003") == MissionDefinitions.STATUS_AVAILABLE, "TEST 3: NAV_003 available")
	_ok(s.mission_state("NAV_004") == MissionDefinitions.STATUS_LOCKED, "TEST 3: NAV_004 still locked")
	_done(s)


func test_04_landing_prep_missing_keeps_nav004_locked() -> void:
	var s: SharedMissionState = _fresh()
	_chain(s, ["NAV_001", "NAV_002", "NAV_003"])
	s.publish_event("SURFACE_COMMUNICATION_READY", "DEV_TEST")
	_ok(s.mission_state("NAV_004") == MissionDefinitions.STATUS_LOCKED, "TEST 4: NAV_004 locked without landing preparation")
	_done(s)


func test_05_comms_missing_keeps_nav004_locked() -> void:
	var s: SharedMissionState = _fresh()
	_chain(s, ["NAV_001", "NAV_002", "NAV_003"])
	s.publish_event("LANDING_PREPARATION_CONFIRMED", "DEV_TEST")
	_ok(s.mission_state("NAV_004") == MissionDefinitions.STATUS_LOCKED, "TEST 5: NAV_004 locked without comms readiness")
	_done(s)


func test_06_all_nav004_requirements_unlock() -> void:
	var s: SharedMissionState = _fresh()
	_chain(s, ["NAV_001", "NAV_002", "NAV_003"])
	s.publish_event("LANDING_PREPARATION_CONFIRMED", "DEV_TEST")
	s.publish_event("SURFACE_COMMUNICATION_READY", "DEV_TEST")
	_ok(s.mission_state("NAV_004") == MissionDefinitions.STATUS_AVAILABLE, "TEST 6: NAV_004 becomes available")
	_done(s)


func test_07_surface_contact_alone_locks_nav005() -> void:
	var s: SharedMissionState = _fresh()
	_chain(s, ["NAV_001", "NAV_002", "NAV_003", "NAV_004"])
	_ok(s.mission_state("NAV_005") == MissionDefinitions.STATUS_LOCKED, "TEST 7: NAV_005 locked while base not operational")
	_done(s)


func test_08_manic_without_varun_locks_nav005() -> void:
	var s: SharedMissionState = _fresh()
	_chain(s, ["NAV_001", "NAV_002", "NAV_003", "NAV_004"])
	s.publish_event("MANIC_BASE_OPERATIONAL", "DEV_TEST")
	_ok(s.mission_state("NAV_005") == MissionDefinitions.STATUS_LOCKED, "TEST 8: NAV_005 locked without Varun surface comms")
	_done(s)


func test_09_all_nav005_requirements_unlock() -> void:
	var s: SharedMissionState = _fresh()
	_chain(s, ["NAV_001", "NAV_002", "NAV_003", "NAV_004"])
	s.publish_event("MANIC_BASE_OPERATIONAL", "DEV_TEST")
	s.publish_event("VARUN_SURFACE_COMMUNICATION_ESTABLISHED", "DEV_TEST")
	_ok(s.mission_state("NAV_005") == MissionDefinitions.STATUS_AVAILABLE, "TEST 9: NAV_005 becomes available")
	_done(s)


func test_10_nav006_requires_all_uploads() -> void:
	var s: SharedMissionState = _fresh()
	_chain(s, ["NAV_001", "NAV_002", "NAV_003", "NAV_004", "NAV_005"])
	var events: Array = ["KANDAM_DATA_UPLOADED", "KADAL_DATA_UPLOADED", "ENVIRONMENTAL_SYSTEMS_VERIFIED", "SAMPLE_STORED", "SCIENTIFIC_RESULTS_UPLOADED", "OBSERVATION_DATA_UPLOADED"]
	for i in range(events.size()):
		s.publish_event(str(events[i]), "DEV_TEST")
		if i < events.size() - 1:
			_ok(s.mission_state("NAV_006") == MissionDefinitions.STATUS_LOCKED, "TEST 10: NAV_006 locked at %d/%d uploads" % [i + 1, events.size()])
	_ok(s.mission_state("NAV_006") == MissionDefinitions.STATUS_AVAILABLE, "TEST 10: NAV_006 available after all uploads")
	_done(s)


func test_11_incomplete_investigation_locks_nav007() -> void:
	var s: SharedMissionState = _fresh()
	_chain(s, ["NAV_001", "NAV_002", "NAV_003", "NAV_004", "NAV_005", "NAV_006"])
	_ok(s.mission_state("NAV_007") == MissionDefinitions.STATUS_LOCKED, "TEST 11: NAV_007 locked until investigation complete")
	_done(s)


func test_12_return_ready_unlocks_nav007() -> void:
	var s: SharedMissionState = _fresh()
	_chain(s, ["NAV_001", "NAV_002", "NAV_003", "NAV_004", "NAV_005", "NAV_006"])
	for ev in ["SCIENTIFIC_INVESTIGATION_COMPLETE", "SAMPLES_PACKAGED", "SURFACE_RETURN_READY", "COMMUNICATIONS_AVAILABLE"]:
		s.publish_event(str(ev), "DEV_TEST")
	_ok(s.mission_state("NAV_007") == MissionDefinitions.STATUS_AVAILABLE, "TEST 12: NAV_007 becomes available")
	_done(s)


func test_13_lander_return_unlocks_nav008() -> void:
	var s: SharedMissionState = _fresh()
	_chain(s, ["NAV_001", "NAV_002", "NAV_003", "NAV_004", "NAV_005", "NAV_006", "NAV_007"])
	_ok(s.mission_state("NAV_008") == MissionDefinitions.STATUS_AVAILABLE, "TEST 13: NAV_008 becomes available")
	_done(s)


func test_14_docking_unlocks_nav009() -> void:
	var s: SharedMissionState = _fresh()
	_chain(s, ["NAV_001", "NAV_002", "NAV_003", "NAV_004", "NAV_005", "NAV_006", "NAV_007", "NAV_008"])
	_ok(s.mission_state("NAV_009") == MissionDefinitions.STATUS_AVAILABLE, "TEST 14: NAV_009 becomes available")
	_done(s)


func test_15_progress_survives_restart() -> void:
	_delete_test_save()
	var s: SharedMissionState = _persistent()
	_chain(s, ["NAV_001", "NAV_002", "NAV_003"])
	s.publish_event("LANDING_PREPARATION_CONFIRMED", "DEV_TEST")
	s.free()

	var reloaded: SharedMissionState = _persistent()
	_ok(reloaded.is_completed("NAV_001") and reloaded.is_completed("NAV_002") and reloaded.is_completed("NAV_003"), "TEST 15: completions preserved after restart")
	_ok(reloaded.has_event("LANDING_PREPARATION_CONFIRMED"), "TEST 15: shared events preserved after restart")
	reloaded.free()
	_delete_test_save()


func test_16_duplicate_events_are_safe() -> void:
	var s: SharedMissionState = _fresh()
	_chain(s, ["NAV_001", "NAV_002", "NAV_003"])
	s.publish_event("LANDING_PREPARATION_CONFIRMED", "DEV_TEST")
	var n: int = s.shared_events.size()
	s.publish_event("LANDING_PREPARATION_CONFIRMED", "DEV_TEST")
	_ok(s.shared_events.size() == n, "TEST 16: duplicate event not recorded twice")
	var c: int = s.completed_count()
	s.complete_mission("NAV_002")
	_ok(s.completed_count() == c, "TEST 16: duplicate completion ignored")
	_done(s)


func test_17_navigator_state_preserved_after_reopen() -> void:
	_delete_test_save()
	var s: SharedMissionState = _persistent()
	s.start_mission("NAV_001")
	var sim: OrbitalSimulation = OrbitalSimulation.new()
	add_child(sim)
	var op: Dictionary = ManeuverDefinitions.get_operation("OP_VERIFY_NAV")
	ManeuverManager.execute(sim, op, 0.0, s, "NAV_001")
	remove_child(sim)
	sim.free()
	s.free()

	# Reopen the navigator: a fresh state reads the same save.
	var reopened: SharedMissionState = _persistent()
	_ok(reopened.active_mission == "NAV_001", "TEST 17: active mission preserved after reopening")
	_ok(reopened.is_objective_done("NAV_001", str(op["objective"])), "TEST 17: completed objective preserved after reopening")
	reopened.free()
	_delete_test_save()


func test_18_unlock_notification_is_published() -> void:
	var s: SharedMissionState = _fresh()
	if MissionBus == null:
		_ok(true, "TEST 18: MissionBus not present in this context — skipped")
		_done(s)
		return
	var received: Array = []
	var cb: Callable = func(id: String) -> void: received.append(id)
	MissionBus.mission_unlocked.connect(cb)
	s.complete_mission("NAV_001")
	MissionBus.mission_unlocked.disconnect(cb)
	_ok(received.has("NAV_002"), "TEST 18: unlocking NAV_002 publishes an unlock notification")
	_done(s)


# --------------------------------------------------------------------------- #

func _fresh() -> SharedMissionState:
	var s: SharedMissionState = SharedMissionState.new()
	s.auto_save = false
	s.save_path = "user://__parallax_test_unused.json"
	add_child(s)
	return s


func _persistent() -> SharedMissionState:
	var s: SharedMissionState = SharedMissionState.new()
	s.auto_save = true
	s.save_path = TEST_PATH
	add_child(s)
	return s


func _delete_test_save() -> void:
	var abs_path: String = ProjectSettings.globalize_path(TEST_PATH)
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(abs_path)


func _chain(s: SharedMissionState, ids: Array) -> void:
	for mid in ids:
		s.complete_mission(str(mid))


func _done(s: SharedMissionState) -> void:
	remove_child(s)
	s.free()


func _ok(condition: bool, message: String) -> void:
	print(("PASS  | " if condition else "FAIL  | ") + message)
	assert(condition, message)