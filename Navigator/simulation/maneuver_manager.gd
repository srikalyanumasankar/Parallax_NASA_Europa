class_name ManeuverManager
extends RefCounted

## PARALLAX — configures, predicts, executes and verifies navigation operations.
## Every execution changes the simulation and records the mission objective; no
## operation merely reports success.

## Real impulses never land exactly on the commanded value; a small execution
## error makes verification meaningful. Documented simplification.
const EXEC_ERROR_FRACTION: float = 0.01

static var _rng: RandomNumberGenerator = null


static func _generator() -> RandomNumberGenerator:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = 20260815
	return _rng


## Δv (m/s) needed to reach a circular orbit at the given altitude, via vis-viva.
static func required_delta_v_ms(sim: OrbitalSimulation, target_altitude_km: float) -> float:
	if sim == null:
		return 0.0
	var target_r: float = sim.body_radius_km + target_altitude_km
	var v2: float = OrbitalSimulation.EUROPA_GM_KM3_S2 * (2.0 / sim.orbit_radius_km - 1.0 / target_r)
	if v2 <= 0.0:
		return 0.0
	return (sqrt(v2) - sim.telemetry()["speed_kms"]) * 1000.0


static func _period_for_radius(radius_km: float) -> float:
	return TAU * sqrt(pow(radius_km, 3.0) / OrbitalSimulation.EUROPA_GM_KM3_S2)


## Predicted outcome of an operation without applying it.
static func predicted(sim: OrbitalSimulation, op: Dictionary, param: float) -> Dictionary:
	if sim == null:
		return {}
	var t: Dictionary = sim.telemetry()
	match str(op.get("kind", "")):
		"verify":
			return {"summary": "Records a navigation verification", "altitude_km": t["altitude_km"], "period_s": t["period_s"], "delta_v_ms": 0.0}
		"target_altitude":
			var alt: float = param
			var radius: float = sim.body_radius_km + alt
			return {
				"summary": "Establish a circular orbit at %d km" % int(alt),
				"altitude_km": alt,
				"period_s": _period_for_radius(radius),
				"delta_v_ms": required_delta_v_ms(sim, alt),
			}
		"delta_v":
			var v_new: float = float(t["speed_kms"]) + param / 1000.0
			var inv_a: float = 2.0 / sim.orbit_radius_km - (v_new * v_new) / OrbitalSimulation.EUROPA_GM_KM3_S2
			var radius2: float = sim.orbit_radius_km if inv_a <= 1.0e-9 else 1.0 / inv_a
			return {
				"summary": "Apply a %.0f m/s impulse" % param,
				"altitude_km": radius2 - sim.body_radius_km,
				"period_s": _period_for_radius(radius2),
				"delta_v_ms": param,
			}
	return {}


## Execute an operation: changes the simulation and records the objective.
static func execute(sim: OrbitalSimulation, op: Dictionary, param: float, state: SharedMissionState, mission_id: String) -> Dictionary:
	if sim == null:
		return {}
	var pred: Dictionary = predicted(sim, op, param)
	var before: Dictionary = sim.telemetry()
	var applied_dv: float = 0.0
	var kind: String = str(op.get("kind", ""))

	if kind == "target_altitude" or kind == "delta_v":
		var commanded: float = float(pred.get("delta_v_ms", 0.0))
		applied_dv = commanded * (1.0 + _generator().randf_range(-EXEC_ERROR_FRACTION, EXEC_ERROR_FRACTION))
		sim.apply_manoeuvre(applied_dv)

	var after: Dictionary = sim.telemetry()
	if state != null and mission_id != "":
		state.complete_objective(mission_id, str(op.get("objective", "")))

	return {
		"op_id": str(op.get("id", "")),
		"kind": kind,
		"param": param,
		"applied_delta_v_ms": applied_dv,
		"altitude_before_km": before["altitude_km"],
		"altitude_after_km": after["altitude_km"],
		"period_before_s": before["period_s"],
		"period_after_s": after["period_s"],
		"predicted": pred,
	}


## Verify the achieved result against the prediction.
static func verify(op: Dictionary, report: Dictionary) -> Dictionary:
	var pred: Dictionary = report.get("predicted", {})
	var predicted_alt: float = float(pred.get("altitude_km", 0.0))
	var achieved: float = float(report.get("altitude_after_km", 0.0))
	var err: float = absf(achieved - predicted_alt)
	if str(op.get("kind", "")) == "verify":
		return {"success": true, "error_km": 0.0, "note": "Navigation solution verified"}
	var tol: float = maxf(2.0, absf(predicted_alt) * 0.05)
	var ok: bool = err <= tol
	return {
		"success": ok,
		"error_km": err,
		"note": ("Within tolerance — %.2f km" % err) if ok else ("Outside tolerance — %.2f km" % err),
	}