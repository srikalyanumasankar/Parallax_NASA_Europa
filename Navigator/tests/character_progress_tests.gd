extends Node

## PARALLAX — cross-character progress façade tests (character_progress_tests.gd).
## Verifies other character modules can publish to the shared state and read
## mission-wide progress, and that the shared database façade works — all
## through the façade, never by reaching into another module.

func test_character_publishes_event_and_uploads() -> void:
	var s: SharedMissionState = _fresh()
	CharacterProgress.publish(s, "VARUN", "RADIO_OBSERVATIONS_RECORDED")
	_ok(s.has_event("RADIO_OBSERVATIONS_RECORDED"), "character event reaches shared state")
	_ok(s.event_source("RADIO_OBSERVATIONS_RECORDED") == "VARUN", "event records its source character")
	CharacterProgress.upload(s, "KRISH", "KANDAM_SURVEY_01", "KANDAM survey data", "KANDAM_DATA_UPLOADED")
	_ok(MissionDatabase.has(s, "KANDAM_SURVEY_01"), "character upload reaches the shared database")
	_ok(s.has_event("KANDAM_DATA_UPLOADED"), "upload also publishes its completion event")
	_done(s)


func test_events_from_filters_by_character() -> void:
	var s: SharedMissionState = _fresh()
	CharacterProgress.publish(s, "MANIC", "MANIC_BASE_OPERATIONAL")
	CharacterProgress.publish(s, "VARUN", "EARTH_COMMUNICATION_VERIFIED")
	CharacterProgress.publish(s, "VARUN", "OBSERVATION_DATA_UPLOADED")
	var varun_events: Array = CharacterProgress.events_from(s, "VARUN")
	_ok(varun_events.size() == 2, "events_from returns only that character's events")
	_ok(varun_events.has("EARTH_COMMUNICATION_VERIFIED") and varun_events.has("OBSERVATION_DATA_UPLOADED"), "and they are the right ones")
	_done(s)


func test_character_completion_flows_through_shared_state() -> void:
	var s: SharedMissionState = _fresh()
	# A character module completing one of its missions must land in shared state.
	var ok: bool = CharacterProgress.complete_mission_for(s, "VARUN", "NAV_001")
	_ok(ok and s.is_completed("NAV_001"), "character completion is recorded in the shared source of truth")
	_done(s)


func test_progress_summary_counts() -> void:
	var s: SharedMissionState = _fresh()
	CharacterProgress.complete_mission_for(s, "SRI_KALYAN", "NAV_001")
	var summary: Dictionary = CharacterProgress.progress_summary(s)
	_ok(int(summary["missions_completed"]) == 1, "summary counts completed missions")
	_ok(int(summary["missions_total"]) == MissionDefinitions.MISSIONS.size(), "summary knows the mission total")
	_ok((summary["available"] as Array).has("NAV_002"), "summary lists NAV_002 as available")
	_done(s)


func test_database_facade() -> void:
	var s: SharedMissionState = _fresh()
	MissionDatabase.add_file(s, "REPORT_001", "MISSION_CONTROL", "Approach summary", "FILE")
	_ok(MissionDatabase.count(s) == 1, "database facade counts entries")
	_ok(MissionDatabase.has(s, "REPORT_001"), "database facade reports presence")
	MissionDatabase.add_file(s, "REPORT_001", "MISSION_CONTROL", "duplicate")
	_ok(MissionDatabase.count(s) == 1, "duplicate entry id is not stored twice")
	_done(s)


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


func _ok(condition: bool, message: String) -> void:
	print(("PASS  | " if condition else "FAIL  | ") + message)
	assert(condition, message)