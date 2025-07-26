extends Node3D

var level_state : LevelState
const MAX_SEARCH_ATTEMPTS = 20

# NPC nodes
var npc_scene = preload("res://scenes/_game_scene/characters/NPC.tscn")
@onready var npc_entrance_path = $NPC/Navigation/EntrancePath
@onready var npc_waiting_area = $NPC/WaitingArea
@onready var npc_dragging_area = $NPC/DraggingArea



#### ### ### ### ### ### ###
##  GAME STATE SETUP
#### ### ### ### ### ### ###
func _ready() -> void:
	level_state = GameState.get_level_state(scene_file_path)
	_populate_area_with_npcs(level_state.npc_occupied_positions)
	%Traincar.update_fed_npcs.connect(_on_train_passed)

func _populate_area_with_npcs(npc_locations) -> void:
	for pos : Vector3 in npc_locations:
		var npc = npc_scene.instantiate()
		
		npc.add_to_group("draggable_npc")
		npc.bounding_box = npc_waiting_area.find_child("Container", false)
		npc_waiting_area.add_child(npc)
		npc.global_position = pos



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
	
	npc.npc_path_completed.connect(_on_entrance_path_completed)
	npc.npc_arrived_at_location.connect(_on_npc_location_change)
	npc.npc_moved.connect(_on_npc_location_change)

func _on_entrance_path_completed(npc):
	# gotta remove the follow path, otherwise the movement loops
	npc.path_follow = null
	npc.add_to_group("draggable_npc")
	npc.reparent(npc_waiting_area, true)
	npc.bounding_box = npc_waiting_area.find_child("Container", false)
	
	var free_spot = npc_waiting_area.pick_random_free_spot()
	print("Located free target position: ", free_spot)
	npc.location_vector = free_spot



#### ### ### ### ### ### ###
##  GAMESTATE UPDATES
#### ### ### ### ### ### ###
func _on_npc_location_change(_npc_location) -> void:
	level_state.npc_occupied_positions = npc_waiting_area.all_occuped_positions()

func _on_train_passed(amount_fed : int) -> void:
	level_state.npc_occupied_positions = npc_waiting_area.all_occuped_positions()
	level_state.npcs_fed_amount += amount_fed



#### ### ### ### ### ### ###
##  DEBUG UI INTERFACE
#### ### ### ### ### ### ###
func _on_spawn_npc_pressed() -> void:
	spawn_npc()

func _on_spawn_traincar_pressed() -> void:
	%Traincar.spawn_traincar()

func _on_void_exit_body_exited(body: Node3D) -> void:
	print("void exited")
	%Traincar.destroy_traincar(body)

func _on_despawn_traincar_pressed() -> void:
	print("force despawn traincar")
	var train = %Traincar.current_train_car
	%Traincar.destroy_traincar(train)
