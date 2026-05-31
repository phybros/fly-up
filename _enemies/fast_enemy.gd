extends Enemy

@export var frequency: float = 1.0
@export var amplitude: float = 20.0
@export var speed = 85

var start_position: Vector2
var time: float = 0.0


func _ready():
	start_position = position
	super._ready()


func _process(delta):
	time += delta

	if GameManager.is_game_over:
		frequency = 0
		amplitude = 0

	super._process(delta)

	var x_offset = amplitude * sin(2.0 * PI * frequency * time)

	position.y += speed * delta
	position.x = start_position.x + x_offset


func die():
	spawn_explosion(2)
	super.die()
