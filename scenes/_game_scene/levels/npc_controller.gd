extends Node3D

var npc_scene = preload("res://scenes/_game_scene/characters/NPC.tscn")

@onready var camera = %PlayerCamera
@onready var entrance_path = $Navigation/EntrancePath
@onready var waiting_area = $WaitingArea
@onready var dragging_area = $DraggingArea

const LAYER_MASK_NPC = 2  #Assuming draggable NPCs are in layer 2
const LAYER_MASK_DRAGGING_AREA = 4  #Assuming dragging area is in layer 4

var held_npc: CharacterBody3D = null

func setup(npc_locations : Array[Vector3]) -> void:
	# Populate the waiting area with NPCs
	for pos : Vector3 in npc_locations:
		var npc = npc_scene.instantiate()

		npc.add_to_group("draggable_npc")
		npc.bounding_box = waiting_area.find_child("Container", false)
		waiting_area.add_child(npc)
		npc.global_position = pos



#### ### ### ### ### ### ###
##  NPC SCENE INITIALIZATION
#### ### ### ### ### ### ###

func spawn_npc() -> CharacterBody3D:
	print("spawning new npc")
	var path_follow = PathFollow3D.new()
	entrance_path.add_child(path_follow)
	path_follow.progress = 0
	
	var npc = npc_scene.instantiate()
	npc.path_follow = path_follow
	add_child(npc)
	
	npc.npc_path_completed.connect(_on_entrance_path_completed)
	return npc

func _on_entrance_path_completed(npc):
	# gotta remove the follow path, otherwise the movement loops
	npc.path_follow = null
	npc.add_to_group("draggable_npc")
	npc.reparent(waiting_area, true)
	npc.bounding_box = waiting_area.find_child("Container", false)
	
	var free_spot = waiting_area.pick_random_free_spot()
	#print("Located free target position: ", free_spot)
	npc.location_vector = free_spot



#### ### ### ### ### ### ###
##  NPC USER CONTROL
#### ### ### ### ### ### ###

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_attempt_pick_or_drag(event.position)
			elif held_npc != null:
				_release_npc()
	elif event is InputEventMouseMotion and held_npc != null:
		_update_position(event.position)

func _raycast_to_npc(mouse_pos : Vector2):
	# create a ray to grab the NPC
	var space_state = get_world_3d().direct_space_state
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
	
	var npc_query = PhysicsRayQueryParameters3D.new()
	npc_query.from = from
	npc_query.to = to
	npc_query.collision_mask = LAYER_MASK_NPC
	
	# Check if the ray pierces an NPC
	var npc_response = space_state.intersect_ray(npc_query)
	if npc_response.has("collider") and npc_response.collider.is_in_group("draggable_npc"):
		# print("NPC query response", npc_response)
		return npc_response
	else:
		return null

func _attempt_pick_or_drag(mouse_pos: Vector2):
	var npc_raycast = _raycast_to_npc(mouse_pos)
	
	if npc_raycast:
		held_npc = npc_raycast.collider
		held_npc.reparent(dragging_area)
		held_npc.bounding_box = dragging_area.find_child("Container", false)
		_update_position(mouse_pos)

func _update_position(mouse_pos: Vector2):
	var npc_raycast = _raycast_to_npc(mouse_pos)
	
	if npc_raycast:
		var new_location = npc_raycast.position
		held_npc.global_position = new_location

func _release_npc():
	# check if there is a train loaded
	if %Traincar.current_train_car:
		# check if the npc is above the traincar container
		var train_compartment: Area3D = %Traincar.current_train_car.get_node("TraincarArea")
		var train_compartment_container : CollisionShape3D = train_compartment.find_child("Container")

		var npc_relative_to_train_compartment = train_compartment_container.to_local(held_npc.global_position) 
		var within_x : bool = abs(npc_relative_to_train_compartment.x) <= train_compartment_container.shape.size.x / 2
		
		if held_npc.global_position.z > 11 and within_x: # z11 is the start of rail tracks, which is good enough
			print("npc is fed to the train")
			held_npc.reparent(train_compartment)
			held_npc.bounding_box = train_compartment_container
			return
	
	# by default, throw NPC back to the waiting area
	held_npc.reparent(waiting_area)
	held_npc.bounding_box = waiting_area.find_child("Container", false)
	held_npc = null
