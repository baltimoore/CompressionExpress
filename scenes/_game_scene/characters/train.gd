extends Node3D

@export var speed = 10.0
@export var bounding_box : CollisionShape3D

var path_follow : PathFollow3D

const speed_slow = 3.0
const speed_fast = 15.0
var current_speed = speed

signal train_path_completed(train)

func _physics_process(delta):
	if path_follow && path_follow.progress_ratio < 0.95:
		_move_along_path(delta)

#### ### ### ### ### ### ###
##  Train navigation functions
#### ### ### ### ### ### ###

func _move_along_path(delta):
	var progress := path_follow.progress_ratio
	
	var target_speed : float
	# Slow down around the middle of the path (platform zone)
	if progress >= 0.35 and progress <= 0.6:
		target_speed = speed_slow
	# increase our speed back up as we leave
	else:
		target_speed = speed_fast
	
	current_speed = lerp(current_speed, target_speed, delta * 7.0)
	path_follow.progress += current_speed * delta
	global_position = path_follow.global_position
	
	# Check if we reached the end of the path
	if progress >= 0.95:
		path_follow.progress_ratio = 1.0
		train_path_completed.emit(self)

func current_path_progress() -> float:
	return path_follow.progress_ratio
