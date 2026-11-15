class_name TimeFrames
extends RefCounted

## PARALLAX — time and coordinate-frame handling.
##
## Keeps reference frames explicit so incompatible frames are never mixed, and
## provides Julian-date conversions used to stamp observations.

enum Frame {
	ECLIPTIC_J2000,       ## Heliocentric ecliptic, J2000.0 — the standard planetary frame.
	JUPITER_EQUATORIAL,   ## IAU Jupiter equatorial frame — used for the moon data here.
	JUPITER_ORBITAL,      ## Jupiter's own orbital plane.
}

const JD_J2000: float = 2451545.0
const JD_UNIX_EPOCH: float = 2440587.5
const SECONDS_PER_DAY: float = 86400.0


static func frame_name(frame: int) -> String:
	match frame:
		Frame.ECLIPTIC_J2000:
			return "ECLIPTIC J2000"
		Frame.JUPITER_EQUATORIAL:
			return "JUPITER EQUATORIAL"
		Frame.JUPITER_ORBITAL:
			return "JUPITER ORBITAL"
		_:
			return "UNKNOWN FRAME"


static func unix_to_jd(unix_seconds: float) -> float:
	return unix_seconds / SECONDS_PER_DAY + JD_UNIX_EPOCH


static func jd_to_unix(jd: float) -> float:
	return (jd - JD_UNIX_EPOCH) * SECONDS_PER_DAY


static func days_since_j2000(jd: float) -> float:
	return jd - JD_J2000


## Parse an ISO-8601 UTC datetime ("2000-01-01T12:00:00") to a Julian date.
static func iso_to_jd(iso: String) -> float:
	var unix: float = float(Time.get_unix_time_from_datetime_string(iso))
	return unix_to_jd(unix)


static func jd_to_iso(jd: float) -> String:
	var unix: int = int(round(jd_to_unix(jd)))
	return Time.get_datetime_string_from_unix_time(unix, true)