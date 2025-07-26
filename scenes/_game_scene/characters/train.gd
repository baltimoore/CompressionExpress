extends StaticBody3D

@export var speed = 15
@export var bounding_box : CollisionShape3D

var path_follow : PathFollow3D

func _physics_process(delta):
	if path_follow && not path_follow.progress == 100:
		_move_along_path(delta)

#### ### ### ### ### ### ###
##  Train navigation functions
#### ### ### ### ### ### ###
func _move_along_path(delta):
	path_follow.progress += speed * delta
	global_position = path_follow.global_position
	
	# Check if we reached the end of the path
	if path_follow.progress_ratio >= 0.95:
		path_follow.progress_ratio = 1.0
