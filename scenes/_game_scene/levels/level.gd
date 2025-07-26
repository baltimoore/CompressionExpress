extends Node3D

var npc_scene = preload("res://scenes/_game_scene/characters/NPC.tscn")
var occupied_positions : Array[Vector3] = []
const MAX_SEARCH_ATTEMPTS = 20

# NPC nodes
@onready var npc_entrance_path = $NPC/Navigation/EntrancePath
@onready var npc_waiting_area = $NPC/WaitingArea

#### ### ### ### ### ### ###
##  NPC CONTROLLING METHODS
#### ### ### ### ### ### ###
func spawn_npc():
	print("spawing npc")
	var path_follow = PathFollow3D.new()
	npc_entrance_path.add_child(path_follow)
	path_follow.progress = 0
	
	var npc = npc_scene.instantiate()
	npc.path_follow = path_follow
	$NPC.add_child(npc)
	
	npc.connect("npc_path_completed", Callable(self, "_on_entrance_path_completed"))

func _on_entrance_path_completed(npc):
	# gotta remove the follow path, otherwise the movement loops
	npc.path_follow = null
	npc.add_to_group("draggable_npc")
	npc.reparent(npc_waiting_area, true)
	
	var free_spot = npc_waiting_area.pick_random_free_spot()
	occupied_positions.append(free_spot)
	print("Located free target position: ", free_spot)
	npc.location_vector = free_spot
	# await their arrival at their waiting spot
	npc.connect("npc_arrived_at_location", Callable(self, "_on_reached_waiting_position"))

func _on_reached_waiting_position(npc_position):
	# do we even need this?
	pass



#### ### ### ### ### ### ###
##  TRAINCAR CONTROLLING METHODS
#### ### ### ### ### ### ###
func spawn_traincar():
	pass



#### ### ### ### ### ### ###
##  DEBUG UI INTERFACE
#### ### ### ### ### ### ###
func _on_spawn_npc_pressed() -> void:
	spawn_npc()

func _on_spawn_traincar_pressed() -> void:
	spawn_traincar()
