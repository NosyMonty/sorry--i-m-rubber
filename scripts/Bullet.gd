class_name Bullet
extends Area2D
## One enemy projectile. Created in code by Battle.gd, so there is no scene to wire up.
## Art: res://art/bullet_<kind>.png  (kinds: pin, roller, anvil, piano, needle)

const COLORS := {
	"pin": Color.SILVER,
	"roller": Color.DIM_GRAY,
	"anvil": Color.SLATE_GRAY,
	"piano": Color.WHITE,
	"needle": Color.CYAN,
}

var velocity := Vector2.ZERO
var gravity := 0.0
var reflected := false
var visual: Node2D


func setup(kind: String, pos: Vector2, vel: Vector2, grav: float, radius: float) -> void:
	position = pos
	velocity = vel
	gravity = grav
	add_to_group("bullets")

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius * 0.8
	shape.shape = circle
	add_child(shape)

	visual = Game.make_visual("res://art/bullet_%s.png" % kind, COLORS.get(kind, Color.WHITE), Vector2(radius * 2.0, radius * 2.0))
	add_child(visual)


func reflect() -> void:
	reflected = true
	velocity = -velocity
	gravity = 0.0
	visual.modulate = Color(1.0, 1.0, 0.4)


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	position += velocity * delta
	if not Rect2(-450, -300, 900, 600).has_point(position):
		queue_free()
