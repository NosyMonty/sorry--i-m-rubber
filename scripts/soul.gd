class_name Soul
extends Area2D
## Noah in the battle box. Rubbery movement, bounces off the walls,
## squashes and stretches when a bullet hits him (no damage, ever).

signal hit(bullet: Bullet)

var box_rect := Rect2(-280, -110, 560, 220)
var max_speed := 260.0
var accel := 1100.0
var bounciness := 0.85   # 1.0 = perfectly bouncy, 0 = stops dead
var radius := 14.0

var velocity := Vector2.ZERO
var invuln := 0.0
var active := false
var visual: Node2D
var base_scale := Vector2.ONE


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)

	visual = Game.make_visual("res://art/noah.png", Color(1.0, 0.45, 0.6), Vector2(radius * 2.6, radius * 2.6))
	add_child(visual)
	base_scale = visual.scale

	area_entered.connect(_on_area_entered)


func set_active(value: bool) -> void:
	active = value
	visible = value
	set_deferred("monitoring", value)
	velocity = Vector2.ZERO
	invuln = 0.0
	if visual:
		visual.scale = base_scale
		visual.modulate.a = 1.0


func _physics_process(delta: float) -> void:
	if not active:
		return

	invuln = maxf(invuln - delta, 0.0)

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

	# Blink while invulnerable
	visual.modulate.a = 0.45 if (invuln > 0.0 and int(invuln * 20.0) % 2 == 0) else 1.0


func _on_area_entered(area: Area2D) -> void:
	var b := area as Bullet
	if b == null or b.reflected or invuln > 0.0:
		return
	invuln = 0.8
	var away := (position - b.position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.UP
	velocity = away * 460.0
	_squash()
	hit.emit(b)


func _squash() -> void:
	var tw := create_tween()
	tw.tween_property(visual, "scale", Vector2(base_scale.x * 1.7, base_scale.y * 0.4), 0.07)
	tw.tween_property(visual, "scale", Vector2(base_scale.x * 0.7, base_scale.y * 1.5), 0.10)
	tw.tween_property(visual, "scale", base_scale, 0.30).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
