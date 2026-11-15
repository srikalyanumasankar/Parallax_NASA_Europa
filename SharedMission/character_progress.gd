class_name CharacterProgress
extends RefCounted

## PARALLAX — cross-character progress façade.
##
## The six-character expedition shares ONE source of truth (SharedMissionState).
## This is a thin, stateless adapter so any character module (Varun, Manic,
## Krish, Dhanush, Amrish, and the navigator) can publish its completion events
## and read mission-wide progress WITHOUT reaching into another module's UI or
## creating a second, competing progression store.

const NAVIGATOR: String = "SRI_KALYAN"


## A character reports that one of its missions is complete.
static func complete_mission_for(state: SharedMissionState, character_id: String, mission_id: String) -> bool:
	return state.complete_mission(mission_id)


## A character publishes a shared event (its own completion signal).
static func publish(state: SharedMissionState, character_id: String, event_name: String) -> void:
	state.publish_event(event_name, character_id)


## Upload scientific data and its completion event from a character.
static func upload(state: SharedMissionState, character_id: String, entry_id: String, title: String, event_name: String = "") -> void:
	state.upload_data(entry_id, character_id, title, event_name)


## The events a given character has contributed, in receipt order.
static func events_from(state: SharedMissionState, character_id: String) -> Array:
	var out: Array = []
	var names: Array = state.shared_events.keys()
	names.sort_custom(func(a: String, b: String) -> bool:
		return int(state.shared_events[a].get("seq", 0)) < int(state.shared_events[b].get("seq", 0)))
	for name in names:
		if str(state.shared_events[name].get("source", "")) == character_id:
			out.append(str(name))
	return out


## A mission-wide progress summary for a character-selection screen.
static func progress_summary(state: SharedMissionState) -> Dictionary:
	var completed_events: int = 0
	for mid in MissionDefinitions.mission_ids():
		if state.is_completed(str(mid)):
			completed_events += 1
	return {
		"missions_completed": state.completed_count(),
		"missions_total": state.mission_count(),
		"available": state.available_missions(),
		"active": state.active_mission,
		"events": state.shared_events.size(),
		"database_entries": state.database.size(),
		"per_character": {
			"VARUN": events_from(state, "VARUN").size(),
			"MANIC": events_from(state, "MANIC").size(),
			"KRISH": events_from(state, "KRISH").size(),
			"DHANUSH": events_from(state, "DHANUSH").size(),
			"AMRISH": events_from(state, "AMRISH").size(),
		},
	}