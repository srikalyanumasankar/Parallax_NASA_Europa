class_name SectionObjectives
extends RefCounted

## PARALLAX — maps the TELEMETRY and SYSTEMS sections to the mission objectives
## their checks satisfy.
##
## IMPORTANT: an objective that is backed by a manoeuvre operation (see
## ManeuverDefinitions.objective_keys) is GATED — it must be earned in the
## MANOEUVRES section, so these helpers deliberately never record it. The
## objectives listed here are the mission's informational maintenance tasks.

const TELEMETRY: Array = [
	"Inspect spacecraft position and velocity",
	"Check attitude and trajectory",
	"Activate navigation displays",
	"Verify navigation data",
	"Review available crew telemetry",
	"Monitor relative position and velocity",
	"Review approach telemetry",
]

const SYSTEMS: Array = [
	"Inspect spacecraft health",
	"Check spacecraft health",
	"Check power and thermal systems",
	"Check power",
	"Inspect propulsion and hull health",
]


## The objectives of `mission_id` that are in `allow` AND are not gated by a
## manoeuvre operation. Pure — no shared state, safe to unit test.
static func applicable(mission_id: String, allow: Array) -> Array:
	if mission_id == "":
		return []
	var def: Dictionary = MissionDefinitions.get_mission(mission_id)
	var gated: Array = ManeuverDefinitions.objective_keys(mission_id)
	var out: Array = []
	for obj in def.get("objectives", []) as Array:
		var o: String = str(obj)
		if allow.has(o) and not gated.has(o) and not out.has(o):
			out.append(o)
	return out


## Complete the applicable objectives of the currently active mission.
## Returns the objectives actually recorded this call.
static func record(allow: Array) -> Array:
	var recorded: Array = []
	if MissionState == null:
		return recorded
	var mid: String = MissionState.active_mission
	for o in applicable(mid, allow):
		if not MissionState.is_objective_done(mid, o) and MissionState.complete_objective(mid, o):
			recorded.append(o)
	return recorded