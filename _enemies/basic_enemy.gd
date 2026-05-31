extends Enemy

var speed := 60


func _process(delta):
	if GameManager.is_game_over:
		speed = 0
	super._process(delta)
	position.y += speed * delta


func die():
	speed = 0
	super.spawn_explosion(2)
	super.die()
