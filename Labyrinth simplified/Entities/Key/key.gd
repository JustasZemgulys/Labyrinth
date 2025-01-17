extends Node3D

@onready var sound = $Ding
@onready var near_sound = $Shining

func _on_sound_played():
	get_parent()._on_key_collected()
	queue_free()

func _on_detection_area_body_entered(body):
	if body.name == "Player":
		if not near_sound.playing:  # Prevent overlapping sound
			near_sound.play()

func _on_detection_area_body_exited(body):
	if body.name == "Player":
		near_sound.stop()

func _on_pick_up_area_body_entered(body):
	if body.name == "Player":
		near_sound.stop()
		$MeshInstance3D.visible = false 
		near_sound.stop()
		sound.play()
		print("Key collected!")
		# Create a Timer to wait before freeing the node
		var timer = Timer.new()
		timer.wait_time = 1  # Wait for the sound duration
		timer.one_shot = true
		timer.connect("timeout", Callable(self, "_on_sound_played"))
		add_child(timer)
		timer.start()

