class_name DataSource
extends RefCounted

## PARALLAX — provenance record for a dataset. Every dataset declares where it
## came from, its reference frame, epoch, units and whether it has been verified
## against the live source, so real astronomical data is never confused with
## fabricated or simulated values.

const KIND_REAL: String = "REAL_ASTRONOMICAL"
const KIND_SIMULATED: String = "FICTIONAL_SIMULATION"

var dataset: String = ""
var kind: String = KIND_REAL
var source: String = ""
var source_url: String = ""
var reference_frame: String = ""
var epoch: String = ""
var units: Dictionary = {}
var retrieved: String = ""
var verified: bool = false
var notes: String = ""


static func from_dict(d: Dictionary) -> DataSource:
	var s: DataSource = DataSource.new()
	s.dataset = str(d.get("dataset", ""))
	s.kind = str(d.get("kind", KIND_REAL))
	s.source = str(d.get("source", ""))
	s.source_url = str(d.get("source_url", ""))
	s.reference_frame = str(d.get("reference_frame", ""))
	s.epoch = str(d.get("epoch", ""))
	s.units = d.get("units", {})
	s.retrieved = str(d.get("retrieved", ""))
	s.verified = bool(d.get("verified_against_source", false))
	s.notes = str(d.get("notes", ""))
	return s


func is_real() -> bool:
	return kind == KIND_REAL


func citation() -> String:
	if source_url == "":
		return source
	return "%s" % source


## One-line status shown in the interface so the player knows the data's state.
func status_line() -> String:
	if not is_real():
		return "FICTIONAL SIMULATION DATA"
	if not verified:
		return "REFERENCE VALUES — NOT RE-VERIFIED AGAINST SOURCE"
	return "VERIFIED AGAINST SOURCE"