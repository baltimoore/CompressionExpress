extends Node3D

@onready var camera = %PlayerCamera
@onready var waiting_area = $"WaitingArea"
@onready var dragging_area = $"DraggingArea"

const LAYER_MASK_NPC = 1  #Assuming draggable NPCs are in layer 2
const LAYER_MASK_DRAGGING_AREA = 4  #Assuming dragging area is in layer 4

var held_npc: CharacterBody3D = null

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
	return space_state.intersect_ray(npc_query)

func _attempt_pick_or_drag(mouse_pos: Vector2):
	var npc_raycast = _raycast_to_npc(mouse_pos)
	print("NPC query response", npc_raycast)
	
	if npc_raycast.has("collider") and npc_raycast.collider.is_in_group("draggable_npc"):
		held_npc = npc_raycast.collider
		held_npc.reparent(dragging_area)
		_update_position(mouse_pos)

func _update_position(mouse_pos: Vector2):
	var npc_raycast = _raycast_to_npc(mouse_pos)
	
	if npc_raycast.has("position"):
		var new_location = npc_raycast.position
		new_location.y = dragging_area.global_position.y
		held_npc.global_position = new_location

func _release_npc():
	held_npc.reparent(waiting_area)
	held_npc.global_position.y = waiting_area.global_position.y
	held_npc = null
