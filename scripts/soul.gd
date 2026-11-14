extends Area2D

@export var box_rect := Rect2(-160, -100, 320, 200)
@export var max_speed := 220.0
@export var accel := 900.0
@export var bounciness := 0.85   # 1.0 = perfectly bouncy, 0 = stops dead
@export var radius := 8.0

var velocity := Vector2.ZERO

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = velocity.move_toward(input * max_speed, accel * delta)
	position += velocity * delta

	var bounds := box_rect.grow(-radius)

	if position.x < bounds.position.x:
		position.x = bounds.position.x
		velocity.x = absf(velocity.x) * bounciness
	elif position.x > bounds.end.x:
		position.x = bounds.end.x
		velocity.x = -absf(velocity.x) * bounciness

	if position.y < bounds.position.y:
		position.y = bounds.position.y
		velocity.y = absf(velocity.y) * bounciness
	elif position.y > bounds.end.y:
		position.y = bounds.end.y
		velocity.y = -absf(velocity.y) * bounciness
