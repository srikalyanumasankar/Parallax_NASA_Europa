class_name MissionDatabase
extends RefCounted

## PARALLAX — shared mission database façade.
##
## A thin, stateless adapter over SharedMissionState's database so any module can
## read or write shared records without touching another module's code. It keeps
## no state of its own — SharedMissionState remains the single source of truth.

static func upload(state: SharedMissionState, character_id: String, entry_id: String, title: String, event_name: String = "") -> void:
	state.upload_data(entry_id, character_id, title, event_name)


static func add_file(state: SharedMissionState, entry_id: String, source: String, title: String, kind: String = "FILE") -> void:
	state.add_database_entry({"id": entry_id, "source": source, "title": title, "kind": kind})


static func entries(state: SharedMissionState) -> Array:
	return state.database


static func has(state: SharedMissionState, entry_id: String) -> bool:
	return state.has_data(entry_id)


static func count(state: SharedMissionState) -> int:
	return state.database.size()