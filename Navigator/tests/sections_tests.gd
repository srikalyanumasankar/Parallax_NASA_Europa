extends Node

## PARALLAX — TELEMETRY & SYSTEMS section tests: the fictional subsystems model,
## its alert behaviour, the objective-mapping helpers (never bypassing gated
## manoeuvre objectives) and the graph component.

func _free(node: Node) -> void:
	if is_instance_valid(node):
		node.free()


func _make_sims() -> Array:
	var orbital: OrbitalSimulation = OrbitalSimulation.new()
	add_child(orbital)
	var systems: SystemsSimulation = SystemsSimulation.new()
	add_child(systems)
	return [orbital, systems]


# --- Subsystems model --------------------------------------------------------

func test_systems_defaults_are_nominal() -> void:
	var pair: Array = _make_sims()
	var systems: SystemsSimulation = pair[1]
	for id in SystemsDefinitions.ids():
		assert(systems.status(str(id)) == "NOMINAL", "%s should start nominal" % id)
	var res: Dictionary = systems.verify()
	assert(bool(res.get("ok", false)), "a fresh spacecraft should pass verification")
	assert((res.get("issues", []) as Array).is_empty(), "a fresh spacecraft should report no issues")
	_free(pair[0])
	_free(pair[1])


func test_manoeuvre_consumes_fuel() -> void:
	var pair: Array = _make_sims()
	var orbital: OrbitalSimulation = pair[0]
	var systems: SystemsSimulation = pair[1]
	var before: float = systems.fuel
	orbital.apply_manoeuvre(10.0)
	assert(systems.fuel < before, "a burn should consume fuel (before %.3f, after %.3f)" % [before, systems.fuel])
	assert(is_equal_approx(systems.fuel, before - 10.0 * SystemsSimulation.FUEL_PER_MS), "fuel should drop by Δv × FUEL_PER_MS")
	_free(pair[0])
	_free(pair[1])


func test_low_fuel_is_low_and_fails_verification() -> void:
	var pair: Array = _make_sims()
	var systems: SystemsSimulation = pair[1]
	systems.fuel = 0.05
	assert(systems.status("propulsion") == "LOW", "5% fuel should read LOW")
	var res: Dictionary = systems.verify()
	assert(not bool(res.get("ok", false)), "verification should fail with fuel low")
	var issues: Array = res.get("issues", [])
	assert(not issues.is_empty() and str(issues[0]).contains("PROPULSION"), "the issue should name PROPULSION")
	_free(pair[0])
	_free(pair[1])


func test_thermal_high_status() -> void:
	var pair: Array = _make_sims()
	var systems: SystemsSimulation = pair[1]
	systems.thermal_k = 320.0
	assert(systems.status("thermal") == "HIGH", "320 K should read HIGH")
	systems.thermal_k = 288.0
	assert(systems.status("thermal") == "NOMINAL", "288 K should be nominal")
	_free(pair[0])
	_free(pair[1])


func test_alerts_emitted_once_per_state() -> void:
	var pair: Array = _make_sims()
	var systems: SystemsSimulation = pair[1]
	systems.fuel = 0.05
	var seen: Array = []
	var cb: Callable = func(_level: String, text: String) -> void:
		seen.append(text)
	MissionBus.alert_raised.connect(cb)
	systems._check_alerts()
	systems._check_alerts()
	MissionBus.alert_raised.disconnect(cb)
	assert(seen.size() == 1, "a non-nominal subsystem should alert once, got %d" % seen.size())
	assert(str(seen[0]).contains("PROPULSION"), "the alert should name the subsystem")
	_free(pair[0])
	_free(pair[1])


# --- Section objective mapping ----------------------------------------------

func test_applicable_excludes_gated_objectives() -> void:
	var list: Array = SectionObjectives.applicable("NAV_001", SectionObjectives.TELEMETRY)
	assert(not list.has("Verify navigation data"), "the gated manoeuvre objective must NOT be offered")
	assert(list.has("Inspect spacecraft position and velocity"), "the observation objective should be offered")


func test_applicable_for_systems_mission() -> void:
	var list: Array = SectionObjectives.applicable("NAV_003", SectionObjectives.SYSTEMS)
	assert(list.has("Inspect spacecraft health"), "NAV_003 health objective should be offered")
	assert(list.has("Check power and thermal systems"), "NAV_003 power/thermal objective should be offered")


func test_applicable_empty_without_mission() -> void:
	assert(SectionObjectives.applicable("", SectionObjectives.SYSTEMS).is_empty(), "no mission means no objectives")
	assert(SectionObjectives.applicable("NAV_003", ["Not A Real Objective"]).is_empty(), "unknown objectives are ignored")


func test_record_completes_objective() -> void:
	var prev_auto: bool = MissionState.auto_save
	MissionState.auto_save = false
	MissionState.reset_progress()
	MissionState.active_mission = "NAV_003"
	var recorded: Array = SectionObjectives.record(SectionObjectives.SYSTEMS)
	assert(recorded.size() > 0, "the systems check should record at least one objective")
	assert(MissionState.is_objective_done("NAV_003", str(recorded[0])), "the recorded objective should be marked done")
	# A second run records nothing new.
	assert(SectionObjectives.record(SectionObjectives.SYSTEMS).is_empty(), "repeat checks should not re-record")
	MissionState.reset_progress()
	MissionState.auto_save = prev_auto


# --- Components / panels -----------------------------------------------------

func test_telemetry_graph_stores_values() -> void:
	var g: TelemetryGraph = TelemetryGraph.new("ORBITAL VELOCITY", "km/s")
	add_child(g)
	g.set_values(PackedFloat32Array([1.0, 2.0, 3.0]))
	assert(g.values.size() == 3, "the graph should store the samples")
	assert(is_equal_approx(g.current_value(), 3.0), "current_value should be the latest sample")
	_free(g)


func test_panels_build() -> void:
	var pair: Array = _make_sims()
	var telemetry: TelemetryPanel = TelemetryPanel.new()
	add_child(telemetry)
	var systems_panel: SystemsPanel = SystemsPanel.new()
	add_child(systems_panel)
	assert(telemetry.get_child_count() > 0, "the telemetry panel should build content")
	assert(systems_panel.get_child_count() > 0, "the systems panel should build content")
	_free(telemetry)
	_free(systems_panel)
	_free(pair[0])
	_free(pair[1])