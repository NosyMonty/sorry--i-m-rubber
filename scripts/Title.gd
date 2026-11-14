extends Node2D
## Title.tscn root (a plain Node2D). Set this as the project's Main Scene.


func _ready() -> void:
	Game.play_music("title")

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12)
	bg.size = Vector2(1280, 720)
	add_child(bg)

	_label("NOAH SINCLAIR", 110, 220)
	_label("he just wants a sick day", 36, 350)
	_label("Press Enter", 28, 560)


func _label(txt: String, font_size: int, y: float) -> void:
	var l := Label.new()
	l.text = txt
	l.position = Vector2(0, y)
	l.size = Vector2(1280, font_size * 1.5)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	add_child(l)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		Game.sfx("select")
		Game.start()
