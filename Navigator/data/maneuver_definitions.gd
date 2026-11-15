class_name ManeuverDefinitions
extends RefCounted

## PARALLAX — data-driven definition of the navigation operations the player
## can configure and execute. Each operation is bound to a mission and to the
## mission objective it fulfils, so nothing is hard-coded into a button.
##
## kinds:
##   "verify"          — records a verification; no orbit change.
##   "target_altitude" — player sets a target altitude; required Δv computed.
##   "delta_v"         — player sets a Δv impulse directly.
##
## "confirm": true operations require a second, explicit confirmation press.

const OPERATIONS: Dictionary = {
	"NAV_001": [
		{
			"id": "OP_VERIFY_NAV",
			"name": "Verify Navigation Data",
			"kind": "verify",
			"objective": "Verify navigation data",
			"description": "Cross-check the navigation solution against the approach data and record the verification in the mission record.",
			"confirm": false,
		},
	],
	"NAV_002": [
		{
			"id": "OP_ORBIT_INSERT",
			"name": "Orbital Insertion Burn",
			"kind": "target_altitude",
			"objective": "Execute the mission-defined manoeuvre sequence",
			"description": "Configure the fictional mission's insertion burn to establish a circular orbit around Europa at the target altitude.",
			"param_label": "TARGET ALTITUDE",
			"unit": "km",
			"min": 20.0,
			"max": 300.0,
			"default": 100.0,
			"step": 5.0,
			"confirm": true,
		},
	],
	"NAV_008": [
		{
			"id": "OP_DOCK_APPROACH",
			"name": "Docking Approach Burn",
			"kind": "delta_v",
			"objective": "Coordinate the docking procedure",
			"description": "Apply a small prograde or retrograde impulse to match the returning lander's approach corridor.",
			"param_label": "DELTA-V",
			"unit": "m/s",
			"min": -20.0,
			"max": 20.0,
			"default": 0.0,
			"step": 1.0,
			"confirm": true,
		},
	],
}


static func for_mission(mission_id: String) -> Array:
	return OPERATIONS.get(mission_id, [])


static func get_operation(op_id: String) -> Dictionary:
	for key in OPERATIONS.keys():
		for op in OPERATIONS[key] as Array:
			if str(op.get("id", "")) == op_id:
				return op
	return {}


static func has_operations(mission_id: String) -> bool:
	return not for_mission(mission_id).is_empty()


## The mission objectives that an operation actually fulfils — these are the
## objectives that gate mission completion. Objectives not backed by an
## operation stay on the checklist as informational tasks.
static func objective_keys(mission_id: String) -> Array:
	var out: Array = []
	for op in for_mission(mission_id):
		var o: String = str(op.get("objective", ""))
		if o != "" and not out.has(o):
			out.append(o)
	return out