extends RigidBody2D

const NUMBER_OF_PIECES = 6

func _ready():
	randomize()

	if randi() % 2:
		$Sprite.texture = preload("res://assets/black.png")
	
	$Sprite.frame = randi() % NUMBER_OF_PIECES
	
	var torque_direction = [1, -1][randi() % 2]
	var torque = randf_range(1, 2) * 100
	
	apply_torque(torque * torque_direction)

func delete_if_not_visible():
	if position.y > 300:
		queue_free()
