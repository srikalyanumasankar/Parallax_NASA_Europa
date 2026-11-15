class_name CommunicationManager
extends RefCounted

## PARALLAX — mission-control and crew communication.
##
## Composes readable mission-control messages, crew reports and directives from
## the shared event vocabulary, records them in SharedMissionState (persisted),
## and derives the orbital↔surface link and Earth-link status. It holds no state
## of its own; the shared state remains the single source of truth.

const SOURCE_LABELS: Dictionary = {
	"MISSION_CONTROL": "MISSION CONTROL",
	"SRI_KALYAN": "SRI KALYAN · NAVIGATOR",
	"VARUN": "VARUN · COMMS",
	"MANIC": "MANIC · BASE OPS",
	"KRISH": "KRISH · KANDAM",
	"DHANUSH": "DHANUSH · KADAL",
	"AMRISH": "AMRISH · LAB",
	"EXTERNAL": "EXTERNAL SOURCE",
	"DEV_TEST": "DEVELOPMENT TEST",
}

## One-way light time reference for a Europa–Earth link is tens of minutes; it is
## shown as a labelled reference range, not a measured value (no geometry here).
const EARTH_LIGHT_TIME_REFERENCE: String = "REFERENCE 35–52 min one-way (NASA/JPL)"


static func source_label(source: String) -> String:
	return SOURCE_LABELS.get(source, source)


static func compose(event_name: String, source: String = "MISSION_CONTROL") -> Dictionary:
	var label: String = MissionDefinitions.event_label(event_name)
	var from: String = source_label(source)
	var subject: String = ""
	var body: String = ""
	match source:
		"MISSION_CONTROL":
			subject = "MISSION CONTROL DIRECTIVE"
			body = "%s — %s. Logged to the shared mission database." % [from, label]
		"SRI_KALYAN":
			subject = "NAVIGATOR LOG"
			body = "Navigation event recorded: %s." % label
		"EXTERNAL", "DEV_TEST":
			subject = "SYSTEM EVENT"
			body = "Received: %s." % label
		_:
			subject = "CREW REPORT"
			body = "%s reports: %s." % [from, label]
	return {
		"id": "EVT_" + event_name,
		"source": source,
		"subject": subject,
		"body": body,
		"kind": "EVENT",
		"event": event_name,
	}


static func compose_directive(mission_id: String) -> Dictionary:
	var title: String = str(MissionDefinitions.get_mission(mission_id).get("title", mission_id))
	return {
		"id": "DIRECTIVE_" + mission_id,
		"source": "MISSION_CONTROL",
		"subject": "MISSION AVAILABLE",
		"body": "Mission control has released a new objective: %s (%s)." % [title, mission_id],
		"kind": "DIRECTIVE",
		"event": "",
	}


## Log a communication for a shared event. Idempotent per event.
static func record_event(state: SharedMissionState, event_name: String, source: String = "MISSION_CONTROL") -> bool:
	if state == null:
		return false
	return state.log_message(compose(event_name, source))


static func record_directive(state: SharedMissionState, mission_id: String) -> bool:
	if state == null:
		return false
	return state.log_message(compose_directive(mission_id))


## Subscribe a live state to the bus so shared events and unlocks auto-log.
## Call once per navigator session.
static func attach(state: SharedMissionState, bus: Node) -> void:
	if state == null or bus == null:
		return
	bus.event_published.connect(func(name: String, source: String) -> void:
		record_event(state, name, source))
	bus.mission_unlocked.connect(func(mission_id: String) -> void:
		record_directive(state, mission_id))


## Orbital ↔ surface link status, derived from shared events.
static func surface_link_status(state: SharedMissionState) -> Dictionary:
	if state == null:
		return {"state": "UNKNOWN", "colour": ParallaxPalette.TEXT_DIM, "detail": ""}
	if not state.has_event("SURFACE_CONTACT_CONFIRMED"):
		return {"state": "NO SURFACE LINK", "colour": ParallaxPalette.TEXT_FAINT, "detail": "Pre-landing — the lander has not confirmed surface contact."}
	if not state.has_event("VARUN_SURFACE_COMMUNICATION_ESTABLISHED"):
		return {"state": "LINK PENDING", "colour": ParallaxPalette.AMBER, "detail": "Surface contact confirmed; awaiting Varun's surface communication link."}
	return {"state": "ORBITAL · SURFACE LINK ACTIVE", "colour": ParallaxPalette.GREEN, "detail": "Two-way relay established between the orbital spacecraft and the surface team."}


## Earth / deep-space network link status.
static func earth_link_status(state: SharedMissionState) -> Dictionary:
	if state == null:
		return {"state": "UNKNOWN", "colour": ParallaxPalette.TEXT_DIM, "detail": ""}
	if state.has_event("EARTH_COMMUNICATION_VERIFIED"):
		return {"state": "DEEP SPACE NET · VERIFIED", "colour": ParallaxPalette.GREEN, "detail": EARTH_LIGHT_TIME_REFERENCE}
	if state.has_event("COMMUNICATIONS_AVAILABLE"):
		return {"state": "DEEP SPACE NET · AVAILABLE", "colour": ParallaxPalette.CYAN, "detail": EARTH_LIGHT_TIME_REFERENCE}
	return {"state": "DEEP SPACE NET · STANDBY", "colour": ParallaxPalette.TEXT_DIM, "detail": "Awaiting communications readiness."}