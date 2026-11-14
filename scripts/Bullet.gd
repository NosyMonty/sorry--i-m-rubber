class_name Bullet
extends Area2D
## Attach to the root of Bullet.tscn.
## Needs children named exactly: Sprite2D, CollisionShape2D.

var velocity := Vector2.ZERO
var fall_accel := 0.0     # not called "gravity": Area2D already has that property
var reflected := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D


## Called by Battle.gd right after the bullet is added to the tree.
func setup(tex: Texture2D, pos: Vector2, vel: Vector2, grav: float, radius: float) -> void:
	position = pos
	velocity = vel
	fall_accel = grav

	# New shape per bullet, otherwise every bullet would share one resource
	var circle := CircleShape2D.new()
	circle.radius = radius * 0.8
	shape.shape = circle

	if tex:
		sprite.texture = tex
	if sprite.texture:
		var biggest := maxf(sprite.texture.get_width(), sprite.texture.get_height())
		sprite.scale = Vector2.ONE * (radius * 2.0 / biggest)


func reflect() -> void:
	reflected = true
	velocity = -velocity
	fall_accel = 0.0
	modulate = Color(1.0, 1.0, 0.4)


func _physics_process(delta: float) -> void:
	velocity.y += fall_accel * delta
	position += velocity * delta
	if not Rect2(-450, -300, 900, 600).has_point(position):
		queue_free()
		
