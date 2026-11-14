extends Node2D
## Ending.tscn root (a plain Node2D). Shown after the last fight.

const LINES := [
	"* Noah Sinclair never did get hurt.",
	"* He did get a coffee, a bus route, a wizard's sob story, and a friend.",
	"* His boss denied the sick day anyway.",
	"* 'You look fine,' he said.",
	"THE END\n\nThanks for playing!",
]

var i := 0
var label: Label


func _ready() -> void:
	Game.play_music("ending")

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12)
	bg.size = Vector2(1280, 720)
	add_child(bg)

	label = Label.new()
	label.position = Vector2(140, 240)
	label.size = Vector2(1000, 300)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 40)
	label.text = LINES[0]
	add_child(label)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		i += 1
		if i >= LINES.size():
			Game.to_title()
		else:
			label.text = LINES[i]
