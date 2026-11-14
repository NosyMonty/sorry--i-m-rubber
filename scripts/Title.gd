extends Node2D
## Root of Title.tscn. Everything visible is a node you place in the editor.


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		GameData.fight_index = 0
		get_tree().change_scene_to_file("res://scripts/Battle.gd")
		
