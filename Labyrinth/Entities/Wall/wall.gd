extends Node3D

var is_fake_wall = false
var is_ghost_wall = false
var stay_timer: Timer = null
var ghost_timer: Timer = null
var enlarged_area: Area3D = null
var click_counter: int = 0 

func set_fake_wall():
	# Sets the wall to be a fake one (posible to pass through)
	is_fake_wall = true  # Mark as a fake wall
	_initialize_stay_timer()
	_set_wall_material()
	_add_enlarged_collision_area()

func _initialize_stay_timer():
	# Initialize and configure the stay timer
	stay_timer = Timer.new()
	stay_timer.wait_time = 3  # 3 seconds
	stay_timer.one_shot = true
	stay_timer.connect("timeout", Callable(self, "_on_stay_timer_timeout"))
	add_child(stay_timer)

func _set_wall_material():
	# Change the wall's material to indicate it's a fake wall
	var material = $MeshInstance3D.get_active_material(0)
	if material:
		var unique_material = material.duplicate()
		unique_material.albedo_color = Color(1, 0, 0)#red
		#unique_material.albedo_color = Color(0.5, 0.5, 0.5)
		$MeshInstance3D.set_surface_override_material(0, unique_material)

func _add_enlarged_collision_area():
	# Add a larger collision area for fake walls
	var enlarged_area = Area3D.new()
	var enlarged_collision_shape = CollisionShape3D.new()
	var new_shape = BoxShape3D.new()
	new_shape.extents = Vector3(5, 10, 0.4)  # Dimensions of the collision box
	enlarged_collision_shape.shape = new_shape
	enlarged_area.add_child(enlarged_collision_shape)
	add_child(enlarged_area)

	# Position and connect the new collision shape
	enlarged_area.transform.origin = Vector3(0, 5, 0.3)  # Adjust as needed
	enlarged_area.connect("body_entered", Callable(self, "_on_body_entered"))
	enlarged_area.connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	# Called when an object enters the collision shape
	if is_fake_wall and body.name == "Player":  # Check if the colliding body is the player
		var rock_sound = $RockHint
		rock_sound.play()
		print("Touched a fake wall, timer start")
		stay_timer.start()

func _on_body_exited(body):
	# Called when an object exits the collision shape
	if is_fake_wall and body.name == "Player":  # Check if the colliding body is the player
		print("Timer stop")
		stay_timer.stop()

func _on_stay_timer_timeout():
	# Called when the timer times out (3 seconds)
	if is_fake_wall:
		var rock_sound = $RockFall
		rock_sound.play()
		print("Wall removed")
		_temp_disable_nearby_walls()

func _temp_disable_nearby_walls():
	# Function to temporarily disable nearby walls (make passable and invisible for 5 seconds)
	# Get the parent node (assuming it holds all walls)
	var parent = get_parent()
	# Iterate over nearby walls within a radius of 1 unit
	for child in parent.get_children():
		# Ensure the child is a wall and is not the current wall
		if child is Node3D:
			var distance = child.global_transform.origin.distance_to(global_transform.origin)
			if distance <= 1.0:  # 1 unit radius
				print("Temporarily disabling wall at ", child.global_transform.origin)
				child.call_deferred("_set_wall_state", false)  # Disable the wall
				
				# Start a timer to re-enable the wall after 5 seconds
				var reenable_timer = Timer.new()
				reenable_timer.wait_time = 5  # 5 seconds
				reenable_timer.one_shot = true
				reenable_timer.connect("timeout", Callable(child, "_set_wall_state").bind(true))  # Re-enable the wall
				child.add_child(reenable_timer)
				reenable_timer.start()

func _set_wall_state(enabled: bool):
	# Helper function to set the wall's state (visible, passable, or not)
	$MeshInstance3D.visible = enabled
	for shape_child in $StaticBody3D.get_children():
			if shape_child is CollisionShape3D:
				shape_child.disabled = not enabled

func set_ghost_wall():
	# Initialize the ghost wall
	is_ghost_wall = true
	_set_ghost_wall_material()
	_set_wall_state(false)
	_reset_ghost_wall_timer()

func _reset_ghost_wall_timer():
	# Create the ghost wall timer if it doesn't exist
	ghost_timer = Timer.new()
	ghost_timer.wait_time = 5  # Every 10 seconds
	ghost_timer.one_shot = false  # Repeat timer
	ghost_timer.connect("timeout", Callable(self, "_attempt_activate_ghost_wall"))
	add_child(ghost_timer)  # Add to the scene tree
	ghost_timer.call_deferred("start")

func _attempt_activate_ghost_wall():
	# Randomly determine if the ghost wall should activate (50% chance)
	if randi() % 2 == 0:
		_activate_ghost_wall()

func _activate_ghost_wall():
	print("Ghost wall activating")
	# Activate the ghost wall and make it passable
	_set_wall_state(true)

	# Start a timer to deactivate the ghost wall after 30 seconds
	var deactivate_timer = Timer.new()
	deactivate_timer.wait_time = 10  # 30 seconds
	deactivate_timer.one_shot = true
	deactivate_timer.connect("timeout", Callable(self, "_deactivate_ghost_wall"))
	add_child(deactivate_timer)
	deactivate_timer.call_deferred("start")

func _deactivate_ghost_wall():
	print("Ghost wall deactivating")
	_set_wall_state(false)

func _set_ghost_wall_material():
	# Change the wall's material to indicate it's a fake wall
	var material = $MeshInstance3D.get_active_material(0)
	if material:
		var unique_material = material.duplicate()
		unique_material.albedo_color = Color(0.5, 0.5, 1)  # Set to blue
		$MeshInstance3D.set_surface_override_material(0, unique_material)
