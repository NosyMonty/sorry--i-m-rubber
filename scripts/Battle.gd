extends Node2D

enum State { TEXT, MENU, DODGE }

const BOX := Rect2(-280, -110, 560, 220)   # relative to the arena centre
const ARENA_POS := Vector2(640, 470)       # for a 1280x720 window
const ENEMY_POS := Vector2(640, 170)
const DODGE_TIME := 7.0

var enemy: Dictionary
var state := State.TEXT
var frustration := 0.0

var queue: Array = []
var after_lines: Callable
var typing := false
var tween: Tween

var menu_i := 0
var dodge_t := 0.0
var spawn_t := 0.0
var pattern_i := 0
var t := 0.0

var arena: Node2D
var soul: Soul
var text_label: Label
var bar: ProgressBar
var bar_label: Label
var enemy_vis: Node2D


func _ready() -> void:
	enemy = Game.enemies[Game.fight_index]
	Game.play_music(enemy.music)
	_build_ui()
	_say_lines(enemy.intro, _show_menu)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.14)
	bg.size = Vector2(1280, 720)
	add_child(bg)

	enemy_vis = Game.make_visual("res://art/enemy_%d.png" % Game.fight_index, enemy.color, Vector2(260, 260))
	enemy_vis.position = ENEMY_POS
	add_child(enemy_vis)

	arena = Node2D.new()
	arena.position = ARENA_POS
	add_child(arena)

	var box_bg := ColorRect.new()
	box_bg.color = Color.BLACK
	box_bg.position = BOX.position
	box_bg.size = BOX.size
	arena.add_child(box_bg)

	var border := Line2D.new()
	border.width = 6.0
	border.closed = true
	border.points = PackedVector2Array([
		BOX.position,
		Vector2(BOX.end.x, BOX.position.y),
		BOX.end,
		Vector2(BOX.position.x, BOX.end.y),
	])
	arena.add_child(border)

	text_label = Label.new()
	text_label.position = BOX.position + Vector2(24, 16)
	text_label.size = BOX.size - Vector2(48, 32)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 28)
	arena.add_child(text_label)

	soul = Soul.new()
	soul.box_rect = BOX
	soul.hit.connect(_on_soul_hit)
	arena.add_child(soul)
	soul.set_active(false)

	var hud := CanvasLayer.new()
	add_child(hud)

	var name_label := Label.new()
	name_label.text = enemy.name
	name_label.position = Vector2(40, 20)
	name_label.add_theme_font_size_override("font_size", 32)
	hud.add_child(name_label)

	bar = ProgressBar.new()
	bar.position = Vector2(40, 70)
	bar.size = Vector2(360, 28)
	bar.custom_minimum_size = Vector2(360, 28)
	bar.max_value = enemy.need
	bar.value = 0.0
	bar.show_percentage = false
	hud.add_child(bar)

	bar_label = Label.new()
	bar_label.text = "FRUSTRATION"
	bar_label.position = Vector2(40, 102)
	hud.add_child(bar_label)


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
				Game.sfx("select")
				_draw_menu()
			elif event.is_action_pressed("ui_down"):
				menu_i = wrapi(menu_i + 1, 0, enemy.acts.size())
				Game.sfx("select")
				_draw_menu()
			elif event.is_action_pressed("ui_accept"):
				_choose(menu_i)


func _choose(i: int) -> void:
	var act: Dictionary = enemy.acts[i]
	Game.sfx("select")

	if act.get("correct", false):
		if frustration >= enemy.need:
			Game.sfx("win")
			_say_lines(act.lines + enemy.win, _next_fight)
		else:
			_say_lines(act.early, _start_dodge)
		return

	frustration = minf(frustration + act.get("gain", 0.0), enemy.need)
	_update_bar()
	_say_lines(act.lines, _start_dodge)


func _next_fight() -> void:
	Game.fight_index += 1
	if Game.fight_index >= Game.enemies.size():
		get_tree().change_scene_to_file("res://Ending.tscn")
	else:
		get_tree().reload_current_scene()

func _start_dodge() -> void:
	state = State.DODGE
	text_label.text = ""
	dodge_t = DODGE_TIME
	spawn_t = 0.6
	soul.position = Vector2.ZERO
	soul.set_active(true)


func _end_dodge() -> void:
	soul.set_active(false)
	get_tree().call_group("bullets", "queue_free")
	if frustration >= enemy.need:
		_say_lines(enemy.ready_lines, _show_menu)
	else:
		_say_lines([enemy.turn_lines.pick_random()], _show_menu)


func _process(delta: float) -> void:
	t += delta
	enemy_vis.position.y = ENEMY_POS.y + sin(t * 2.0) * 6.0

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
	Game.sfx("boing")
	bullet.reflect()
	frustration = minf(frustration + enemy.hit_gain, enemy.need)
	_update_bar()
	_pop_text("BOING!", soul.position)

	var tw := create_tween()
	tw.tween_property(enemy_vis, "rotation", 0.15, 0.05)
	tw.tween_property(enemy_vis, "rotation", 0.0, 0.2)


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
	

func _spawn(kind: String, pos: Vector2, vel: Vector2, grav := 0.0, r := 14.0) -> void:
	var b := Bullet.new()
	b.setup(kind, pos, vel, grav, r)
	arena.add_child(b)


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
