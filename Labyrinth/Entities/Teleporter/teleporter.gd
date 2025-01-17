extends Node3D

# Variable to hold the destination cell for teleportation
var destination_cell: Vector3

func set_teleporting_position(destination: Vector3):
	# Method to set the destination cell for teleportation
	destination_cell = destination

func _on_area_3d_body_entered(body: Node3D):
	# Check if the body is the player
	if body.name == "Player":
		var sound = $Zing
		sound.play()
		get_parent()._on_teleportation(destination_cell, body)
