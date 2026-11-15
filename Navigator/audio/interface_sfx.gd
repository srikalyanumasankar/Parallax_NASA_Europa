class_name InterfaceSfx
extends RefCounted

## PARALLAX — Phase 9 interface audio.
##
## A single registry of the console's seven interface sounds. The files are
## AI-generated into res://assets/generated/audio/ and played through ZivaSfx,
## which adds a small random pitch variation so repeated clicks do not sound
## machine-identical.
##
## Every call here is silent-safe: if a file is missing, the call plays nothing
## rather than erroring, so the console keeps working while sound files are
## still being produced.

const DIR: String = "res://assets/generated/audio/"

## sound name -> file path. `fan` is a seamless loop (ambience); the rest are
## one-shots.
const SOUNDS: Dictionary = {
	"click": DIR + "ui_click.mp3",
	"confirm": DIR + "ui_confirm.mp3",
	"relay": DIR + "ui_relay.mp3",
	"fan": DIR + "amb_fan.mp3",
	"comm": DIR + "comm_signal.mp3",
	"warning": DIR + "sys_warning.mp3",
	"complete": DIR + "op_complete.mp3",
}

static var _cache: Dictionary = {}


## The cached stream for a sound name, or null when there is no such sound or
## its file is absent.
static func stream_for(sound: String) -> AudioStream:
	if not SOUNDS.has(sound):
		return null
	if not _cache.has(sound):
		var path: String = str(SOUNDS[sound])
		_cache[sound] = load(path) if ResourceLoader.exists(path) else null
	return _cache[sound] as AudioStream


static func has(sound: String) -> bool:
	return stream_for(sound) != null


## All registered sound names, sorted.
static func names() -> Array:
	var out: Array = SOUNDS.keys()
	out.sort()
	return out


## Play a one-shot sound attached to `from`. Returns the transient player, or
## null when the sound or the node is unavailable.
static func play(from: Node, sound: String, volume_db: float = -4.0, pitch_variation: float = 0.08) -> AudioStreamPlayer:
	var stream: AudioStream = stream_for(sound)
	if stream == null or from == null or not is_instance_valid(from) or from.get_tree() == null:
		return null
	# Self-contained one-shot: a transient player with a little random pitch so
	# repeated clicks do not sound machine-identical. (Previously delegated to a
	# ZivaSfx helper that is not part of this project, which broke parsing.)
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	if AudioServer.get_bus_index(&"SFX") != -1:
		player.bus = &"SFX"
	var host: Node = from.get_tree().current_scene
	if host == null:
		host = from.get_tree().root
	host.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return player


## Build a persistent looping player for ambient sound (the cabin fan). The
## caller owns and frees the returned node. Returns null when the file is
## missing.
static func make_loop(sound: String, volume_db: float = -20.0) -> AudioStreamPlayer:
	var stream: AudioStream = stream_for(sound)
	if stream == null:
		return null
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	if AudioServer.get_bus_index(&"SFX") != -1:
		player.bus = &"SFX"
	return player