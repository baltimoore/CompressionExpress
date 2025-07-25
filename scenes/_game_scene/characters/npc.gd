extends CharacterBody3D

@export var speed = 5

var path_follow : PathFollow3D
var in_waiting_area = false
var waiting_position_distance: Vector3
var at_position = false

# stuckage variables
const STUCK_THRESHOLD_TIME := 0.5  # seconds
const STUCK_DISTANCE_EPSILON := 0.01  # minimum distance considered "movement"
var last_position: Vector3 = Vector3.ZERO
var stuck_timer := 0.0

signal reached_waiting_area(npc)
signal reached_waiting_position(npc_position)

func _physics_process(delta):
	# Just spawned, moving along the path
	if path_follow && not in_waiting_area:
		_move_along_entry_path(delta)
	# Entered waiting area, now going to waiting spot
	elif in_waiting_area && waiting_position_distance != Vector3.ZERO:
		_move_to_waiting_spot(delta)

# Function to handle path following until NPC reaches the waiting area
func _move_along_entry_path(delta):
	path_follow.progress += speed * delta
	global_position = path_follow.global_position
	
	# Check if we reached the end of the path
	if path_follow.progress_ratio >= 0.95:
		path_follow.progress_ratio = 1.0
		in_waiting_area = true
		emit_signal("reached_waiting_area", self)

# Function to handle movement toward the assigned waiting position
func _move_to_waiting_spot(delta):
	var dir = (waiting_position_distance - global_position).normalized()
	
	# try moving NPC
	velocity = dir * speed
	move_and_slide()
	
	# if NPC is close enough, he's close enough
	if global_position.distance_to(waiting_position_distance) < 0.5:
		_arrived_at_waiting_spot()
	# if NPC hasn't moved from his current spot at all,
	# let's make the current spot his permanent resting spot
	elif global_position.distance_to(last_position) < STUCK_DISTANCE_EPSILON:
		stuck_timer += delta
		if stuck_timer >= STUCK_THRESHOLD_TIME:
			print("NPC seems stuck, stopping early.")
			_arrived_at_waiting_spot()
	
	# always update the current position at the end
	last_position = global_position  

# NPC at final position and emits signal
func _arrived_at_waiting_spot():
	# Stop movement
	waiting_position_distance = Vector3.ZERO  
	velocity = Vector3.ZERO
	emit_signal("reached_waiting_position", self.global_position)
