class_name SystemsDefinitions
extends RefCounted

## PARALLAX — FICTIONAL spacecraft subsystem definitions for the SYSTEMS section.
##
## These thresholds are the game's OWN simulation limits for its fictional
## spacecraft, not engineering or NASA data. Real astronomical values live in
## CelestialData; the fictional mission configuration lives in SimulatedMissionData.

## Each subsystem: id, display name, the meter's own label, and the limits that
## raise a non-nominal state.
const SUBSYSTEMS: Array = [
	{"id": "propulsion", "name": "PROPULSION", "label": "Propulsion — fuel level", "warn_below": 0.15},
	{"id": "power", "name": "POWER", "label": "Power — solar array output", "warn_below": 0.35},
	{"id": "reactor", "name": "REACTOR", "label": "Reactor output", "warn_below": 0.25},
	{"id": "thermal", "name": "THERMAL", "label": "Thermal regulation", "warn_below": 250.0, "warn_above": 305.0},
	{"id": "comms", "name": "COMMUNICATIONS", "label": "Communications — data rate", "warn_below": 5.0},
	{"id": "structure", "name": "STRUCTURAL", "label": "Structural integrity", "warn_below": 0.90},
	{"id": "radiation", "name": "RADIATION", "label": "Radiation dose", "warn_above": 0.5},
]


static func get_subsystem(id: String) -> Dictionary:
	for s in SUBSYSTEMS:
		if str(s.get("id", "")) == id:
			return s
	return {}


static func ids() -> Array:
	var out: Array = []
	for s in SUBSYSTEMS:
		out.append(str(s.get("id", "")))
	return out