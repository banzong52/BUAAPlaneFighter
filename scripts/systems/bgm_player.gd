# BGMPlayer.gd — 程序化BGM播放器
extends Node

var _player: AudioStreamPlayer = null
var _playback = null
var _title_notes: Array = [60,64,67,72,71,67,64,60,62,65,69,74,72,69,65,62]
var _game_notes: Array = [60,63,67,70,72,75,79,72,70,67,63,60, 62,65,69,72,74,77,81,77,74,72,69,65]
var _note_duration: float = 0.18
var _note_timer: float = 0.0
var _note_idx: int = 0
var _playing: bool = false
var _notes: Array = []
var _phase: float = 0.0
var _sample_rate: float = 44100.0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	var gen: AudioStreamGenerator = AudioStreamGenerator.new()
	gen.mix_rate = _sample_rate
	gen.buffer_length = 0.05
	_player.stream = gen
	_player.volume_db = -14.0


func play_title() -> void:
	_notes = _title_notes
	_start()


func play_game() -> void:
	_notes = _game_notes
	_start()


func _start() -> void:
	_playing = true
	_note_idx = 0
	_note_timer = 0.0
	_phase = 0.0
	if not _player.playing:
		_player.play()
		_playback = _player.get_stream_playback()


func stop() -> void:
	_playing = false
	_player.stop()
	_playback = null


func _process(_d: float) -> void:
	if not _playing:
		return
	if _playback == null:
		_playback = _player.get_stream_playback()
		if _playback == null:
			return
	_fill_buffer()


func _fill_buffer() -> void:
	var to_fill: int = _playback.get_frames_available()
	if to_fill <= 0:
		return

	for i in range(to_fill):
		_note_timer -= 1.0 / _sample_rate
		if _note_timer <= 0:
			_note_timer = _note_duration
			_note_idx = (_note_idx + 1) % _notes.size()

		var midi: int = _notes[_note_idx]
		var freq: float = 440.0 * pow(2.0, (midi - 69.0) / 12.0)
		var step: float = freq / _sample_rate

		# Square-ish wave with harmonics
		var v: float = 0.0
		var t: float = _phase * TAU
		v += sin(t) * 0.12
		v += sin(t * 2.0) * 0.04
		v += sin(t * 0.5) * 0.06

		# Note envelope
		var note_pos: float = 1.0 - (_note_timer / _note_duration)
		var env: float = 1.0
		if note_pos < 0.05:
			env = note_pos / 0.05
		elif note_pos > 0.8:
			env = (1.0 - note_pos) / 0.2
		v *= env

		_playback.push_frame(Vector2(v, v))
		_phase += step
		if _phase >= 1.0:
			_phase -= 1.0
