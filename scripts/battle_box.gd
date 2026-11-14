extends Node2D

const BOX := Rect2(-160, -100, 320, 200)

func _draw() -> void:
	draw_rect(BOX, Color.BLACK, true)
	draw_rect(BOX, Color.WHITE, false, 4.0)
