extends CharacterBody3D

@export var speed = 5
@export var bounding_box : CollisionShape3D
@onready var nav : NavigationAgent3D = $NavigationAgent3D

# pathfinding variables
var path_follow : PathFollow3D
var location_vector: Vector3

# stuckage variables
const STUCK_THRESHOLD_TIME := 0.5  # seconds
const STUCK_DISTANCE_EPSILON := 0.05  # minimum distance considered "movement"
var last_position: Vector3 = Vector3.ZERO
var stuck_timer := 0.0

# bumping variables
var last_push_time := 0.0
const PUSH_COOLDOWN := 0.1

# dragging variables
var is_dragged := false

signal npc_path_completed(npc)
signal npc_arrived_at_location(npc_position)
signal npc_moved(npc_position)

func _physics_process(delta):
	# While being dragged, don't move automatically
	if is_dragged:
		velocity = Vector3.ZERO
		pass
	# Just spawned, moving along the path
	elif path_follow && not path_follow.progress == 100:
		_move_along_path(delta)
	# Entered waiting area, now going to waiting spot
	elif path_follow == null && location_vector != Vector3.ZERO:
		_move_to_location(delta)
	
	move_and_slide()
	velocity = Vector3.ZERO
	
	# NPC has finalized their position; time to be shuffled around
	last_push_time = max(0.0, last_push_time - delta)
	
	# Clamp position so NPC stays inside waiting area
	if bounding_box:
		global_position = _bind_position_within_bounding_box()

#### ### ### ### ### ### ###
##  NPC navigation functions
#### ### ### ### ### ### ###

# Function to handle path following until NPC reaches the waiting area
func _move_along_path(delta):
	path_follow.progress += speed * delta
	global_position = path_follow.global_position
	
	# Check if we reached the end of the path
	if path_follow.progress_ratio >= 0.95:
		path_follow.progress_ratio = 1.0
		emit_signal("npc_path_completed", self)

# Function to handle movement toward the assigned waiting position
func _move_to_location(delta):
	# We do not move npc around if they are being dragged
	if is_dragged:
		return
		
	# try moving NPC
	var dir = (location_vector - global_position).normalized()
	velocity = dir * speed
	
	# if NPC is close enough, he's close enough
	if global_position.distance_to(location_vector) < 0.5:
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
	location_vector = Vector3.ZERO  
	velocity = Vector3.ZERO
	emit_signal("npc_arrived_at_location", self.global_position)

# NPC containment within area
func _bind_position_within_bounding_box() -> Vector3:
	var shape = bounding_box.shape
	var half_size = shape.size * 0.5
	var center = bounding_box.global_transform.origin
	
	# Clamp each axis inside the box bounds
	var clamped_x = clamp(global_position.x, center.x - half_size.x, center.x + half_size.x)
	var clamped_y = clamp(global_position.y, center.y - half_size.y, center.y + half_size.y)
	var clamped_z = clamp(global_position.z, center.z - half_size.z, center.z + half_size.z)
	
	return Vector3(clamped_x, clamped_y, clamped_z)

#### ### ### ### ### ### ###
##  NPC shoving logic
#### ### ### ### ### ### ###
func _on_personal_space_body_entered(body):
	if body != self and body is CharacterBody3D and last_push_time <= 0:
		var push_dir = (global_position - body.global_position).normalized()
		velocity = push_dir * speed * 1.5
		last_push_time = PUSH_COOLDOWN

#### ### ### ### ### ### ###
##  NPC draggability functions
#### ### ### ### ### ### ###
func start_drag():
	is_dragged = true
	velocity = Vector3.ZERO
	# Optionally, disable NavigationAgent3D path following to stop movement
	nav.set_enabled(false)

func stop_drag():
	is_dragged = false
	nav.set_enabled(true)
	emit_signal("npc_moved", global_position)
