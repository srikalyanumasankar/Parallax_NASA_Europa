class_name SystemsSimulation
extends Node

## PARALLAX — FICTIONAL spacecraft subsystems model for the SYSTEMS section.
##
## DOCUMENTED, DELIBERATELY SIMPLE MODEL (no claim to be an engineering sim):
##   * Solar array output follows a slow sinusoid (a sun-angle proxy).
##   * The reactor holds a near-steady output with a small ripple.
##   * Thermal regulation lags towards a setpoint raised by reactor load and any
##     manoeuvre burn.
##   * The communications data rate falls with a slow sinusoid (a geometry proxy).
##   * Fuel is spent in proportion to the total |Δv| applied by manoeuvres.
##   * Hull integrity is near-constant; radiation follows a slow ripple.
## Limits live in SystemsDefinitions; non-nominal states raise bus alerts.

signal updated(state: Dictionary)

const BASE_COMMS_MBPS: float = 64.0
const FUEL_PER_MS: float = 0.02          # fictional fuel spent per m/s of Δv
const THERMAL_SETPOINT_K: float = 288.0

var fuel: float = 0.74
var power: float = 0.92
var reactor: float = 1.0
var thermal_k: float = 288.0
var comms_mbps: float = BASE_COMMS_MBPS
var structure: float = 0.99
var radiation_msvh: float = 0.12

var _t: float = 0.0
var _alerted: Dictionary = {}

static var _active: SystemsSimulation = null


static func active() -> SystemsSimulation:
	return _active


func _ready() -> void:
	_active = self
	var sim: OrbitalSimulation = OrbitalSimulation.active()
	if sim != null:
		sim.manoeuvre_applied.connect(_on_manoeuvre)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	power = clampf(0.90 + sin(_t * 0.15) * 0.07, 0.0, 1.0)
	reactor = clampf(0.98 + sin(_t * 0.9) * 0.02, 0.0, 1.0)
	var target: float = THERMAL_SETPOINT_K + (reactor - 0.5) * 8.0 + (1.0 - power) * 12.0
	thermal_k += (target - thermal_k) * clampf(delta * 0.5, 0.0, 1.0)
	comms_mbps = clampf(BASE_COMMS_MBPS * (0.92 + sin(_t * 0.05) * 0.12), 0.0, 100.0)
	radiation_msvh = clampf(0.12 + sin(_t * 0.03) * 0.05, 0.0, 5.0)
	updated.emit(state())
	_check_alerts()


func _on_manoeuvre(report: Dictionary) -> void:
	var dv: float = absf(float(report.get("delta_v_ms", 0.0)))
	fuel = clampf(fuel - dv * FUEL_PER_MS, 0.0, 1.0)
	thermal_k += dv * 0.35          # a burn briefly heats the spacecraft
	updated.emit(state())


func state() -> Dictionary:
	return {
		"propulsion": fuel,
		"power": power,
		"reactor": reactor,
		"thermal": thermal_k,
		"comms": comms_mbps,
		"structure": structure,
		"radiation": radiation_msvh,
	}


## A 0..1 fill for a subsystem's meter. Thermal and radiation are mapped from
## their own display ranges so the bar is meaningful.
func normalised(id: String) -> float:
	match id:
		"thermal":
			return clampf((thermal_k - 250.0) / 70.0, 0.0, 1.0)
		"radiation":
			return clampf(radiation_msvh / 1.0, 0.0, 1.0)
		"comms":
			return clampf(comms_mbps / 100.0, 0.0, 1.0)
		_:
			return clampf(float(state().get(id, 0.0)), 0.0, 1.0)


func status(id: String) -> String:
	var def: Dictionary = SystemsDefinitions.get_subsystem(id)
	var raw: float = float(state().get(id, 0.0))
	if def.has("warn_below") and raw < float(def["warn_below"]):
		return "LOW"
	if def.has("warn_above") and raw > float(def["warn_above"]):
		return "HIGH"
	return "NOMINAL"


## The documented systems check: report whether every subsystem is in limits.
func verify() -> Dictionary:
	var issues: Array = []
	for def in SystemsDefinitions.SUBSYSTEMS:
		var id: String = str(def["id"])
		var st: String = status(id)
		if st != "NOMINAL":
			issues.append("%s %s" % [str(def.get("name", id)), st])
	return {"ok": issues.is_empty(), "issues": issues}


func _check_alerts() -> void:
	for def in SystemsDefinitions.SUBSYSTEMS:
		var id: String = str(def["id"])
		var st: String = status(id)
		if st != "NOMINAL":
			var key: String = id + ":" + st
			if not _alerted.has(key):
				_alerted[key] = true
				if MissionBus != null:
					MissionBus.alert_raised.emit("WARNING", "%s %s" % [str(def.get("name", id)), st])
		else:
			_alerted.erase(id + ":LOW")
			_alerted.erase(id + ":HIGH")