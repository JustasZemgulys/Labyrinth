extends Node3D

@onready var wall_scene = preload("res://Entities/Wall/wall.tscn")
@onready var key_scene = preload("res://Entities/Key/key.tscn")
@onready var exit_scene = preload("res://Entities/Exit/exit.tscn")
@onready var teleporter_scene = preload("res://Entities/Teleporter/teleporter.tscn")
@onready var player_scene = preload("res://Entities/Player/player.tscn")

const N = 1
const E = 2
const S = 4
const W = 8

var cell_walls = {Vector2(0,-1): N, Vector2(1,0): E,
				Vector2(0,1): S,Vector2(-1,0): W}

@export var height = 10 #map height
@export var width = 10 #map width
@export var scale_factor: float = 5
@export var inward_shift = -0.2

var Map = TileMap.new()
var search_start = 0 # width value from where the maze begins
var map_seed = 0


var door_instance = null
var three_wall_cells = null
var three_wall_cells_used: Array = []

func _ready():
	while true:
		# Generate a new seed and initialize the maze
		map_seed = randi()
		search_start = randi_range(0, width)
		seed(map_seed)
		print("Seed: ", map_seed, " ,search start: ", search_start)

		make_maze()
		create_entrance()
		
		var cell_distances_from_entrance = calculate_distances()
		var furthest_point = find_furthest_point(cell_distances_from_entrance)
		three_wall_cells = find_cells_with_three_walls(cell_distances_from_entrance)
		
		spawn_key(three_wall_cells)
		spawn_door(three_wall_cells)
		spawn_exit(three_wall_cells)
		
		if three_wall_cells.size() > 5:
			var middle_cell = find_middle_cell_with_unique_distance(cell_distances_from_entrance)
			var portal_cells = check_for_two_free_cells(cell_distances_from_entrance, middle_cell)
			if portal_cells and portal_cells[0].size() > 1 and portal_cells[1].size() > 1 :
				print("Distance to furthest point: ", furthest_point[0], " Cell: ", furthest_point[1])
				print("Number of cells with exactly three walls: ", three_wall_cells)
				var open_walls = find_open_walls(middle_cell)
				spawn_wall(middle_cell,open_walls[0])
				build_3d_maze(cell_distances_from_entrance)
				spawn_teleporter(portal_cells[0][0], portal_cells[1][1])
				spawn_teleporter(portal_cells[1][0], portal_cells[0][1])
				spawn_player()
				break  # Exit the loop if the condition is satisfied
			else:
				clear_maze()
		else:
			clear_maze()

func clear_maze():
	# Clear maze structure
	for child in get_children():
		child.queue_free()

func check_neighbors(cell, unvisited):
	#Checks the cells neighbors,
	#returns an array of cell's unvisited neighbors
	var list = []
	for n in cell_walls.keys():
		if cell + n in unvisited:
			list.append(cell + n)
	return list

func make_maze():
	#First fills map with solid tiles
	#Then executes recursive backtracker algorithm
	#Making sure each tile has been visited atleast once
	var unvisited = []  # array of unvisited tiles
	var stack = []
	# fill the map with solid tiles
	Map.clear()
	for x in range(width):
		for y in range(height):
			unvisited.append(Vector2(x, y))
			Map.set_cell(0, Vector2(x, y), N|E|S|W, Vector2i(0, 0), 0)
	var current = Vector2(0, search_start)
	unvisited.erase(current)
	# execute recursive backtracker algorithm
	while unvisited:
		var neighbors = check_neighbors(current, unvisited)
		if neighbors.size() > 0:
			var next = neighbors[randi() % neighbors.size()]
			stack.append(current)
			# remove walls from *both* cells
			var dir = next - current
			var current_walls = Map.get_cell_source_id(0, current) - cell_walls[dir]
			var next_walls = Map.get_cell_source_id(0, next) - cell_walls[-dir]
			Map.set_cell(0, current, current_walls, Vector2i(0, 0), 0)
			Map.set_cell(0, next, next_walls, Vector2i(0, 0), 0)
			current = next
			unvisited.erase(current)
		elif stack:
			current = stack.pop_back()

func create_entrance():
	#Creates the entrance to the labyrinth
	var entrance_cell = Vector2(0, search_start)  # Starting cell
	var entrance_walls = Map.get_cell_source_id(0, entrance_cell)
	
	# Remove the wall of the entrance cell
	entrance_walls -= W
	Map.set_cell(0, entrance_cell, entrance_walls, Vector2i(0, 0), 0)

func calculate_distances() -> Dictionary:
	# Calculates the distance from Vector2(0, search_start) to each cell
	var distances = {}  # Store distances from the start cell
	var visited = []  # Keep track of visited cells
	var queue = []  # BFS queue: contains pairs of (cell, distance)
	var start_cell = Vector2(0, search_start)
	queue.append([start_cell, 0])  # Start from the initial cell with distance 0
	visited.append(start_cell)
	while queue.size() > 0:
		var current_data = queue.pop_front()
		var current_cell = current_data[0]
		var current_distance = current_data[1]
		
		# Record the distance to the current cell
		distances[current_cell] = current_distance
		
		# Check neighbors
		for direction in cell_walls.keys():
			var neighbor = current_cell + direction
			var walls = Map.get_cell_source_id(0, current_cell)
			
			# Only proceed if there's no wall blocking the path
			if not (walls & cell_walls[direction]) and not (neighbor in visited):
				queue.append([neighbor, current_distance + 1])
				visited.append(neighbor)
	return distances

func find_furthest_point(cell_distances_from_entrance) -> Array:
	var furthest_point = Vector2(0, search_start)
	var furthest_point_distance = -1
	for x in range(width):
		for y in range(height):
			var current_cell = Vector2(x, y)
			if cell_distances_from_entrance[current_cell] > furthest_point_distance:
				furthest_point = current_cell
				furthest_point_distance = cell_distances_from_entrance[current_cell]
	return [furthest_point_distance, furthest_point]

func find_cells_with_three_walls(cell_distances_from_entrance: Dictionary) -> Array:
	#Finds cells with 3 walls and sorts them by distance from the entrance
	var cells_with_three_walls = []
	for x in range(width):
		for y in range(height):
			var cell = Vector2(x, y)
			var walls = Map.get_cell_source_id(0, cell)
			# Count the number of walls for the cell
			var wall_count = 0
			for direction in [N, E, S, W]:
				if walls & direction:wall_count += 1
				# Add the cell to the list if it has exactly three walls
				if wall_count == 3:
					cells_with_three_walls.append(cell)
	
	#sorting by distance from the entrance
	for i in range(cells_with_three_walls.size()):
		for j in range(i + 1, cells_with_three_walls.size()):
			var cell_a = cells_with_three_walls[i]
			var cell_b = cells_with_three_walls[j]
			if cell_distances_from_entrance[cell_a] > cell_distances_from_entrance[cell_b]:
				var temp = cells_with_three_walls[i]
				cells_with_three_walls[i] = cells_with_three_walls[j]
				cells_with_three_walls[j] = temp
				
	return cells_with_three_walls

func spawn_key(three_wall_cells: Array):
	#Spawns the exit key in the first half of the labyrinth
	
	# Split the list into two halves
	var mid_index = three_wall_cells.size() / 2
	var first_half = three_wall_cells.slice(0, mid_index)
	
	# Choose two random cells for the key
	var key_cell = first_half[randi() % first_half.size()]
	#var key_cell = three_wall_cells.front()
	
	# Spawn the key
	var key_instance = key_scene.instantiate()
	key_instance.position = Vector3(key_cell.x * scale_factor, 0, key_cell.y * scale_factor)
	add_child(key_instance)
	
	three_wall_cells_used.append(key_cell)
	print("Key spawned at: ", key_cell)

func spawn_door(three_wall_cells: Array):
	#Spawns the exit door
	var door_cell = three_wall_cells.back()
	var missing_direction = find_open_walls(door_cell)
	# Spawns the door
	door_instance = wall_scene.instantiate()
	match missing_direction[0]:
		N:
			door_instance.position = Vector3(door_cell.x * scale_factor, 0, (door_cell.y - 0.5) * scale_factor)  # North wall
			door_instance.transform.basis = Basis().rotated(Vector3(0, 1, 0), deg_to_rad(0))
		E:
			door_instance.position = Vector3((door_cell.x + 0.5) * scale_factor, 0, door_cell.y * scale_factor)  # East wall
			door_instance.transform.basis = Basis().rotated(Vector3(0, 1, 0), deg_to_rad(90))
		S:
			door_instance.position = Vector3(door_cell.x * scale_factor, 0, (door_cell.y + 0.5) * scale_factor)  # South wall
			door_instance.transform.basis = Basis().rotated(Vector3(0, 1, 0), deg_to_rad(180))
		W:
			door_instance.position = Vector3((door_cell.x - 0.5) * scale_factor, 0, door_cell.y * scale_factor)  # West wall
			door_instance.transform.basis = Basis().rotated(Vector3(0, 1, 0), deg_to_rad(270))
	add_child(door_instance)
	print("Door spawned at: ", door_cell)

func spawn_exit(three_wall_cells: Array):
	var door_cell = three_wall_cells.back()
	# Spawn the exit object
	var exit_instance = exit_scene.instantiate()
	exit_instance.position = Vector3(door_cell.x * scale_factor, 0, door_cell.y * scale_factor)
	#exit_instance.position = Vector3(0, 0, 0)
	add_child(exit_instance)
	
	three_wall_cells_used.append(door_cell)
	print("exit spawned at: ", door_cell)

func build_3d_maze(cell_distances_from_entrance):
	# Builds the 3D maze using the wall scene
	var fake_walls = select_fake_walls()
	var ghost_wall = -1
	for x in range(width):
		for y in range(height):
			var cell = Vector2(x, y)
			var walls = Map.get_cell_source_id(0, cell)
			
			var fake_wall_direction = -1 
			# Randomly select one direction for the fake wall
			if cell in fake_walls:
				fake_wall_direction = randi_range(0, 4)
				ghost_wall = check_ghost_walls(cell, fake_wall_direction, cell_distances_from_entrance)
				
			if walls & N:
				spawn_wall(cell, N, fake_wall_direction == 0, ghost_wall)  # North wall
			if walls & E:
				spawn_wall(cell, E, fake_wall_direction == 1, ghost_wall)  # East wall
			if walls & S:
				spawn_wall(cell, S, fake_wall_direction == 2, ghost_wall)
			if walls & W:
				spawn_wall(cell, W, fake_wall_direction == 3, ghost_wall)

func _on_key_collected():
	if door_instance:
		door_instance.queue_free()

func select_fake_walls() -> Array:
	# Selects cells that will have fake walls
	var cells_to_select = int(pow(height * width, 0.5))
	var all_cells = []
	for x in range(width):
		for y in range(height):
			if is_on_edge(Vector2(x, y)):
				all_cells.append(Vector2(x, y))
	all_cells.shuffle()
	var selected_cells = all_cells.slice(0, cells_to_select)
	print("Selected cells with fake walls: ", selected_cells)
	return selected_cells

func is_on_edge(position: Vector2) -> bool:
	# Check if the wall is on the outermost row or column based on its direction
	if position.y == 0: return false  #South wall
	if position.y == height-1: return false  #North wall
	if position.x == width-1: return false  # East wall 
	if position.x == 0: return false  # West wall
	return true

func spawn_wall(cell: Vector2i, direction: int, fake_wall : bool = false, ghost_wall: int = -1) -> Node3D:
	# Spawns a wall at the specified cell and direction
	var wall_instance = wall_scene.instantiate()
	var position = null
	#wall_instance.transform = Transform3D(Basis().scaled(scale), Vector3(position.x, 0, position.z))
	
	match direction:
		N:
			position = Vector3(cell.x * scale_factor, 0, (cell.y-0.5) * scale_factor -inward_shift)
			wall_instance.position = position  # North wall
			wall_instance.transform.basis = Basis().rotated(Vector3(0, 1, 0), deg_to_rad(0))
		E:
			position = Vector3((cell.x + 0.5) * scale_factor +inward_shift, 0, cell.y * scale_factor)  
			wall_instance.position = position # East wall
			wall_instance.transform.basis = Basis().rotated(Vector3(0, 1, 0), deg_to_rad(90))
		S:
			position = Vector3(cell.x * scale_factor, 0, (cell.y + 0.5) * scale_factor + inward_shift)
			wall_instance.position = position  # South wall
			wall_instance.transform.basis = Basis().rotated(Vector3(0, 1, 0), deg_to_rad(180))
		W:
			position = Vector3((cell.x - 0.5) * scale_factor - inward_shift, 0, cell.y * scale_factor)
			wall_instance.position = position  # West wall
			wall_instance.transform.basis = Basis().rotated(Vector3(0, 1, 0), deg_to_rad(270))
	if fake_wall:
		print("Fake wall spawned at: ", cell, " direction: ", fake_wall)
		wall_instance.set_fake_wall()
		
		if ghost_wall != -1:
			print("Ghost wall spawned at: ", cell, " direction: ", ghost_wall)
			var ghost_instance = wall_scene.instantiate()
			# Position ghost wall at the same position as the normal wall
			match ghost_wall:
				N:
					ghost_instance.position = Vector3(cell.x * scale_factor, 0, (cell.y - 0.5) * scale_factor - inward_shift)  # North wall
					ghost_instance.transform.basis = Basis().rotated(Vector3(0, 1, 0), deg_to_rad(0))
				E:
					ghost_instance.position = Vector3((cell.x + 0.5) * scale_factor + inward_shift, 0, cell.y * scale_factor)  # East wall
					ghost_instance.transform.basis = Basis().rotated(Vector3(0, 1, 0), deg_to_rad(90))
				S:
					ghost_instance.position = Vector3(cell.x * scale_factor, 0, (cell.y + 0.5) * scale_factor+inward_shift)  # South wall
					ghost_instance.transform.basis = Basis().rotated(Vector3(0, 1, 0), deg_to_rad(180))
				W:
					ghost_instance.position = Vector3((cell.x - 0.5) * scale_factor - inward_shift, 0, cell.y * scale_factor)  # West wall
					ghost_instance.transform.basis = Basis().rotated(Vector3(0, 1, 0), deg_to_rad(270))
			ghost_instance.set_ghost_wall()
			add_child(ghost_instance)
			
	add_child(wall_instance)
	return wall_instance

func find_middle_cell_with_unique_distance(cell_distances_from_entrance):
	# Find a cell near the middle which could be used to split labyrinth in 2
	var unique_distances = {}
	var distance_count = {}
	
	# Count occurrences of each distance
	for cell in cell_distances_from_entrance:
		var distance = cell_distances_from_entrance[cell]
		distance_count[distance] = distance_count.get(distance, 0) + 1
	
	# Filter out non-unique distances
	for distance in distance_count.keys():
		if distance_count[distance] == 1:
			unique_distances[distance] = true
	var unique_distance_list = unique_distances.keys()
	if unique_distance_list.size() == 0:
		print("No unique distances found.")
		return null
	
	var middle_index = unique_distance_list.size() / 2
	var search_index = middle_index
	
	# Adjust the index by adding or subtracting 1 until a valid distance is found
	while search_index >= 0 and search_index < unique_distance_list.size():
		var candidate_distance = unique_distance_list[search_index]
		# Check if the candidate distance is valid
		for cell in cell_distances_from_entrance:
			if cell_distances_from_entrance[cell] == candidate_distance:
				print("Middle cell with unique distance:", cell, " Distance: ", candidate_distance)
				return Vector2(cell[0],cell[1])
		# Adjust the search index: alternate between -1 and +1
		search_index += (1 if search_index <= middle_index else -1)
	
	print("No middle cell found with unique distance.")
	return null

func check_for_two_free_cells(cell_distances_from_entrance, middle_cell):
	#Checks the unused three_wall_cells for compatible cells where the teleporter could go
	
	print("Currently used cells: ", three_wall_cells_used)
	var middle_distance = cell_distances_from_entrance[middle_cell]
	# Create lists to store the found cells
	var smaller_cells = []
	var larger_cells = []
	
	# Iterate through all available cells
	var cell_keys = cell_distances_from_entrance.keys()
	cell_keys.shuffle()  # Shuffles the keys randomly
	for cell in cell_keys:
		# Skip cells that are already used
		if cell in three_wall_cells_used:
			continue
		if cell not in three_wall_cells:
			continue
		
		var cell_distance = cell_distances_from_entrance[cell]
		
		# Find cells with smaller distance
		if cell_distance < middle_distance and smaller_cells.size() < 2:
			smaller_cells.append(cell)
		
		# Find cells with larger distance
		if cell_distance > middle_distance and larger_cells.size() < 2:
			larger_cells.append(cell)
		
		# If we have found both smaller and larger cells, break the loop
		if smaller_cells.size() == 2 and larger_cells.size() == 2:
			break
	
	# If we have found 2 smaller and 2 larger cells, return them
	if smaller_cells.size() == 2 and larger_cells.size() == 2:
		print("Found 4 free cells: Smaller Cells: ", smaller_cells, " Larger Cells: ", larger_cells)
		return [smaller_cells,larger_cells]
	else:
		print("Could not find the required cells for teleporters.")
		return null

func find_open_walls(cell: Vector2) -> Array:
	#Returns the directions in which the given cells wall are open
	if not Map: 
		return []  # Return empty if Map is null
	var open_walls = []  # List to store open directions
	# Get the current wall configuration of the cell
	var walls = Map.get_cell_source_id(0, cell)
	# Check for each direction to see if the wall is removed
	if not (walls & N):  # No North wall
		open_walls.append(N)
	if not (walls & E):  # No East wall
		open_walls.append(E)
	if not (walls & S):  # No South wall
		open_walls.append(S)
	if not (walls & W):  # No West wall
		open_walls.append(W)
	return open_walls

func spawn_teleporter(cell: Vector2,location : Vector2):
	#Spawns the teleporter
	var teleporter = teleporter_scene.instantiate()
	teleporter.position = Vector3(cell.x * scale_factor, 0, cell.y * scale_factor)
	teleporter.set_teleporting_position(Vector3(location.x * scale_factor, 0, location.y * scale_factor))
	add_child(teleporter)
	
	three_wall_cells_used.append(teleporter)
	print("Teleporter spawned at: ", cell, " going to: ", location)

func _on_teleportation(destination_cell, player):
	print("Teleported player to: ", destination_cell)
	player.global_position = destination_cell

func spawn_player():
	var player_instance = player_scene.instantiate()
	player_instance.position = Vector3(-1 * scale_factor,0, (search_start) * scale_factor)
	var rotation_angle_rad = deg_to_rad(270)
	player_instance.transform.basis = Basis().rotated(Vector3(0, 1, 0), rotation_angle_rad)
	add_child(player_instance)

func check_ghost_walls(fake_wall_cell: Vector2, fake_wall_direction: int, cell_distances_from_entrance) -> int:
	# Checks if a ghost wall can be placed in that cell
	# If its distance compared to  neighboring is bigger then likely the user wont be blocked in
	# possible open wall directions
	var directions = find_open_walls(fake_wall_cell)
	# Remove the fake wall direction from the list of directions
	directions.erase(fake_wall_direction)
	# Calculate distances from the entrance
	#var distances_from_start = cell_distances_from_entrance[fake_wall_cell]
	print(directions)
	if directions.size() > 0:
		return directions[0]
	
	# If no valid direction found, return -1
	return -1

func get_direction_vector(direction: int) -> Vector2:
	# Helper function to get the direction vector for N, E, S, W
	if direction == N:
		return Vector2(0, -1)
	elif direction == E:
		return Vector2(1, 0)
	elif direction == S:
		return Vector2(0, 1)
	elif direction == W:
		return Vector2(-1, 0)
	# If no valid direction is found, return a default value
	return Vector2(0, 0)
