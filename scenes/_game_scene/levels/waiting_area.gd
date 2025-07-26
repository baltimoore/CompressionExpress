extends Area3D

@onready var collision_shape := $CollisionShape3D

var occupied_positions : Array[Vector3] = []
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
			return candidate_position
	
	# fallback to center of wait area, if no randomized guesses were free
	return area_location


func is_position_free(pos: Vector3) -> bool:
	for p in occupied_positions: # width of NPC collision box + some space
		# sorry, someone is already staying there
		return false
	# we went through everything, and seems like nobody is standing there (yet)!
	return true
