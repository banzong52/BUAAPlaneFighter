# BGMPlayer.gd — 程序化BGM, 多音轨
extends Node

var _player: AudioStreamPlayer = null
var _playback = null
var _sample_rate: float = 44100.0
var _playing: bool = false

# Per-voice phase
var _ph_m: float = 0.0
var _ph_b: float = 0.0
var _ph_p: float = 0.0

# Title theme
var _title_m: Array = [
	[64,1],[67,1],[71,1],[74,2],[72,1],[71,1],[67,1],[64,2],
	[62,1],[65,1],[69,1],[72,2],[71,1],[69,1],[65,1],[62,2],
]
var _title_b: Array = [[48,4],[52,4],[55,4],[50,4]]

# Combat theme
var _combat_m: Array = [
	[60,1],[63,0.5],[67,0.5],[70,1],[72,0.5],[75,0.5],[79,1],[72,1],[70,0.5],[67,0.5],[63,1],[60,1],
	[62,1],[65,0.5],[69,0.5],[72,1],[74,0.5],[77,0.5],[81,1],[77,1],[74,0.5],[72,0.5],[69,1],[65,1],
	[67,1],[70,1],[72,1],[75,1],[77,1],[79,1],[75,1],[72,1],[70,1],[67,1],[63,1],[60,2],
]
var _combat_b: Array = [[48,4],[55,4],[50,4],[53,4]]

# Boss theme
var _boss_m: Array = [
	[48,0.5],[51,0.5],[54,0.5],[57,0.5],[60,0.5],[63,0.5],[66,0.5],[69,0.5],
	[72,0.5],[69,0.5],[66,0.5],[63,0.5],[60,0.5],[57,0.5],[54,0.5],[51,0.5],
	[50,0.5],[53,0.5],[56,0.5],[59,0.5],[62,0.5],[65,0.5],[68,0.5],[71,0.5],
	[74,0.5],[71,0.5],[68,0.5],[65,0.5],[62,0.5],[59,0.5],[56,0.5],[53,0.5],
	[48,0.25],[52,0.25],[55,0.25],[60,0.25],[63,0.25],[67,0.25],[72,0.25],[75,0.25],[79,1],[77,1],[75,1],[72,1],
]
var _boss_b: Array = [[36,2],[39,2],[42,2],[45,2],[38,2],[41,2],[44,2],[47,2]]

var _mel: Array = []
var _bas: Array = []
var _dur: float = 0.16
var _vol: float = 0.12
var _nt: float = 0.0
var _ni: int = 0
var _bt: float = 0.0
var _bi: int = 0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	var gen: AudioStreamGenerator = AudioStreamGenerator.new()
	gen.mix_rate = _sample_rate
	gen.buffer_length = 0.05
	_player.stream = gen
	_player.volume_db = -14.0


func play_title() -> void:
	_mel = _title_m; _bas = _title_b; _dur = 0.28; _vol = 0.12; _start()


func play_game() -> void:
	_mel = _combat_m; _bas = _combat_b; _dur = 0.16; _vol = 0.13; _start()


func play_boss() -> void:
	_mel = _boss_m; _bas = _boss_b; _dur = 0.12; _vol = 0.15; _start()


func _start() -> void:
	_playing = true
	_ni = 0; _bi = 0
	_nt = 0.0; _bt = 0.0
	_ph_m = 0.0; _ph_b = 0.0; _ph_p = 0.0
	if not _player.playing:
		_player.play()
		_playback = _player.get_stream_playback()


func stop() -> void:
	_playing = false
	_player.stop()
	_playback = null


func _process(_d: float) -> void:
	if not _playing or _playback == null:
		if _player and _player.playing:
			_playback = _player.get_stream_playback()
		return
	_fill()


func _fill() -> void:
	var n: int = _playback.get_frames_available()
	if n <= 0: return
	for _i in range(n):
		var dt: float = 1.0 / _sample_rate
		_nt -= dt
		if _nt <= 0.0 and _mel.size() > 0:
			_nt = _dur * _mel[_ni][1]
			_ni = (_ni + 1) % _mel.size()
		_bt -= dt
		if _bt <= 0.0 and _bas.size() > 0:
			_bt = _dur * 4.0 * _bas[_bi][1]
			_bi = (_bi + 1) % _bas.size()

		var idx_m: int = (_ni - 1 + _mel.size()) % _mel.size() if _mel.size() > 0 else 0
		var idx_b: int = (_bi - 1 + _bas.size()) % _bas.size() if _bas.size() > 0 else 0
		var mi: int = _mel[idx_m][0] if _mel.size() > 0 else 60
		var bi: int = _bas[idx_b][0] if _bas.size() > 0 else 36

		var v: float = _tone(mi, _ph_m)
		_ph_m = fmod(_ph_m + _step(mi), 1.0)
		v += _tone(bi, _ph_b) * 0.45
		_ph_b = fmod(_ph_b + _step(bi), 1.0)
		v += _tone(mi + 7, _ph_p) * 0.12
		_ph_p = fmod(_ph_p + _step(mi + 7), 1.0)

		var mp: float = 1.0 - (_nt / max(_dur * 0.3, 0.01))
		var env: float = 1.0
		if mp < 0.02: env = mp / 0.02
		elif mp > 0.9: env = (1.0 - mp) / 0.1
		v *= env
		v = clamp(v, -0.25, 0.25)
		v = clamp(v, -0.3, 0.3)
		_playback.push_frame(Vector2(v, v))


func _step(midi: int) -> float:
	return (440.0 * pow(2.0, (midi - 69.0) / 12.0)) / _sample_rate


func _tone(_midi: int, ph: float) -> float:
	# 8-bit square wave (pulse at 25% duty)
	var t: float = ph * TAU
	var sq: float = 1.0 if fmod(ph, 1.0) < 0.25 else -1.0
	var v: float = sq * _vol * 0.7
	# Triangle for bass warmth
	v += sin(t) * _vol * 0.25
	# High-frequency sparkle (simulate NES noise channel)
	var nz: float = sin(ph * 31.7) * _vol * 0.04
	nz += sin(ph * 73.1) * _vol * 0.02
	v += nz
	return v
