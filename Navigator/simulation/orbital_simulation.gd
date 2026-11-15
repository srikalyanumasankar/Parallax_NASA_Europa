class_name OrbitalSimulation
extends Node

## PARALLAX — the spacecraft flight simulation model.
##
## DOCUMENTED, DELIBERATELY SIMPLIFIED KINEMATIC MODEL
## ---------------------------------------------------------------------------
## The fictional PARALLAX spacecraft is treated as flying a CIRCULAR orbit
## around Europa at a constant angular rate. Assumptions, stated openly:
##   * Circular orbit only — no eccentricity, no perturbations, no third bodies.
##   * Europa's position is treated as fixed; its orbital motion is not modelled.
##   * The orbit plane is fixed; the craft does not precess.
##   * Manoeuvres are idealised impulses and the orbit is re-circularised
##     instantly (documented simplification), so a burn changes the orbit radius.
## Real inputs used: Europa's mean radius and Europa's gravitational parameter
## come from the REAL data registry (CelestialData / NASA-JPL reference values).
## The ~100 km operating altitude and the spacecraft herself are FICTIONAL
## (SimulatedMissionData). No value here is claimed to be a NASA-verified
## mission parameter.

signal ticked
signal telemetry_updated(snapshot: Dictionary)
signal manoeuvre_applied(report: Dictionary)

## Europa's gravitational parameter (real, km^3/s^2) — NASA/JPL reference value.
const EUROPA_GM_KM3_S2: float = 3202.7
const HISTORY_MAX: int = 120
const SAMPLE_INTERVAL_S: float = 0.15

var time_scale: float = 1.0
var sim_elapsed_s: float = 0.0

var body_radius_km: float = 1560.8
var orbit_radius_km: float = 1660.8
var inclination_deg: float = 1.2        # fictional simulation parameter
var europa_semi_major_km: float = 670900.0

var _gm: float = EUROPA_GM_KM3_S2
var _v_circ_kms: float = 0.0
var _omega: float = 0.0
var _period_s: float = 0.0
var _angle: float = 0.0
var _position: Vector3 = Vector3.ZERO   # local Europa-centred frame, km
var _velocity: Vector3 = Vector3.ZERO   # km/s
var _pitch_deg: float = 0.0
var _yaw_deg: float = 0.0
var _roll_deg: float = 0.0
var _nav_accuracy: float = 99.4

var _history: Dictionary = {}
var _sample_accum: float = 0.0

static var _active: OrbitalSimulation = null

static func active() -> OrbitalSimulation:
	return _active


func _ready() -> void:
	_active = self
	setup()
	set_process(true)


func setup() -> void:
	var europa: Dictionary = CelestialData.instance().get_body("EUROPA")
	body_radius_km = float(europa.get("radius_mean_km", 1560.8))
	europa_semi_major_km = float(europa.get("semi_major_axis_km", 670900.0))
	orbit_radius_km = body_radius_km + SimulatedMissionData.REFERENCE_ORBIT_ALTITUDE_KM
	_recompute_orbit()
	_recompute_kinematics()


func _process(delta: float) -> void:
	if time_scale <= 0.0:
		return
	var dt: float = delta * time_scale
	step(dt)
	ticked.emit()
	telemetry_updated.emit(telemetry())
	_sample_accum += delta
	if _sample_accum >= SAMPLE_INTERVAL_S:
		_sample_accum = 0.0
		_sample_history()


## Advance the model by dt simulated seconds. Public so tests can drive it.
func step(dt: float) -> void:
	sim_elapsed_s += dt
	_angle = fposmod(_angle + _omega * dt, TAU)
	_recompute_kinematics()
	_nav_accuracy = 99.4 + sin(_angle * 3.0) * 0.3


func set_time_scale(scale: float) -> void:
	time_scale = maxf(0.0, scale)


func mission_elapsed_days() -> float:
	return SharedMissionState.DEFAULT_MET_DAYS + sim_elapsed_s / TimeFrames.SECONDS_PER_DAY


## Apply an idealised prograde/retrograde impulse (m/s). Returns a report.
## The post-burn speed is mapped to a new orbit via the vis-viva relation
## (1/a = 2/r − v²/μ), and the orbit is then assumed circular at that semi-major
## axis — a documented simplification of a real two-burn manoeuvre.
func apply_manoeuvre(delta_v_ms: float) -> Dictionary:
	var dv_kms: float = delta_v_ms / 1000.0
	var v_new: float = maxf(0.05, _v_circ_kms + dv_kms)
	var inv_a: float = 2.0 / orbit_radius_km - (v_new * v_new) / _gm
	var r_new: float = orbit_radius_km
	if inv_a > 1.0e-9:
		r_new = 1.0 / inv_a
	var alt_new: float = r_new - body_radius_km
	if alt_new < 5.0:
		alt_new = 5.0
		r_new = body_radius_km + alt_new
	orbit_radius_km = r_new
	_recompute_orbit()
	_recompute_kinematics()
	var report: Dictionary = {
		"delta_v_ms": delta_v_ms,
		"altitude_km": orbit_radius_km - body_radius_km,
		"speed_kms": _v_circ_kms,
		"period_s": _period_s,
	}
	manoeuvre_applied.emit(report)
	return report


func telemetry() -> Dictionary:
	var r_m: float = orbit_radius_km * 1000.0
	var v_ms: float = _v_circ_kms * 1000.0
	return {
		"elapsed_s": sim_elapsed_s,
		"mission_days": mission_elapsed_days(),
		"altitude_km": orbit_radius_km - body_radius_km,
		"orbit_radius_km": orbit_radius_km,
		"speed_kms": _v_circ_kms,
		"accel_ms2": (v_ms * v_ms) / r_m,
		"period_s": _period_s,
		"distance_europa_km": orbit_radius_km,
		"distance_jupiter_km": europa_semi_major_km,
		"inclination_deg": inclination_deg,
		"pitch_deg": _pitch_deg,
		"yaw_deg": _yaw_deg,
		"roll_deg": _roll_deg,
		"nav_accuracy": _nav_accuracy,
		"position": _position,
		"velocity": _velocity,
		"time_scale": time_scale,
	}


func channel(channel_name: String) -> PackedFloat32Array:
	var arr: PackedFloat32Array = _history.get(channel_name, PackedFloat32Array())
	return arr


func _recompute_orbit() -> void:
	_v_circ_kms = sqrt(_gm / orbit_radius_km)
	_omega = _v_circ_kms / orbit_radius_km
	_period_s = TAU / _omega


func _recompute_kinematics() -> void:
	var ca: float = cos(_angle)
	var sa: float = sin(_angle)
	_position = Vector3(ca, sa, 0.0) * orbit_radius_km
	_velocity = Vector3(-sa, ca, 0.0) * _v_circ_kms
	# Kinematic attitude: the craft flies nose-forward with small oscillations.
	_yaw_deg = fposmod(rad_to_deg(_angle) + 90.0, 360.0)
	_pitch_deg = sin(_angle * 2.0) * 0.8
	_roll_deg = cos(_angle) * 0.5


func _sample_history() -> void:
	var snap: Dictionary = telemetry()
	_push("speed", float(snap["speed_kms"]))
	_push("altitude", float(snap["altitude_km"]))
	_push("accel", float(snap["accel_ms2"]))
	_push("accuracy", float(snap["nav_accuracy"]))


func _push(chan: String, value: float) -> void:
	var arr: PackedFloat32Array = _history.get(chan, PackedFloat32Array())
	arr.append(value)
	if arr.size() > HISTORY_MAX:
		arr = arr.slice(arr.size() - HISTORY_MAX)
	_history[chan] = arr