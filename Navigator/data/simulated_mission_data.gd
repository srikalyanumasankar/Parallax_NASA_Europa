class_name SimulatedMissionData
extends RefCounted

## PARALLAX — FICTIONAL mission parameters for the spacecraft simulation.
##
## This is deliberately kept apart from CelestialData (which holds real
## NASA/JPL astronomical data). Nothing here is a NASA-verified mission value;
## it is the game's own fictional mission configuration.

const IS_SIMULATED: bool = true
const SOURCE_LABEL: String = "FICTIONAL PARALLAX MISSION SIMULATION"

const SPACECRAFT_ID: String = "AETHER"
const SPACECRAFT_NAME: String = "AETHER"
const CREW_SIZE: int = 6

## The fictional mission plan targets roughly this altitude above Europa. It is
## the game's reference target, NOT a NASA-verified mission orbit.
const REFERENCE_ORBIT_ALTITUDE_KM: float = 100.0


static func note() -> String:
	return "Fictional mission parameters for the PARALLAX spacecraft simulation — not NASA-verified mission data."