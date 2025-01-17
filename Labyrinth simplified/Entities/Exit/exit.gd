extends Node3D

func _on_area_3d_body_entered(body):
	if body.name == "Player":
		call_deferred("trigger_victory_screen")

# Victory screen trigger
func trigger_victory_screen():
	print("Victory! You reached the exit!")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://Menus/Game_end_menu/Game_end.tscn")
