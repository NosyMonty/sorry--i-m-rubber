extends Node2D
## Root of Battle.tscn. Flow: intro text -> menu (pick an Act) -> response text ->
## dodge phase -> menu ... Getting hit bounces the bullet back and fills the
## Frustration bar; once full, the hidden correct Act ends the fight.
## Run out of turns first and it's Game Over (Retry / Back to title).
## Esc returns to the title at any time.
## Scene paths live in GameData.gd.

enum State { TEXT, MENU, DODGE, OVER }

const BOX := Rect2(-280, -110, 560, 220)   # relative to the Arena node
const ARENA_POS := Vector2(640, 470)       # for a 1280x720 window
const ENEMY_POS := Vector2(640, 170)
const ENEMY_SIZE := 260.0
const DODGE_TIME := 7.0

# Fill these in the Inspector (select the Battle root node)
@export var enemy_textures: Array[Texture2D] = []   # 4 entries: Todd, Steve, Merlot, Needle
@export var tex_pin: Texture2D
@export var tex_roller: Texture2D
@export var tex_anvil: Texture2D
@export var tex_piano: Texture2D
@export var tex_needle: Texture2D

var enemy: Dictionary
var state := State.TEXT
var frustration := 0.0
var turns_left := 0

var queue: Array = []
var after_lines: Callable
var typing := false
var tween: Tween

var menu_i := 0
var dodge_t := 0.0
var spawn_t := 0.0
var pattern_i := 0
var time := 0.0

@onready var bullet_scene: PackedScene = load(GameData.BULLET_PATH)
@onready var enemy_sprite: Sprite2D = $Enemy
@onready var arena: Node2D = $Arena
@onready var text_label: Label = $Arena/DialogueLabel
@onready var bullets: Node2D = $Arena/Bullets
@onready var soul: Soul = $Arena/Soul
@onready var name_label: Label = $HUD/NameLabel
@onready var bar: ProgressBar = $HUD/FrustrationBar
@onready var bar_label: Label = $HUD/BarLabel
@onready var music: AudioStreamPlayer = $Music
@onready var boss_music: AudioStreamPlayer = $BossMusic
@onready var sfx_boing: AudioStreamPlayer = $SfxBoing
@onready var sfx_select: AudioStreamPlayer = $SfxSelect
@onready var sfx_win: AudioStreamPlayer = $SfxWin


func _ready() -> void:
	enemy = GameData.enemies[GameData.fight_index]

	arena.position = ARENA_POS
	soul.box_rect = BOX
	soul.hit.connect(_on_soul_hit)

	turns_left = enemy.turn_limit
	_update_header()
	bar.max_value = enemy.need
	bar.value = 0.0
	bar_label.text = "FRUSTRATION"

	_setup_enemy_sprite()

	if enemy.get("boss", false):
		boss_music.play()
	else:
		music.play()

	_say_lines(enemy.intro, _show_menu)


func _setup_enemy_sprite() -> void:
	var idx: int = GameData.fight_index
	var tex: Texture2D = enemy_textures[idx] if idx < enemy_textures.size() else null
	if tex:
		enemy_sprite.texture = tex
		enemy_sprite.modulate = Color.WHITE
	else:
		enemy_sprite.modulate = enemy.color   # tint the placeholder instead
	if enemy_sprite.texture:
		var biggest := maxf(enemy_sprite.texture.get_width(), enemy_sprite.texture.get_height())
		enemy_sprite.scale = Vector2.ONE * (ENEMY_SIZE / biggest)
	enemy_sprite.position = ENEMY_POS


func _update_header() -> void:
	name_label.text = "%s     TURNS LEFT: %d" % [enemy.name, maxi(turns_left, 0)]


func _update_bar() -> void:
	create_tween().tween_property(bar, "value", frustration, 0.2)
	bar_label.text = "AT WIT'S END!" if frustration >= enemy.need else "FRUSTRATION"

func _say_lines(lines: Array, next: Callable) -> void:
	state = State.TEXT
	queue = lines.duplicate()
	after_lines = next
	_next_line()


func _next_line() -> void:
	if queue.is_empty():
		after_lines.call()
		return
	_type(queue.pop_front())


func _type(txt: String) -> void:
	text_label.text = txt
	text_label.visible_ratio = 0.0
	typing = true
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(text_label, "visible_ratio", 1.0, maxf(txt.length() * 0.03, 0.1))
	tween.finished.connect(func(): typing = false)


func _show_menu() -> void:
	state = State.MENU
	menu_i = 0
	_draw_menu()


func _draw_menu() -> void:
	var s := ""
	for i in enemy.acts.size():
		s += ("> " if i == menu_i else "   ") + enemy.acts[i].label + "\n"
	text_label.text = s
	text_label.visible_ratio = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(GameData.TITLE_PATH)
		return

	match state:
		State.TEXT:
			if event.is_action_pressed("ui_accept"):
				if typing:
					if tween and tween.is_valid():
						tween.kill()
					text_label.visible_ratio = 1.0
					typing = false
				else:
					_next_line()
		State.MENU:
			if event.is_action_pressed("ui_up"):
				menu_i = wrapi(menu_i - 1, 0, enemy.acts.size())
				sfx_select.play()
				_draw_menu()
			elif event.is_action_pressed("ui_down"):
				menu_i = wrapi(menu_i + 1, 0, enemy.acts.size())
				sfx_select.play()
				_draw_menu()
			elif event.is_action_pressed("ui_accept"):
				_choose(menu_i)
		State.OVER:
			if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
				menu_i = 1 - menu_i
				sfx_select.play()
				_draw_over_menu()
			elif event.is_action_pressed("ui_accept"):
				if menu_i == 0:
					get_tree().reload_current_scene()   # retry this fight
				else:
					get_tree().change_scene_to_file(GameData.TITLE_PATH)


func _choose(i: int) -> void:
	var act: Dictionary = enemy.acts[i]
	sfx_select.play()

	# Out of turns: only the correct Act (with a full bar) can still save you
	if turns_left <= 0 and not act.get("correct", false):
		_game_over()
		return

	if act.get("correct", false):
		if frustration >= enemy.need:
			sfx_win.play()
			_say_lines(act.lines + enemy.win, _next_fight)
		else:
			_say_lines(act.early, _start_dodge)
		return

	frustration = minf(frustration + act.get("gain", 0.0), enemy.need)
	_update_bar()
	_say_lines(act.lines, _start_dodge)


func _next_fight() -> void:
	GameData.fight_index += 1
	if GameData.fight_index >= GameData.enemies.size():
		get_tree().change_scene_to_file(GameData.ENDING_PATH)
	else:
		get_tree().reload_current_scene()

func _start_dodge() -> void:
	state = State.DODGE
	turns_left -= 1
	_update_header()
	text_label.text = ""
	dodge_t = DODGE_TIME
	spawn_t = 0.6
	soul.position = Vector2.ZERO
	soul.set_active(true)


func _end_dodge() -> void:
	soul.set_active(false)
	for b in bullets.get_children():
		b.queue_free()
	if turns_left <= 0 and frustration < enemy.need:
		_game_over()
		return
	if frustration >= enemy.need:
		_say_lines(enemy.ready_lines, _show_menu)
	else:
		_say_lines([enemy.turn_lines.pick_random()], _show_menu)

func _game_over() -> void:
	soul.set_active(false)
	for b in bullets.get_children():
		b.queue_free()
	music.stop()
	boss_music.stop()
	_say_lines(["* Noah's shift starts.\n* No injury, no sick day.", "GAME OVER"], _show_over_menu)


func _show_over_menu() -> void:
	state = State.OVER
	menu_i = 0
	_draw_over_menu()


func _draw_over_menu() -> void:
	var options := ["Retry this fight", "Back to title"]
	var s := ""
	for i in options.size():
		s += ("> " if i == menu_i else "   ") + options[i] + "\n"
	text_label.text = s
	text_label.visible_ratio = 1.0

func _process(delta: float) -> void:
	time += delta
	enemy_sprite.position.y = ENEMY_POS.y + sin(time * 2.0) * 6.0

	if state != State.DODGE:
		return

	dodge_t -= delta
	spawn_t -= delta
	if spawn_t <= 0.0:
		spawn_t = enemy.interval
		call(enemy.patterns[pattern_i % enemy.patterns.size()])
		pattern_i += 1
	if dodge_t <= 0.0:
		_end_dodge()


func _on_soul_hit(bullet: Bullet) -> void:
	sfx_boing.play()
	bullet.reflect()
	frustration = minf(frustration + enemy.hit_gain, enemy.need)
	_update_bar()
	_pop_text("BOING!", soul.position)

	var tw := create_tween()
	tw.tween_property(enemy_sprite, "rotation", 0.15, 0.05)
	tw.tween_property(enemy_sprite, "rotation", 0.0, 0.2)


func _pop_text(txt: String, pos: Vector2) -> void:
	var l := Label.new()
	l.text = txt
	l.position = pos + Vector2(-40, -60)
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", Color.YELLOW)
	arena.add_child(l)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 50.0, 0.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(l.queue_free)

func _tex(kind: String) -> Texture2D:
	match kind:
		"pin": return tex_pin
		"roller": return tex_roller
		"anvil": return tex_anvil
		"piano": return tex_piano
		"needle": return tex_needle
	return null


func _spawn(kind: String, pos: Vector2, vel: Vector2, grav := 0.0, r := 14.0) -> void:
	var b: Bullet = bullet_scene.instantiate()
	bullets.add_child(b)          # must be in the tree before setup()
	b.setup(_tex(kind), pos, vel, grav, r)


func _rand_x() -> float:
	return randf_range(BOX.position.x + 30.0, BOX.end.x - 30.0)


func p_pin_drop() -> void:
	_spawn("pin", Vector2(_rand_x(), BOX.position.y - 20.0), Vector2(0, 260))


func p_aimed() -> void:
	var from := Vector2(_rand_x(), BOX.position.y - 20.0)
	var dir := (soul.position - from).normalized()
	_spawn(enemy.get("bullet", "pin"), from, dir * 320.0)


func p_roller() -> void:
	var from_left := randf() < 0.5
	var y := randf_range(BOX.position.y + 40.0, BOX.end.y - 40.0)
	var x := BOX.position.x - 60.0 if from_left else BOX.end.x + 60.0
	_spawn("roller", Vector2(x, y), Vector2(230.0 if from_left else -230.0, 0.0), 0.0, 38.0)


func p_anvil() -> void:
	_spawn("anvil", Vector2(_rand_x(), BOX.position.y - 30.0), Vector2.ZERO, 700.0, 28.0)


func p_piano() -> void:
	_spawn("piano", Vector2(_rand_x(), BOX.position.y - 40.0), Vector2.ZERO, 450.0, 40.0)


func p_needle_fan() -> void:
	var base := PI / 2.0 + sin(dodge_t * 2.0) * 0.5
	for i in range(-2, 3):
		_spawn("needle", Vector2(0, BOX.position.y - 20.0), Vector2.from_angle(base + i * 0.35) * 240.0)
		
