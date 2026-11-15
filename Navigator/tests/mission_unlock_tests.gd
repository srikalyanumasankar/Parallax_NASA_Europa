extends Node

## PARALLAX — mission progression tests (mission_unlock_tests.gd).
##
## Each test_* method is self-contained and runs on a fresh SharedMissionState
## (no autoload needed, no real save touched). Covers the spec's TEST 1–17
## progression scenarios for the shared mission dependency system.


# --------------------------------------------------------------------------- #

func test_1_new_game_locks_future_missions() -> void:
	var s: SharedMissionState = _fresh()
	_ok(s.mission_state("NAV_001") == MissionDefinitions.STATUS_AVAILABLE, "TEST 1: NAV_001 available at start")
	for mid in ["NAV_002", "NAV_003", "NAV_004", "NAV_005", "NAV_006", "NAV_007", "NAV_008", "NAV_009"]:
		_ok(s.mission_state(mid) == MissionDefinitions.STATUS_LOCKED, "TEST 1: %s locked at start" % mid)
	_done(s)


func test_2_nav001_unlocks_nav002() -> void:
	var s: SharedMissionState = _fresh()
	s.complete_mission("NAV_001")
	_ok(s.is_completed("NAV_001"), "TEST 2: NAV_001 recorded complete")
	_ok(s.mission_state("NAV_002") == MissionDefinitions.STATUS_AVAILABLE, "TEST 2: NAV_002 available after NAV_001")
	_done(s)


func test_3_nav002_unlocks_nav003_nav004_locked() -> void:
	var s: SharedMissionState = _fresh()
	s.complete_mission("NAV_001")
	s.complete_mission("NAV_002")
	_ok(s.mission_state("NAV_003") == MissionDefinitions.STATUS_AVAILABLE, "TEST 3: NAV_003 available after NAV_002")
	_ok(s.mission_state("NAV_004") == MissionDefinitions.STATUS_LOCKED, "TEST 3: NAV_004 still locked (events missing)")
	_done(s)


func test_4_landing_prep_missing_locks_nav004() -> void:
	var s: SharedMissionState = _fresh()
	_complete_chain(s, ["NAV_001", "NAV_002", "NAV_003"])
	s.publish_event("SURFACE_COMMUNICATION_READY", "DEV_TEST")
	_ok(s.mission_state("NAV_004") == MissionDefinitions.STATUS_LOCKED, "TEST 4: NAV_004 locked without landing-preparation")
	_done(s)


func test_5_comms_readiness_missing_locks_nav004() -> void:
	var s: SharedMissionState = _fresh()
	_complete_chain(s, ["NAV_001", "NAV_002", "NAV_003"])
	s.publish_event("LANDING_PREPARATION_CONFIRMED", "DEV_TEST")
	_ok(s.mission_state("NAV_004") == MissionDefinitions.STATUS_LOCKED, "TEST 5: NAV_004 locked without comms readiness")
	_done(s)


func test_6_all_nav004_requirements_unlock() -> void:
	var s: SharedMissionState = _fresh()
	_complete_chain(s, ["NAV_001", "NAV_002", "NAV_003"])
	s.publish_event("LANDING_PREPARATION_CONFIRMED", "DEV_TEST")
	s.publish_event("SURFACE_COMMUNICATION_READY", "DEV_TEST")
	_ok(s.mission_state("NAV_004") == MissionDefinitions.STATUS_AVAILABLE, "TEST 6: NAV_004 available with all requirements")
	_done(s)


func test_7_surface_contact_alone_does_not_unlock_nav005() -> void:
	var s: SharedMissionState = _fresh()
	_complete_chain(s, ["NAV_001", "NAV_002", "NAV_003", "NAV_004"])
	_ok(s.has_event("SURFACE_CONTACT_CONFIRMED"), "TEST 7: surface contact confirmed by NAV_004")
	_ok(s.mission_state("NAV_005") == MissionDefinitions.STATUS_LOCKED, "TEST 7: NAV_005 locked while surface base not operational")
	_done(s)


func test_8_manic_without_varun_locks_nav005() -> void:
	var s: SharedMissionState = _fresh()
	_complete_chain(s, ["NAV_001", "NAV_002", "NAV_003", "NAV_004"])
	s.publish_event("MANIC_BASE_OPERATIONAL", "DEV_TEST")
	_ok(s.mission_state("NAV_005") == MissionDefinitions.STATUS_LOCKED, "TEST 8: NAV_005 locked without Varun surface comms")
	_done(s)


func test_9_all_nav005_requirements_unlock() -> void:
	var s: SharedMissionState = _fresh()
	_complete_chain(s, ["NAV_001", "NAV_002", "NAV_003", "NAV_004"])
	s.publish_event("MANIC_BASE_OPERATIONAL", "DEV_TEST")
	s.publish_event("VARUN_SURFACE_COMMUNICATION_ESTABLISHED", "DEV_TEST")
	_ok(s.mission_state("NAV_005") == MissionDefinitions.STATUS_AVAILABLE, "TEST 9: NAV_005 available with all requirements")
	_done(s)


func test_10_nav006_needs_all_scientific_uploads() -> void:
	var s: SharedMissionState = _fresh()
	_complete_chain(s, ["NAV_001", "NAV_002", "NAV_003", "NAV_004", "NAV_005"])
	var events: Array = ["KANDAM_DATA_UPLOADED", "KADAL_DATA_UPLOADED", "ENVIRONMENTAL_SYSTEMS_VERIFIED", "SAMPLE_STORED", "SCIENTIFIC_RESULTS_UPLOADED", "OBSERVATION_DATA_UPLOADED"]
	for i in range(events.size()):
		s.publish_event(str(events[i]), "DEV_TEST")
		if i < events.size() - 1:
			_ok(s.mission_state("NAV_006") == MissionDefinitions.STATUS_LOCKED, "TEST 10: NAV_006 still locked (%d/%d uploads)" % [i + 1, events.size()])
	_ok(s.mission_state("NAV_006") == MissionDefinitions.STATUS_AVAILABLE, "TEST 10: NAV_006 available after all uploads")
	_done(s)


func test_11_incomplete_investigation_locks_nav007() -> void:
	var s: SharedMissionState = _fresh()
	_complete_chain(s, ["NAV_001", "NAV_002", "NAV_003", "NAV_004", "NAV_005", "NAV_006"])
	_ok(s.mission_state("NAV_007") == MissionDefinitions.STATUS_LOCKED, "TEST 11: NAV_007 locked until investigation + return-ready")
	_done(s)


func test_12_investigation_and_return_ready_unlock_nav007() -> void:
	var s: SharedMissionState = _fresh()
	_complete_chain(s, ["NAV_001", "NAV_002", "NAV_003", "NAV_004", "NAV_005", "NAV_006"])
	for ev in ["SCIENTIFIC_INVESTIGATION_COMPLETE", "SAMPLES_PACKAGED", "SURFACE_RETURN_READY", "COMMUNICATIONS_AVAILABLE"]:
		s.publish_event(str(ev), "DEV_TEST")
	_ok(s.mission_state("NAV_007") == MissionDefinitions.STATUS_AVAILABLE, "TEST 12: NAV_007 available")
	_done(s)


func test_13_lander_return_unlocks_nav008() -> void:
	var s: SharedMissionState = _fresh()
	_complete_chain(s, ["NAV_001", "NAV_002", "NAV_003", "NAV_004", "NAV_005", "NAV_006", "NAV_007"])
	_ok(s.mission_state("NAV_008") == MissionDefinitions.STATUS_AVAILABLE, "TEST 13: NAV_008 available after lander returning to orbit")
	_done(s)


func test_14_docking_unlocks_nav009() -> void:
	var s: SharedMissionState = _fresh()
	_complete_chain(s, ["NAV_001", "NAV_002", "NAV_003", "NAV_004", "NAV_005", "NAV_006", "NAV_007", "NAV_008"])
	_ok(s.mission_state("NAV_009") == MissionDefinitions.STATUS_AVAILABLE, "TEST 14: NAV_009 available after docking")
	_done(s)


func test_15_progress_survives_save_restore() -> void:
	var s: SharedMissionState = _fresh()
	_complete_chain(s, ["NAV_001", "NAV_002", "NAV_003"])
	s.publish_event("LANDING_PREPARATION_CONFIRMED", "DEV_TEST")
	var snapshot: Dictionary = s.to_dict()
	var restored: SharedMissionState = _fresh()
	restored.from_dict(snapshot)
	_ok(restored.is_completed("NAV_001") and restored.is_completed("NAV_002") and restored.is_completed("NAV_003"), "TEST 15: completions preserved across restore")
	_ok(restored.has_event("LANDING_PREPARATION_CONFIRMED"), "TEST 15: cross-module events preserved across restore")
	_done(s)
	_done(restored)


func test_16_duplicate_events_are_idempotent() -> void:
	var s: SharedMissionState = _fresh()
	_complete_chain(s, ["NAV_001", "NAV_002", "NAV_003"])
	s.publish_event("LANDING_PREPARATION_CONFIRMED", "DEV_TEST")
	var event_count: int = s.shared_events.size()
	s.publish_event("LANDING_PREPARATION_CONFIRMED", "DEV_TEST")
	_ok(s.shared_events.size() == event_count, "TEST 16: duplicate event not recorded twice")
	var completions: int = s.completed_count()
	s.complete_mission("NAV_002")
	_ok(s.completed_count() == completions, "TEST 16: duplicate completion ignored")
	_done(s)


# --------------------------------------------------------------------------- #
#  Helpers
# --------------------------------------------------------------------------- #

func _fresh() -> SharedMissionState:
	var s: SharedMissionState = SharedMissionState.new()
	s.auto_save = false
	s.save_path = "user://__parallax_test_unused.json"
	add_child(s)
	return s


func _done(s: SharedMissionState) -> void:
	remove_child(s)
	s.free()


func _complete_chain(s: SharedMissionState, ids: Array) -> void:
	for mid in ids:
		s.complete_mission(str(mid))


func _ok(condition: bool, message: String) -> void:
	print(("PASS  | " if condition else "FAIL  | ") + message)
	assert(condition, message)