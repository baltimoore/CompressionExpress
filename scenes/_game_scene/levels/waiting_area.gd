extends Area3D

@onready var collision_shape := $Container

signal no_free_spots()
signal has_free_spots()

const MAX_SEARCH_ATTEMPTS := 20

func pick_random_free_spot() -> Vector3:
	var area_location = collision_shape.global_transform.origin
	var area_size = collision_shape.shape.size / 2.0
	
	for i in range (MAX_SEARCH_ATTEMPTS):
		var random_x = randf_range(area_location.x - area_size.x, area_location.x + area_size.x)
		var random_z = randf_range(area_location.z - area_size.z, area_location.z + area_size.z)
		var y = area_location.y
		var candidate_position = Vector3(random_x, y, random_z)
		
		# Evaluating whether the picked position isn't too close to someone already
		if is_position_free(candidate_position):
			has_free_spots.emit()
			return candidate_position
	
	# fallback to center of wait area, if no randomized guesses were free
	no_free_spots.emit()
	return area_location

func is_position_free(pos: Vector3) -> bool:
	for child in all_occuped_positions():
		if child.distance_to(pos) < 1.25: # NPC personal space radius
			# sorry, someone is already staying there
			return false
	# we went through everything, and seems like nobody is standing there (yet)!
	return true

func all_occuped_positions() -> Array[Vector3]:
	var positions : Array[Vector3] = []
	for child in self.get_children():
		# We're only collecting the positions of NPCs
		if child is not CharacterBody3D:
			continue
		
		positions.append(child.global_position)
	
	return positions
