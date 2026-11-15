extends Node
class_name SharedMissionState

## PARALLAX — shared mission state (autoload: MissionState).
##
## The single source of truth for the six-character expedition's progression.
## It stores completed missions, received cross-module events, uploaded data,
## story flags and mission history, evaluates dependencies (ALL + ANY), and
## saves/restores everything with a versioned save.
##
## Nothing else may mark a mission complete: completion flows through here, so
## switching characters or reopening the navigator never loses progress. Future
## character modules just call `publish_event()` / `complete_mission()`.

## All-signal fired whenever anything in the shared state changes.
signal changed

const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://parallax_mission_state.json"

## The story begins six years after departure. This is a FICTIONAL mission-elapsed
## clock (not a real calendar date).
const DEFAULT_MET_DAYS: float = 2191.0

var completed_missions: Dictionary = {}      # mission_id -> {day: float, event: String}
var active_mission: String = ""
var shared_events: Dictionary = {}           # event_name -> {source: String, seq: int, day: float}
var database: Array = []                     # [{id, source, title, kind, day}]
var communications: Array = []               # [{id, source, subject, body, kind, day}] oldest first
var story_flags: Dictionary = {}             # flag_name -> bool
var completed_objectives: Dictionary = {}    # mission_id -> Array[String] (objective text)
var sim_day: float = 0.0                     # mission-elapsed days (fictional sim clock)

var _sequence: int = 0
var _announced_available: Dictionary = {}

## Writing is on by default; tests disable it so they never touch the real save.
var auto_save: bool = true
var save_path: String = SAVE_PATH
var _bus: Node = null


func _ready() -> void:
	_bus = get_node_or_null("/root/MissionBus")
	if not load_game():
		sim_day = DEFAULT_MET_DAYS


# --------------------------------------------------------------------------- #
#  Queries
# --------------------------------------------------------------------------- #

func is_completed(mission_id: String) -> bool:
	return completed_missions.has(mission_id)


func has_event(event_name: String) -> bool:
	return shared_events.has(event_name)


func event_source(event_name: String) -> String:
	var e: Dictionary = shared_events.get(event_name, {})
	return e.get("source", "UNKNOWN")


func has_flag(flag_name: String) -> bool:
	return bool(story_flags.get(flag_name, false))


func has_data(entry_id: String) -> bool:
	for entry: Dictionary in database:
		if entry.get("id", "") == entry_id:
			return true
	return false


## Current status of a mission: LOCKED / AVAILABLE / ACTIVE / COMPLETED.
func mission_state(mission_id: String) -> String:
	return MissionUnlockEvaluator.state_of(mission_id, self)


## Evaluate every dependency of a mission and return reasons for the UI.
## Returns { "unlocked": bool, "requirements": [{label, met}], "missing": [String] }.
#  Delegates to MissionUnlockEvaluator, which holds no state of its own.
func evaluate(mission_id: String) -> Dictionary:
	return MissionUnlockEvaluator.evaluate(mission_id, self)


func available_missions() -> Array:
	var out: Array = []
	for mid in MissionDefinitions.mission_ids():
		if not is_completed(mid) and evaluate(mid).get("unlocked", false):
			out.append(mid)
	return out


func completed_count() -> int:
	return completed_missions.size()


func mission_count() -> int:
	return MissionDefinitions.MISSIONS.size()


# --------------------------------------------------------------------------- #
#  Mutations
# --------------------------------------------------------------------------- #

## Record a cross-module / story event. Idempotent — duplicate events never
## create duplicate records and never re-corrupt progression.
func publish_event(event_name: String, source: String = "EXTERNAL") -> void:
	if shared_events.has(event_name):
		return
	_sequence += 1
	shared_events[event_name] = {"source": source, "seq": _sequence, "day": sim_day}
	_bus_call("publish_event", [event_name, source])
	_refresh_unlocks()
	changed.emit()
	_persist()


## Write an entry into the shared mission database (uploaded observations,
## reports, mission files). Deduplicated by id.
func add_database_entry(entry: Dictionary) -> void:
	var entry_id: String = str(entry.get("id", ""))
	if entry_id != "" and has_data(entry_id):
		return
	var record: Dictionary = entry.duplicate(true)
	record["id"] = entry_id
	record.set("day", sim_day)
	database.append(record)
	_bus_call("publish_database_entry", [record])
	_refresh_unlocks()
	changed.emit()
	_persist()


## Upload a scientific data record: stores it AND publishes its completion
## event (e.g. "KANDAM_DATA_UPLOADED"). Used by character modules.
func upload_data(data_id: String, source: String, title: String, event_name: String = "") -> void:
	add_database_entry({"id": data_id, "source": source, "title": title, "kind": "DATA"})
	if event_name != "":
		publish_event(event_name, source)


## Record a communication (mission-control message, crew report, directive).
## Deduplicated by id so the same event never logs twice.
func log_message(message: Dictionary) -> bool:
	var mid: String = str(message.get("id", ""))
	if mid != "" and has_communication(mid):
		return false
	_sequence += 1
	var rec: Dictionary = message.duplicate(true)
	if mid == "":
		rec["id"] = "MSG_%d" % _sequence
	rec["day"] = sim_day
	communications.append(rec)
	_bus_call("publish_communication", [rec])
	changed.emit()
	_persist()
	return true


func has_communication(message_id: String) -> bool:
	for m in communications:
		if str(m.get("id", "")) == message_id:
			return true
	return false


## Newest-first list of recent communications.
func recent_communications(count: int) -> Array:
	var out: Array = communications.duplicate()
	out.reverse()
	return out.slice(0, mini(count, out.size()))


## Completed missions in chronological order, for the mission-history list.
func mission_history() -> Array:
	var out: Array = []
	for mid in MissionDefinitions.mission_ids():
		var id: String = str(mid)
		if is_completed(id):
			var rec: Dictionary = completed_missions.get(id, {})
			out.append({
				"mission_id": id,
				"title": MissionDefinitions.get_mission(id).get("title", id),
				"day": float(rec.get("day", 0.0)),
				"event": str(rec.get("event", "")),
			})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["day"]) < float(b["day"]))
	return out


func set_flag(flag_name: String, value: bool = true) -> void:
	if has_flag(flag_name) == value:
		return
	story_flags[flag_name] = value
	_refresh_unlocks()
	changed.emit()
	_persist()


## Story milestone helpers (milestones are stored as flags).
func set_milestone(milestone_name: String, reached: bool = true) -> void:
	set_flag(milestone_name, reached)


func has_milestone(milestone_name: String) -> bool:
	return has_flag(milestone_name)


# --------------------------------------------------------------------------- #
#  Objective tracking
# --------------------------------------------------------------------------- #

## Record that one of a mission's objectives has been completed. Idempotent.
func complete_objective(mission_id: String, objective: String) -> bool:
	if mission_id == "" or objective == "":
		return false
	var arr: Array = completed_objectives.get(mission_id, [])
	if arr.has(objective):
		return false
	arr.append(objective)
	completed_objectives[mission_id] = arr
	_bus_call("publish_progression_changed", [])
	changed.emit()
	_persist()
	return true


func is_objective_done(mission_id: String, objective: String) -> bool:
	var arr: Array = completed_objectives.get(mission_id, [])
	return arr.has(objective)


## The objectives that gate completion: those backed by an actual operation.
## A mission with no operations is never gated by objectives.
func required_objectives(mission_id: String) -> Array:
	return ManeuverDefinitions.objective_keys(mission_id)


func objectives_done_count(mission_id: String) -> int:
	var arr: Array = completed_objectives.get(mission_id, [])
	var n: int = 0
	for o in required_objectives(mission_id):
		if arr.has(o):
			n += 1
	return n


func required_objective_count(mission_id: String) -> int:
	return required_objectives(mission_id).size()


## True when every operation-backed objective of the mission has been recorded.
func are_objectives_done(mission_id: String) -> bool:
	var required: Array = required_objectives(mission_id)
	if required.is_empty():
		return true
	for o in required:
		if not is_objective_done(mission_id, str(o)):
			return false
	return true


## Begin an AVAILABLE mission (marks it ACTIVE).
func start_mission(mission_id: String) -> bool:
	if mission_state(mission_id) != MissionDefinitions.STATUS_AVAILABLE:
		return false
	active_mission = mission_id
	_bus_call("publish_mission_state_changed", [mission_id, MissionDefinitions.STATUS_ACTIVE])
	changed.emit()
	return true


## Complete a mission and publish its completion event. No-op if the mission is
## already complete (keeps completion records stable under duplicate calls).
func complete_mission(mission_id: String) -> bool:
	if is_completed(mission_id):
		return false
	if MissionDefinitions.get_mission(mission_id).is_empty():
		return false
	completed_missions[mission_id] = {"day": sim_day, "event": MissionDefinitions.get_mission(mission_id).get("completion_event", "")}
	if active_mission == mission_id:
		active_mission = ""
	_bus_call("publish_mission_completed", [mission_id])
	var ev: String = MissionDefinitions.get_mission(mission_id).get("completion_event", "")
	if ev != "":
		publish_event(ev, "NAVIGATOR")
	_refresh_unlocks()
	changed.emit()
	_persist()
	return true


## Reset the navigator's own progression (does NOT touch other characters'
## records in the shared database in the real game; provided for testing).
func reset_progress() -> void:
	completed_missions.clear()
	shared_events.clear()
	database.clear()
	story_flags.clear()
	active_mission = ""
	_sequence = 0
	_announced_available.clear()
	changed.emit()


# --------------------------------------------------------------------------- #
#  Internal
# --------------------------------------------------------------------------- #

func _refresh_unlocks() -> void:
	for mid in available_missions():
		if not _announced_available.has(mid):
			_announced_available[mid] = true
			_bus_call("publish_mission_unlocked", [mid])
	_bus_call("publish_progression_changed", [])


func _bus_call(method: String, args: Array) -> void:
	if _bus != null and _bus.has_method(method):
		_bus.callv(method, args)


func _persist() -> void:
	if auto_save:
		save_game()


# --------------------------------------------------------------------------- #
#  Persistence (versioned, tolerant of missing/outdated fields)
# --------------------------------------------------------------------------- #

func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"completed_missions": completed_missions.duplicate(true),
		"active_mission": active_mission,
		"shared_events": shared_events.duplicate(true),
		"database": database.duplicate(true),
		"communications": communications.duplicate(true),
		"story_flags": story_flags.duplicate(true),
		"completed_objectives": completed_objectives.duplicate(true),
		"sim_day": sim_day,
		"sequence": _sequence,
	}


func from_dict(data: Dictionary) -> void:
	completed_missions = data.get("completed_missions", {})
	active_mission = str(data.get("active_mission", ""))
	shared_events = data.get("shared_events", {})
	database = data.get("database", [])
	communications = data.get("communications", [])
	story_flags = data.get("story_flags", {})
	completed_objectives = data.get("completed_objectives", {})
	sim_day = float(data.get("sim_day", 0.0))
	_sequence = int(data.get("sequence", 0))
	# Seed the announced set so we do not re-announce on load.
	_announced_available.clear()
	for mid in available_missions():
		_announced_available[mid] = true
	changed.emit()


func save_game() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("MissionState: could not write save at %s" % save_path)
		return
	file.store_string(JSON.stringify(to_dict(), "\t"))
	file.close()


func load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("MissionState: save file malformed, ignoring")
		return false
	from_dict(parsed)
	return true