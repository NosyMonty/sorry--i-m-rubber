extends Node2D
## Root of the Ending scene. Shows the epilogue, then the credits, then returns
## to the title. Scene paths live in GameData.gd.
## It looks for a Label named TextLabel anywhere in the scene; if there isn't one,
## it uses the first Label it finds.
##
## To add or change a credit, edit the CREDITS list below. One entry = one page.

const STORY := [
	"* Noah Sinclair never did get hurt.",
	"* He did get a coffee, a bus route, a wizard's sob story, and a friend.",
	"* His boss denied the sick day anyway.",
	"* 'You look fine,' he said.",
	"THE END\n\nThanks for playing!",
]

const CREDITS := [
	"CREDITS\n\nCharacter animations\nTiM - Free Character Animations\nby DANI MACCARI\ndani-maccari.itch.io/player-animations-tim",
	"MUSIC\n\nEpic Techno Battle Music - Techno Song #20 - PROWESS - Best Techno Music Mix\nyoutube.com/watch?v=R5sOQxhh6wc",
	"MUSIC\n\nUltimate Boss Battle Music - Intense Final Clash (15 Minutes)\nyoutube.com/watch?v=DoWYvYold-w",
	"Made with Godot",
]

const STORY_FONT_SIZE := 40
const CREDITS_FONT_SIZE := 30   # smaller so long titles fit on screen

var pages: Array = []
var i := 0

@onready var label: Label = _find_label()


func _find_label() -> Label:
	var named := find_child("TextLabel", true, false) as Label
	if named:
		return named
	for node in find_children("*", "Label", true, false):
		return node as Label
	return null


func _ready() -> void:
	if label == null:
		push_error("Ending: no Label node found. Add a Label to the Ending scene.")
		return
	pages = STORY + CREDITS
	_show_page(0)


func _show_page(n: int) -> void:
	var size := STORY_FONT_SIZE if n < STORY.size() else CREDITS_FONT_SIZE
	label.add_theme_font_size_override("font_size", size)
	label.text = pages[n]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(GameData.TITLE_PATH)   # skip straight to the title
	elif event.is_action_pressed("ui_accept"):
		i += 1
		if i >= pages.size():
			get_tree().change_scene_to_file(GameData.TITLE_PATH)
		elif label:
			_show_page(i)
			
