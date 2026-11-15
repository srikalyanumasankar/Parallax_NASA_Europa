class_name MissionUnlockEvaluator
extends RefCounted

## PARALLAX — evaluates a mission's dependencies against the shared state.
##
## Extracted as its own class so the progression logic is testable and reusable,
## but it holds NO state of its own: it reads a SharedMissionState, which remains
## the single source of truth. Supports ALL and ANY groups plus flags and data.

const STATUS_LOCKED: String = "LOCKED"
const STATUS_AVAILABLE: String = "AVAILABLE"
const STATUS_ACTIVE: String = "ACTIVE"
const STATUS_COMPLETED: String = "COMPLETED"


## Returns { "unlocked": bool, "requirements": [{label, met}], "missing": [String] }.
static func evaluate(mission_id: String, state: SharedMissionState) -> Dictionary:
	var def: Dictionary = MissionDefinitions.get_mission(mission_id)
	if def.is_empty():
		return {"unlocked": false, "requirements": [], "missing": ["Unknown mission"]}

	var req: Dictionary = def.get("requirements", {})
	var lines: Array = []
	var missing: Array = []
	var all_met: bool = true

	# ALL prerequisite missions
	for raw_id in req.get("missions", []) as Array:
		var mid: String = str(raw_id)
		var met: bool = state.is_completed(mid)
		lines.append({"label": MissionDefinitions.get_mission(mid).get("title", mid), "met": met})
		if not met:
			all_met = false
			missing.append("Mission incomplete: " + mid)

	# ANY-one-of missions
	var any_missions: Array = req.get("any_missions", [])
	if not any_missions.is_empty():
		var met_any: bool = false
		var names: Array = []
		for raw_id in any_missions:
			var mid2: String = str(raw_id)
			names.append(MissionDefinitions.get_mission(mid2).get("title", mid2))
			if state.is_completed(mid2):
				met_any = true
		lines.append({"label": "Any of: " + ", ".join(names), "met": met_any})
		if not met_any:
			all_met = false
			missing.append("None of the alternative missions complete")

	# ALL required events
	for raw_ev in req.get("events", []) as Array:
		var ev: String = str(raw_ev)
		var met_ev: bool = state.has_event(ev)
		lines.append({"label": MissionDefinitions.event_label(ev), "met": met_ev})
		if not met_ev:
			all_met = false
			missing.append("Waiting for: " + MissionDefinitions.event_label(ev))

	# ANY-one-of events
	var any_events: Array = req.get("any_events", [])
	if not any_events.is_empty():
		var met_any_ev: bool = false
		var ev_names: Array = []
		for raw_ev in any_events:
			var ev2: String = str(raw_ev)
			ev_names.append(MissionDefinitions.event_label(ev2))
			if state.has_event(ev2):
				met_any_ev = true
		lines.append({"label": "Any of: " + ", ".join(ev_names), "met": met_any_ev})
		if not met_any_ev:
			all_met = false
			missing.append("None of the alternative events received")

	# Story flags / milestones
	for raw_flag in req.get("flags", []) as Array:
		var flag: String = str(raw_flag)
		var met_flag: bool = state.has_flag(flag)
		lines.append({"label": MissionDefinitions.milestone_label(flag), "met": met_flag})
		if not met_flag:
			all_met = false
			missing.append("Milestone not reached: " + MissionDefinitions.milestone_label(flag))

	# Uploaded data
	for raw_data in req.get("data", []) as Array:
		var did: String = str(raw_data)
		var met_data: bool = state.has_data(did)
		lines.append({"label": "Uploaded data: " + did, "met": met_data})
		if not met_data:
			all_met = false
			missing.append("Data not uploaded: " + did)

	return {"unlocked": all_met, "requirements": lines, "missing": missing}


static func state_of(mission_id: String, state: SharedMissionState) -> String:
	if state.is_completed(mission_id):
		return STATUS_COMPLETED
	if evaluate(mission_id, state).get("unlocked", false):
		return STATUS_ACTIVE if state.active_mission == mission_id else STATUS_AVAILABLE
	return STATUS_LOCKED