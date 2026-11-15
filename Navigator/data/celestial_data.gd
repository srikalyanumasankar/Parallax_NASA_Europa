class_name CelestialData
extends RefCounted

## PARALLAX — real astronomical data registry (NASA/JPL).
##
## Loads, validates and caches the real-data datasets. Everything here is REAL
## astronomical data with explicit provenance; the fictional spacecraft
## simulation and the schematic map geometry live elsewhere
## (SimulatedMissionData, OrbitalSchematic). This keeps the two categories
## strictly separate so simulated values are never presented as real.
##
## Retrieval stays separate from the interface: panels ask this registry, not
## the filesystem.

const DATASET_DIR: String = "res://PARALLAX/Navigator/data/datasets"
const DATASET_FILES: Array = [
	"jupiter_data.json",
	"europa_data.json",
	"galilean_moons_data.json",
]

const REQUIRED_FIELDS: Array = ["id", "name", "type"]

var bodies: Dictionary = {}     # id -> body Dictionary (with "_source": DataSource)
var errors: Array = []
var warnings: Array = []
var loaded: bool = false

static var _instance: CelestialData = null


## Shared, lazily-loaded registry instance.
static func instance() -> CelestialData:
	if _instance == null:
		_instance = CelestialData.new()
		_instance.load_all()
	return _instance


func load_all() -> void:
	bodies.clear()
	errors.clear()
	warnings.clear()
	for file_name in DATASET_FILES:
		_load_file("%s/%s" % [DATASET_DIR, file_name])
	loaded = true


func _load_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		errors.append("Missing dataset file: %s" % path)
		return
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		errors.append("Malformed JSON (not a dictionary): %s" % path)
		return
	var data: Dictionary = parsed
	var meta: Dictionary = data.get("_meta", {})
	if meta.is_empty():
		warnings.append("Dataset without _meta provenance: %s" % path)
	var source: DataSource = DataSource.from_dict(meta)
	if not source.is_real():
		errors.append("Non-real data in the real registry: %s" % path)
	var list: Array = data.get("bodies", [])
	if list.is_empty():
		errors.append("No bodies in dataset: %s" % path)
	for entry in list:
		var b: Dictionary = entry
		for field in REQUIRED_FIELDS:
			if not b.has(field):
				errors.append("Body missing '%s' in %s" % [field, path])
		var id: String = str(b.get("id", ""))
		if id == "":
			errors.append("Body without an id in %s" % path)
			continue
		var record: Dictionary = b.duplicate(true)
		record["_source"] = source
		bodies[id] = record


func is_available(body_id: String) -> bool:
	return bodies.has(body_id)


func is_real() -> bool:
	return true


func get_body(body_id: String) -> Dictionary:
	return bodies.get(body_id, {})


func source_for(body_id: String) -> DataSource:
	var b: Dictionary = bodies.get(body_id, {})
	if b.has("_source"):
		return b["_source"]
	return null


func ids() -> Array:
	return bodies.keys()


func has_errors() -> bool:
	return not errors.is_empty()