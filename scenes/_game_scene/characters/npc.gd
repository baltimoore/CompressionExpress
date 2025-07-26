extends CharacterBody3D

@export var speed = 5
@export var bounding_box : CollisionShape3D
@onready var nav : NavigationAgent3D = $NavigationAgent3D

# pathfinding variables
var path_follow : PathFollow3D
var in_waiting_area = false
var waiting_position_distance: Vector3
var at_position = false

# stuckage variables
const STUCK_THRESHOLD_TIME := 0.5  # seconds
const STUCK_DISTANCE_EPSILON := 0.05  # minimum distance considered "movement"
var last_position: Vector3 = Vector3.ZERO
var stuck_timer := 0.0

# bumping variables
var last_push_time := 0.0
const PUSH_COOLDOWN := 0.1

signal reached_waiting_area(npc)
signal reached_waiting_position(npc_position)

func _physics_process(delta):
	# Just spawned, moving along the path
	if path_follow && not in_waiting_area:
		_move_along_entry_path(delta)
	# Entered waiting area, now going to waiting spot
	elif in_waiting_area && waiting_position_distance != Vector3.ZERO:
		_move_to_waiting_spot(delta)
	# Clamp position so NPC stays inside waiting area
	elif bounding_box:
		global_position = _bind_position_within_bounding_box(global_position)
	
	# NPC has finalized their position; time to be shuffled around
	last_push_time = max(0.0, last_push_time - delta)
	
	move_and_slide()
	velocity = Vector3.ZERO

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

func _bind_position_within_bounding_box(pos: Vector3) -> Vector3:
	var shape = bounding_box.shape
	var half_size = shape.size * 0.5
	var center = bounding_box.global_transform.origin
	
	# Clamp each axis inside the box bounds
	var clamped_x = clamp(pos.x, center.x - half_size.x, center.x + half_size.x)
	var clamped_y = clamp(pos.y, center.y - half_size.y, center.y + half_size.y)
	var clamped_z = clamp(pos.z, center.z - half_size.z, center.z + half_size.z)
	
	return Vector3(clamped_x, clamped_y, clamped_z)


# pushing movement logic
func _on_personal_space_body_entered(body):
	if body != self and body is CharacterBody3D and last_push_time <= 0:
		var push_dir = (global_position - body.global_position).normalized()
		velocity = push_dir * speed * 1.5
		last_push_time = PUSH_COOLDOWN
