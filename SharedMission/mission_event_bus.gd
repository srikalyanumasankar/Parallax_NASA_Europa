extends Node

## PARALLAX — central mission event bus (autoload: MissionBus).
##
## The single signal hub every module talks to. Character modules (the other
## five crew, and the navigator) publish into it and listen to it; nothing
## reaches into another module's UI directly. MissionState uses this to
## broadcast progression changes.

## A shared mission / cross-character event was published.
signal event_published(event_name: String, source: String)
## A mission's persisted status changed (LOCKED/AVAILABLE/ACTIVE/COMPLETED).
signal mission_state_changed(mission_id: String, state: String)
signal mission_unlocked(mission_id: String)
signal mission_completed(mission_id: String)
## Any progression change at all — panels use this to refresh.
signal progression_changed
## A new entry was written to the shared mission database.
signal database_entry_added(entry: Dictionary)
## A mission/crew communication message arrived.
signal communication_received(message: Dictionary)
## A system alert for the interface (level: INFO / WARNING / CRITICAL).
signal alert_raised(level: String, text: String)


func publish_event(event_name: String, source: String = "EXTERNAL") -> void:
	event_published.emit(event_name, source)


func publish_mission_state_changed(mission_id: String, state: String) -> void:
	mission_state_changed.emit(mission_id, state)


func publish_mission_unlocked(mission_id: String) -> void:
	mission_unlocked.emit(mission_id)


func publish_mission_completed(mission_id: String) -> void:
	mission_completed.emit(mission_id)


func publish_progression_changed() -> void:
	progression_changed.emit()


func publish_database_entry(entry: Dictionary) -> void:
	database_entry_added.emit(entry)


func publish_communication(message: Dictionary) -> void:
	communication_received.emit(message)


func raise_alert(level: String, text: String) -> void:
	alert_raised.emit(level, text)