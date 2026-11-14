class_name Soul
extends Area2D

signal hit(bullet: Bullet)

const ANIM_IDLE := "Idle"
const ANIM_RUN := "Run"
const ANIM_HURT := "Hurt"
const ANIM_BALL := "Ball"

@export var radius := 14.0            # keep equal to the circle shape's radius
@export var max_speed := 260.0
@export var accel := 1100.0
@export var bounciness := 0.85        # 1.0 = perfectly bouncy, 0 = stops dead
@export var faces_right := true       # untick if your Run art faces left

var box_rect := Rect2(-280, -110, 560, 220)   # Battle.gd overwrites this
var velocity := Vector2.ZERO
var invuln := 0.0
var hurt_time := 0.0
var active := false
var base_scale := Vector2.ONE

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	base_scale = sprite.scale
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	set_active(false)


func set_active(value: bool) -> void:
	active = value
	visible = value
	set_deferred("monitoring", value)
	velocity = Vector2.ZERO
	invuln = 0.0
	hurt_time = 0.0
	sprite.scale = base_scale
	sprite.modulate.a = 1.0
	if value:
		_play(ANIM_IDLE)


func _physics_process(delta: float) -> void:
	if not active:
		return

	invuln = maxf(invuln - delta, 0.0)
	hurt_time = maxf(hurt_time - delta, 0.0)

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

	_update_animation(input)

	# Blink while invulnerable
	sprite.modulate.a = 0.45 if (invuln > 0.0 and int(invuln * 20.0) % 2 == 0) else 1.0


func _update_animation(input: Vector2) -> void:
	# Face the way he's steering
	if absf(input.x) > 0.1:
		sprite.flip_h = (input.x < 0.0) if faces_right else (input.x > 0.0)

	if hurt_time > 0.0:
		_play(ANIM_HURT)                       # just got hit
	elif velocity.length() > max_speed * 1.1:
		_play(ANIM_BALL)                       # flying after a bounce
	elif input != Vector2.ZERO:
		_play(ANIM_RUN)
	else:
		_play(ANIM_IDLE)


func _play(anim: String) -> void:
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


func _on_area_entered(area: Area2D) -> void:
	var b := area as Bullet
	if b == null or b.reflected or invuln > 0.0:
		return
	invuln = 0.8
	hurt_time = 0.4
	var away := (position - b.position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.UP
	velocity = away * 460.0
	_squash()
	hit.emit(b)


func _squash() -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(base_scale.x * 1.7, base_scale.y * 0.4), 0.07)
	tw.tween_property(sprite, "scale", Vector2(base_scale.x * 0.7, base_scale.y * 1.5), 0.10)
	tw.tween_property(sprite, "scale", base_scale, 0.30).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
