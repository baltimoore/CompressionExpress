extends Node3D

var npc_scene = preload("res://scenes/_game_scene/characters/NPC.tscn")
var occupied_positions : Array[Vector3] = []
const MAX_SEARCH_ATTEMPTS = 20

#### ### ### ### ### ### ###
##  NPC CONTROLLING METHODS
#### ### ### ### ### ### ###
func spawn_npc():
	var path_follow = PathFollow3D.new()
	$NpcNavigation/EntrancePath.add_child(path_follow)
	path_follow.progress = 0
	
	var npc = npc_scene.instantiate()
	#npc.global_position = path_follow.global_position
	npc.path_follow = path_follow
	$NpcContainer.add_child(npc)
	
	npc.connect("reached_waiting_area", Callable(self, "_on_reached_waiting_area"))

func _on_reached_waiting_area(npc):
	# gotta remove the follow path, otherwise the movement loops
	npc.path_follow = null
	
	var free_spot = pick_random_free_spot()
	print("Located free target position: ")
	print(free_spot)
	npc.waiting_position_distance = free_spot
	# await their arrival at their waiting spot
	npc.connect("reached_waiting_position", Callable(self, "_on_reached_waiting_position"))

func _on_reached_waiting_position(npc_position):
	occupied_positions.append(npc_position)

#### ### ### ### ### ### ###
##  WAIT POSITION LOCATION METHODS
#### ### ### ### ### ### ###
func pick_random_free_spot():
	var area = $NpcNavigation/WaitingArea/CollisionShape3D
	var area_location = area.global_transform.origin
	var area_size = area.shape.size / 2.0 # calculating size from centerpoint
	for i in range (MAX_SEARCH_ATTEMPTS):
		var random_x = randf_range(area_location.x - area_size.x, area_location.x + area_size.x)
		var random_z = randf_range(area_location.z - area_size.z, area_location.z + area_size.z)
		var y = area_location.y
		var candidate_position = Vector3(random_x, y, random_z)
		
		# Evaluating whether the picked position isn't too close to someone already
		if is_position_free(candidate_position):
			return candidate_position

func is_position_free(pos : Vector3) -> bool:
	for p in occupied_positions:
		if p.distance_to(pos) < 0.3: # width of NPC + some space
			# sorry, someone is already staying there
			return false
	# we went through everything, and seems like nobody is standing there (yet)!
	return true
	


func _on_spawn_npc_pressed() -> void:
	spawn_npc()
