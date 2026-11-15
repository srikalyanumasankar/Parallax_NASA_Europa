extends Node

## PARALLAX — Phase 3 data-foundation tests (data_foundation_tests.gd).
##
## Verifies the real NASA/JPL data registry loads and validates, that units and
## provenance are present, that time conversions are correct, that missing data
## yields an explicit unavailable state, and that real data is kept strictly
## separate from the fictional simulation and schematic geometry.

func test_datasets_load_without_errors() -> void:
	var d: CelestialData = _fresh_data()
	_ok(d.loaded, "registry reports loaded")
	_ok(not d.has_errors(), "no dataset errors (got: %s)" % str(d.errors))
	_cleanup(d)


func test_expected_bodies_present() -> void:
	var d: CelestialData = _fresh_data()
	for id in ["JUPITER", "EUROPA", "IO", "GANYMEDE", "CALLISTO"]:
		_ok(d.is_available(str(id)), "real dataset contains %s" % id)
	_cleanup(d)


func test_bodies_have_required_fields_and_provenance() -> void:
	var d: CelestialData = _fresh_data()
	for id in d.ids():
		var b: Dictionary = d.get_body(str(id))
		for field in CelestialData.REQUIRED_FIELDS:
			_ok(b.has(field), "%s has field '%s'" % [id, field])
		var src: DataSource = d.source_for(str(id))
		_ok(src != null and src.is_real(), "%s carries real provenance" % id)
		if src != null:
			_ok(src.source != "" and src.reference_frame != "" and src.epoch != "", "%s provenance names source/frame/epoch" % id)
			_ok(src.units.has("radius") and src.units.has("mass"), "%s declares units" % id)
	_cleanup(d)


func test_reference_values_are_plausible() -> void:
	var d: CelestialData = _fresh_data()
	var europa: Dictionary = d.get_body("EUROPA")
	_ok(absf(float(europa.get("radius_mean_km", 0.0)) - 1560.8) < 5.0, "Europa radius ≈ 1560.8 km")
	_ok(absf(float(europa.get("orbital_period_days", 0.0)) - 3.551181) < 0.01, "Europa orbital period ≈ 3.551 d")
	_ok(absf(float(europa.get("semi_major_axis_km", 0.0)) - 670900.0) < 100.0, "Europa semi-major axis ≈ 670,900 km")
	var jupiter: Dictionary = d.get_body("JUPITER")
	_ok(absf(float(jupiter.get("radius_equatorial_km", 0.0)) - 71492.0) < 1.0, "Jupiter equatorial radius = 71,492 km")
	_cleanup(d)


func test_missing_body_is_explicitly_unavailable() -> void:
	var d: CelestialData = _fresh_data()
	_ok(not d.is_available("PLUTO"), "unknown body reports unavailable")
	_ok(d.get_body("PLUTO").is_empty(), "unknown body returns an empty record (no fabricated values)")
	_cleanup(d)


func test_time_frames_conversions() -> void:
	_ok(absf(TimeFrames.days_since_j2000(TimeFrames.JD_J2000)) < 0.0001, "J2000 epoch is zero days from J2000")
	_ok(absf(TimeFrames.unix_to_jd(0.0) - 2440587.5) < 0.0001, "Unix epoch maps to JD 2440587.5")
	var jd: float = TimeFrames.unix_to_jd(1700000000.0)
	_ok(absf(TimeFrames.jd_to_unix(jd) - 1700000000.0) < 1.0, "jd ↔ unix round-trips")
	_ok(absf(TimeFrames.iso_to_jd("2000-01-01T12:00:00") - 2451545.0) < 0.001, "2000-01-01T12:00:00 UTC is JD 2451545.0")


func test_real_and_simulated_data_are_separate() -> void:
	var d: CelestialData = _fresh_data()
	_ok(d.is_real(), "CelestialData is the real-data registry")
	_ok(SimulatedMissionData.IS_SIMULATED, "SimulatedMissionData is marked simulated")
	_ok(OrbitalSchematic.IS_FICTIONAL, "OrbitalSchematic is marked fictional")
	_ok(not d.is_available("AETHER"), "the fictional spacecraft is NOT in the real registry")
	_ok(absf(SimulatedMissionData.REFERENCE_ORBIT_ALTITUDE_KM - 100.0) < 0.001, "fictional reference orbit altitude is 100 km")
	_cleanup(d)


func test_source_status_reports_unverified() -> void:
	var d: CelestialData = _fresh_data()
	var src: DataSource = d.source_for("EUROPA")
	_ok(src != null and not src.verified, "seeded data honestly reports it is not re-verified against source")
	if src != null:
		_ok(src.status_line().contains("REFERENCE") or src.status_line().contains("VERIFIED"), "status line is meaningful: %s" % src.status_line())
	_cleanup(d)


# --------------------------------------------------------------------------- #

func _fresh_data() -> CelestialData:
	var d: CelestialData = CelestialData.new()
	d.load_all()
	return d


func _cleanup(_d: CelestialData) -> void:
	pass


func _ok(condition: bool, message: String) -> void:
	print(("PASS  | " if condition else "FAIL  | ") + message)
	assert(condition, message)