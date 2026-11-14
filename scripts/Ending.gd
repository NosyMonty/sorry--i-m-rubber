extends Node2D
## Root of Ending.tscn. Needs a Label child named TextLabel.

const LINES := [
	"* Noah Sinclair never did get hurt.",
	"* He did get a coffee, a bus route, a wizard's sob story, and a friend.",
	"* His boss denied the sick day anyway.",
	"* 'You look fine,' he said.",
	"THE END\n\nThanks for playing!",
]

var i := 0

@onready var label: Label = $TextLabel


func _ready() -> void:
	label.text = LINES[0]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		i += 1
		if i >= LINES.size():
			get_tree().change_scene_to_file("res://scenes/title.tscn")
		else:
			label.text = LINES[i]
