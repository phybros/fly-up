extends Camera2D

var _strength: float = 30
var _fade: float = 1

var rng = RandomNumberGenerator.new()
var _shake_strength: float = 0


func apply_shake(strength: float, fade: float):
	_strength = strength
	_fade = fade
	_shake_strength = strength


# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.connect("camera_shake", apply_shake)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _shake_strength > 0:
		_shake_strength = lerpf(_shake_strength, 0, _fade * delta)

		offset = randomOffset()


func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-_shake_strength, _shake_strength), rng.randf_range(-_shake_strength, _shake_strength))
