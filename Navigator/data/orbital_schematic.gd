class_name OrbitalSchematic
extends RefCounted

## PARALLAX — the Phase 2 orbital display data model.
##
## This is a CLEARLY LABELLED SCHEMATIC. Distances are in abstract "schematic
## units" (u), body sizes are exaggerated for visibility, and this is NOT a
## scale drawing and NOT for navigation. Phase 3 replaces it with real NASA/JPL
## Horizons ephemerides and physical properties, keeping real and simulated data
## strictly separate.

const SOURCE_LABEL: String = "SCHEMATIC — NOT TO SCALE"
const SOURCE_DETAIL: String = "Abstract units · sizes exaggerated · real NASA/JPL data arrives in Phase 3"
const IS_FICTIONAL: bool = true

## Jupiter is at the world origin (0, 0).
const JUPITER: Dictionary = {
	"id": "JUPITER",
	"name": "Jupiter",
	"designation": "Sol V",
	"type": "PLANET",
	"colour": Color(0.85, 0.72, 0.52),
	"orbit_of": "",
	"orbit_radius": 0.0,
	"radius": 3.6,
	"phase": 0.0,
	"description": "Gas giant and largest planet in the Solar System. PARALLAX operates in the Jovian system, six years into the expedition.",
}

## Galilean moons. Orbit radii are in schematic units; the relative ordering and
## spacing follow the real system but the absolute scale is arbitrary.
const MOONS: Array = [
	{
		"id": "IO", "name": "Io", "designation": "Jupiter I", "type": "MOON",
		"colour": Color(0.90, 0.80, 0.38), "orbit_of": "JUPITER",
		"orbit_radius": 9.0, "radius": 0.5, "phase": 2.1,
		"description": "Volcanically active inner Galilean moon.",
	},
	{
		"id": "EUROPA", "name": "Europa", "designation": "Jupiter II", "type": "MOON",
		"colour": Color(0.72, 0.83, 0.92), "orbit_of": "JUPITER",
		"orbit_radius": 14.5, "radius": 0.42, "phase": 0.55,
		"description": "Icy moon with a global subsurface ocean — the destination of the PARALLAX expedition.",
	},
	{
		"id": "GANYMEDE", "name": "Ganymede", "designation": "Jupiter III", "type": "MOON",
		"colour": Color(0.66, 0.62, 0.56), "orbit_of": "JUPITER",
		"orbit_radius": 20.5, "radius": 0.6, "phase": 3.5,
		"description": "Largest moon in the Solar System.",
	},
	{
		"id": "CALLISTO", "name": "Callisto", "designation": "Jupiter IV", "type": "MOON",
		"colour": Color(0.52, 0.50, 0.48), "orbit_of": "JUPITER",
		"orbit_radius": 27.5, "radius": 0.55, "phase": 1.35,
		"description": "Heavily cratered outermost Galilean moon.",
	},
]

## The player's spacecraft (fictional) — orbits Europa.
const SPACECRAFT: Dictionary = {
	"id": "AETHER",
	"name": "AETHER",
	"designation": "PARALLAX ORBITAL VEHICLE",
	"type": "SPACECRAFT",
	"colour": Color(0.22, 0.82, 0.95),
	"orbit_of": "EUROPA",
	"orbit_radius": 1.6,
	"radius": 0.0,
	"phase": 0.5,
	"description": "PARALLAX orbital spacecraft (fictional mission vehicle). Carries the six-person crew.",
}


static func all() -> Array:
	var out: Array = [JUPITER]
	out.append_array(MOONS)
	return out


static func body(body_id: String) -> Dictionary:
	if body_id == JUPITER["id"]:
		return JUPITER
	for m: Dictionary in MOONS:
		if m["id"] == body_id:
			return m
	if body_id == SPACECRAFT["id"]:
		return SPACECRAFT
	return {}


static func celestial_count() -> int:
	return MOONS.size() + 1