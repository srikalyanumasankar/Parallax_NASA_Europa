class_name MissionDefinitions
extends RefCounted

## PARALLAX — static, configurable definition of every story mission and the
## shared event / data vocabulary used by the mission progression system.
##
## Missions are keyed by a STABLE id (NAV_001 …) and never by display name.
## Nothing here is hard-coded into UI buttons: the Navigator reads these
## definitions through MissionState, and future character modules publish the
## same events into the shared state.
##
## A mission's `requirements` supports AND and OR groups so progression is not
## a single linear chain:
##   missions      — ALL of these mission ids must be completed
##   any_missions  — at least ONE of these mission ids must be completed
##   events        — ALL of these shared events must have been received
##   any_events    — at least ONE of these shared events must have been received
##   flags         — ALL of these story flags must be set
##   data          — ALL of these database upload ids must be present

const STATUS_LOCKED: String = "LOCKED"
const STATUS_AVAILABLE: String = "AVAILABLE"
const STATUS_ACTIVE: String = "ACTIVE"
const STATUS_COMPLETED: String = "COMPLETED"

const CREW_ROSTER: Array = [
	{"id": "SRI_KALYAN", "name": "Sri Kalyan", "role": "Flight & Navigation Officer", "station": "Orbital — Navigation"},
	{"id": "VARUN", "name": "Varun", "role": "Radio Astronomy & Communications Officer", "station": "Orbital — Comms Array"},
	{"id": "MANIC", "name": "Manic", "role": "Base Operations & Environmental Scientist", "station": "Surface — Habitat"},
	{"id": "KRISH", "name": "Krish", "role": "Rover Operations & Planetary Field Scientist", "station": "Surface — KANDAM"},
	{"id": "DHANUSH", "name": "Dhanush", "role": "Subsurface Ocean Operations Scientist", "station": "Surface — KADAL"},
	{"id": "AMRISH", "name": "Amrish", "role": "Astrobiologist", "station": "Surface — Laboratory"},
]

## Human-readable labels for shared events (used to explain locked missions).
const EVENT_LABELS: Dictionary = {
	"NAVIGATION_SYSTEMS_VERIFIED": "Navigation systems verified",
	"EUROPA_ORBIT_ESTABLISHED": "Europa orbit established",
	"ORBITAL_SYSTEMS_VERIFIED": "Orbital spacecraft systems verified",
	"LANDING_PREPARATION_CONFIRMED": "Landing preparation confirmed",
	"SURFACE_COMMUNICATION_READY": "Communications readiness",
	"SURFACE_CONTACT_CONFIRMED": "Surface contact confirmed",
	"MANIC_BASE_OPERATIONAL": "Surface base operational",
	"VARUN_SURFACE_COMMUNICATION_ESTABLISHED": "Surface communication link established",
	"ORBITAL_SURFACE_LINK_VERIFIED": "Orbital-surface link verified",
	"KANDAM_OPERATIONAL": "KANDAM rover operational",
	"KANDAM_SURVEY_STARTED": "KANDAM survey started",
	"KANDAM_DATA_UPLOADED": "KANDAM survey data uploaded",
	"KANDAM_INVESTIGATION_COMPLETED": "KANDAM investigation complete",
	"KADAL_OPERATIONAL": "KADAL cryobot operational",
	"KADAL_DRILLING_COMPLETED": "KADAL drilling complete",
	"SUBSURFACE_SAMPLE_RETRIEVED": "Subsurface sample retrieved",
	"KADAL_DATA_UPLOADED": "KADAL subsurface data uploaded",
	"ENVIRONMENTAL_SYSTEMS_VERIFIED": "Environmental systems verified",
	"SAMPLE_STORED": "Sample stored",
	"CREW_AND_BASE_STATUS_VERIFIED": "Crew and base status verified",
	"AMRISH_LABORATORY_OPERATIONAL": "Laboratory operational",
	"SAMPLE_RECEIVED": "Sample received",
	"SAMPLE_ANALYSIS_COMPLETED": "Sample analysis complete",
	"SCIENTIFIC_RESULTS_UPLOADED": "Scientific results uploaded",
	"COMMUNICATIONS_OPERATIONAL": "Communications operational",
	"RADIO_OBSERVATIONS_RECORDED": "Radio observations recorded",
	"OBSERVATION_DATA_UPLOADED": "Observation data uploaded",
	"EARTH_COMMUNICATION_VERIFIED": "Earth communication verified",
	"MISSION_DATA_INTEGRATED": "Mission data integrated",
	"SCIENTIFIC_INVESTIGATION_COMPLETE": "Scientific investigation complete",
	"SAMPLES_PACKAGED": "Samples and records packaged",
	"SURFACE_RETURN_READY": "Surface crew return-ready",
	"COMMUNICATIONS_AVAILABLE": "Communications available",
	"LANDER_RETURNING_TO_ORBIT": "Lander returning to orbit",
	"LANDER_DOCKED": "Lander docked",
	"FINAL_SYSTEMS_VERIFIED": "Final systems verified",
	"FINAL_SIGNAL_DETECTED": "Final signal detected",
}

## Story milestones — persisted as flags, used as mission dependency gates.
const MILESTONES: Dictionary = {
	"LANDING_PREPARATION_CONFIRMED": "Landing preparation confirmed",
	"SURFACE_COMMUNICATION_READY": "Surface communication readiness",
	"SURFACE_CONTACT_CONFIRMED": "Surface contact confirmed",
	"BASE_OPERATIONAL": "Surface base operational",
	"SCIENTIFIC_INVESTIGATION_COMPLETE": "Scientific investigation complete",
	"SAMPLES_PACKAGED": "Samples and records packaged",
	"SURFACE_RETURN_READY": "Surface crew return-ready",
	"FINAL_SIGNAL": "Final signal sequence reached",
}

## The full mission set. Ordered by intended play sequence.
const MISSIONS: Dictionary = {
	"NAV_001": {
		"id": "NAV_001",
		"title": "Activate Navigation Systems",
		"phase": "PHASE A — JUPITER ARRIVAL",
		"character": "SRI_KALYAN",
		"mandatory": true,
		"summary": "Bring the navigation station online six years into the expedition and verify approach data.",
		"objectives": [
			"Activate navigation displays",
			"Inspect spacecraft position and velocity",
			"Check attitude and trajectory",
			"Inspect propulsion and hull health",
			"Review the Jupiter-system approach",
			"Verify navigation data",
		],
		"requirements": {},
		"completion_event": "NAVIGATION_SYSTEMS_VERIFIED",
	},
	"NAV_002": {
		"id": "NAV_002",
		"title": "Jupiter Approach & Europa Orbit",
		"phase": "PHASE A — JUPITER ARRIVAL",
		"character": "SRI_KALYAN",
		"mandatory": true,
		"summary": "Configure and execute the fictional mission's orbital-insertion manoeuvre to establish a ~100 km Europa orbit.",
		"objectives": [
			"Examine Jupiter and Europa positions",
			"Review the approach trajectory",
			"Inspect orbital parameters",
			"Configure the required navigation operation",
			"Execute the mission-defined manoeuvre sequence",
			"Monitor telemetry",
			"Verify the resulting trajectory",
		],
		"requirements": {"missions": ["NAV_001"]},
		"completion_event": "EUROPA_ORBIT_ESTABLISHED",
	},
	"NAV_003": {
		"id": "NAV_003",
		"title": "Orbital Spacecraft Systems Verification",
		"phase": "PHASE B — ORBITAL VERIFICATION",
		"character": "SRI_KALYAN",
		"mandatory": true,
		"summary": "Verify the orbital station is ready for continued operations.",
		"objectives": [
			"Inspect spacecraft health",
			"Check power and thermal systems",
			"Monitor propulsion",
			"Check radiation exposure",
			"Check communications",
			"Review the shared mission database",
		],
		"requirements": {"missions": ["NAV_002"]},
		"completion_event": "ORBITAL_SYSTEMS_VERIFIED",
	},
	"NAV_004": {
		"id": "NAV_004",
		"title": "Coordinate Lander Separation",
		"phase": "PHASE C — LANDER & LANDING",
		"character": "SRI_KALYAN",
		"mandatory": true,
		"summary": "Coordinate lander separation and monitor the landing toward Thera Macula from orbit.",
		"objectives": [
			"Review lander status",
			"Review available crew telemetry",
			"Verify landing-preparation information",
			"Confirm communication availability",
			"Coordinate separation",
			"Monitor lander telemetry and landing",
			"Receive landing confirmation",
		],
		"requirements": {
			"missions": ["NAV_002", "NAV_003"],
			"events": ["LANDING_PREPARATION_CONFIRMED", "SURFACE_COMMUNICATION_READY"],
		},
		"completion_event": "SURFACE_CONTACT_CONFIRMED",
	},
	"NAV_005": {
		"id": "NAV_005",
		"title": "Establish Orbital-Surface Operations",
		"phase": "PHASE D — SURFACE BASE",
		"character": "SRI_KALYAN",
		"mandatory": true,
		"summary": "Verify the surface communication link and coordinate orbital and surface operations.",
		"objectives": [
			"Verify the surface communication link",
			"Monitor surface-base status",
			"Check crew telemetry",
			"Inspect surface mission information",
			"Verify the shared mission database",
			"Coordinate orbital and surface operations",
		],
		"requirements": {
			"events": [
				"SURFACE_CONTACT_CONFIRMED",
				"MANIC_BASE_OPERATIONAL",
				"VARUN_SURFACE_COMMUNICATION_ESTABLISHED",
			],
		},
		"completion_event": "ORBITAL_SURFACE_LINK_VERIFIED",
	},
	"NAV_006": {
		"id": "NAV_006",
		"title": "Mission Data Integration",
		"phase": "PHASE E — SCIENTIFIC INVESTIGATION",
		"character": "SRI_KALYAN",
		"mandatory": true,
		"summary": "Integrate the required findings from every character module into the shared mission database.",
		"objectives": [
			"Access the common mission database",
			"Review data received from each character",
			"Inspect upload status",
			"Compare mission records",
			"Verify data completeness",
			"Record mission-wide progress",
			"Transmit required reports",
		],
		"requirements": {
			"events": [
				"KANDAM_DATA_UPLOADED",
				"KADAL_DATA_UPLOADED",
				"ENVIRONMENTAL_SYSTEMS_VERIFIED",
				"SAMPLE_STORED",
				"SCIENTIFIC_RESULTS_UPLOADED",
				"OBSERVATION_DATA_UPLOADED",
			],
		},
		"completion_event": "MISSION_DATA_INTEGRATED",
	},
	"NAV_007": {
		"id": "NAV_007",
		"title": "Coordinate Surface Crew Return",
		"phase": "PHASE F — RETURN TO ORBIT",
		"character": "SRI_KALYAN",
		"mandatory": true,
		"summary": "Coordinate the surface crew's return launch and track the lander back to orbit.",
		"objectives": [
			"Review return readiness",
			"Monitor the lander's launch",
			"Track the lander's trajectory",
			"Monitor communication",
			"Coordinate approach to the orbital spacecraft",
			"Prepare the docking system",
		],
		"requirements": {
			"events": [
				"SCIENTIFIC_INVESTIGATION_COMPLETE",
				"SAMPLES_PACKAGED",
				"SURFACE_RETURN_READY",
				"COMMUNICATIONS_AVAILABLE",
			],
		},
		"completion_event": "LANDER_RETURNING_TO_ORBIT",
	},
	"NAV_008": {
		"id": "NAV_008",
		"title": "Docking Operations",
		"phase": "PHASE F — RETURN TO ORBIT",
		"character": "SRI_KALYAN",
		"mandatory": true,
		"summary": "Coordinate the docking procedure and confirm crew and vehicle status.",
		"objectives": [
			"Monitor relative position and velocity",
			"Review approach telemetry",
			"Coordinate the docking procedure",
			"Monitor spacecraft status",
			"Confirm docking",
			"Verify crew and vehicle status",
		],
		"requirements": {"events": ["LANDER_RETURNING_TO_ORBIT"]},
		"completion_event": "LANDER_DOCKED",
	},
	"NAV_009": {
		"id": "NAV_009",
		"title": "Final Spacecraft Verification",
		"phase": "PHASE G — FINAL SEQUENCE",
		"character": "SRI_KALYAN",
		"mandatory": true,
		"summary": "Complete the final orbital-spacecraft system checks ahead of the atomic-clock handshake.",
		"objectives": [
			"Check spacecraft health",
			"Check power",
			"Check communications",
			"Check crew status",
			"Verify mission records",
			"Complete final system checks",
		],
		"requirements": {"events": ["LANDER_DOCKED"]},
		"completion_event": "FINAL_SYSTEMS_VERIFIED",
	},
}

const MISSION_ORDER: Array = [
	"NAV_001", "NAV_002", "NAV_003", "NAV_004", "NAV_005",
	"NAV_006", "NAV_007", "NAV_008", "NAV_009",
]


static func get_mission(mission_id: String) -> Dictionary:
	return MISSIONS.get(mission_id, {})


static func mission_ids() -> Array:
	return MISSION_ORDER.duplicate()


static func event_label(event_name: String) -> String:
	return EVENT_LABELS.get(event_name, event_name.replace("_", " ").capitalize())


static func milestone_label(milestone_name: String) -> String:
	if MILESTONES.has(milestone_name):
		return MILESTONES[milestone_name]
	return event_label(milestone_name)


static func crew_for(character_id: String) -> Dictionary:
	for member: Dictionary in CREW_ROSTER:
		if member["id"] == character_id:
			return member
	return {}