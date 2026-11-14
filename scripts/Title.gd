extends Node2D
## Root of Title.tscn. Scene paths live in GameData.gd.


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		GameData.fight_index = 0   # every new run starts at the first fight
		get_tree().change_scene_to_file(GameData.BATTLE_PATH)
		
