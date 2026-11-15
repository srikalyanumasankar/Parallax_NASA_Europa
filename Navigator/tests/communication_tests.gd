extends Node

## PARALLAX — Phase 7 communication tests (communication_tests.gd).
## Verifies message composition, idempotent logging, link-status derivation,
## mission history and persistence of the communication log.

func test_compose_event_message() -> void:
	var msg: Dictionary = CommunicationManager.compose("KANDAM_DATA_UPLOADED", "KRISH")
	_ok(str(msg["id"]) == "EVT_KANDAM_DATA_UPLOADED", "composed message has a stable event id")
	_ok(str(msg["source"]) == "KRISH", "message records its source")
	_ok(str(msg["subject"]) != "" and str(msg["body"]) != "", "message has a subject and body")
	_ok(str(msg["body"]).contains("KANDAM survey data uploaded"), "body names the event")


func test_mission_control_message_style() -> void:
	var msg: Dictionary = CommunicationManager.compose("LANDING_PREPARATION_CONFIRMED", "MISSION_CONTROL")
	_ok(str(msg["subject"]) == "MISSION CONTROL DIRECTIVE", "mission-control messages are labelled as directives")
	var d: Dictionary = CommunicationManager.compose_directive("NAV_002")
	_ok(str(d["id"]) == "DIRECTIVE_NAV_002", "directive id is stable")
	_ok(str(d["body"]).contains("Jupiter Approach"), "directive names the mission")


func test_record_event_is_idempotent() -> void:
	var s: SharedMissionState = _fresh()
	_ok(CommunicationManager.record_event(s, "RADIO_OBSERVATIONS_RECORDED", "VARUN"), "first record logs a message")
	_ok(not CommunicationManager.record_event(s, "RADIO_OBSERVATIONS_RECORDED", "VARUN"), "the same event does not log twice")
	_ok(s.communications.size() == 1, "only one message stored")
	_done(s)


func test_surface_link_status_progression() -> void:
	var s: SharedMissionState = _fresh()
	_ok(str(CommunicationManager.surface_link_status(s)["state"]) == "NO SURFACE LINK", "pre-landing: no surface link")
	s.publish_event("SURFACE_CONTACT_CONFIRMED", "SRI_KALYAN")
	_ok(str(CommunicationManager.surface_link_status(s)["state"]) == "LINK PENDING", "after landing: link pending")
	s.publish_event("VARUN_SURFACE_COMMUNICATION_ESTABLISHED", "VARUN")
	_ok(str(CommunicationManager.surface_link_status(s)["state"]) == "ORBITAL · SURFACE LINK ACTIVE", "after Varun: link active")
	_done(s)


func test_earth_link_status_progression() -> void:
	var s: SharedMissionState = _fresh()
	_ok(str(CommunicationManager.earth_link_status(s)["state"]).contains("STANDBY"), "starts in standby")
	s.publish_event("COMMUNICATIONS_AVAILABLE", "VARUN")
	_ok(str(CommunicationManager.earth_link_status(s)["state"]).contains("AVAILABLE"), "available once comms are up")
	s.publish_event("EARTH_COMMUNICATION_VERIFIED", "VARUN")
	_ok(str(CommunicationManager.earth_link_status(s)["state"]).contains("VERIFIED"), "verified after the Earth link check")
	_ok(str(CommunicationManager.earth_link_status(s)["detail"]).contains("REFERENCE"), "light-time is labelled a reference value")
	_done(s)


func test_mission_history_is_chronological() -> void:
	var s: SharedMissionState = _fresh()
	s.sim_day = 2191.0
	s.complete_mission("NAV_001")
	s.sim_day = 2200.0
	s.complete_mission("NAV_002")
	var history: Array = s.mission_history()
	_ok(history.size() == 2, "history lists both completed missions")
	_ok(str(history[0]["mission_id"]) == "NAV_001" and str(history[1]["mission_id"]) == "NAV_002", "history is in chronological order")
	_ok(str(history[1]["event"]) == "EUROPA_ORBIT_ESTABLISHED", "history records the completion event")
	_done(s)


func test_communications_survive_save_restore() -> void:
	var s: SharedMissionState = _fresh()
	CommunicationManager.record_event(s, "OBSERVATION_DATA_UPLOADED", "VARUN")
	var snapshot: Dictionary = s.to_dict()
	var restored: SharedMissionState = _fresh()
	restored.from_dict(snapshot)
	_ok(restored.has_communication("EVT_OBSERVATION_DATA_UPLOADED"), "communication log survives save/restore")
	_ok(restored.recent_communications(1).size() == 1, "recent communications reads back")
	_done(s)
	_done(restored)


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