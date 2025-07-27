extends Node3D

var level_state : LevelState
const MAX_SEARCH_ATTEMPTS = 20

# NPC nodes
@onready var npc_waiting_area = $NPC/WaitingArea
# Timer nodes
@onready var npc_timer = $Timers/NpcTimer
@onready var train_timer = $Timers/TrainTimer


#### ### ### ### ### ### ###
##  GAME STATE SETUP
#### ### ### ### ### ### ###

func _ready() -> void:
	level_state = GameState.get_level_state(scene_file_path)
	$NPC.setup(level_state.npc_occupied_positions)

	%Traincar.update_fed_npcs.connect(_on_train_passed)
	_update_humans_fed()
	_start_random_npc_timer()
	_start_random_train_timer()



#### ### ### ### ### ### ###
##  CLOCK METHODS
#### ### ### ### ### ### ###

func _start_random_npc_timer():
	var wait = randf_range(2.0, 5.0)  # Between 2 and 5 seconds
	npc_timer.wait_time = wait
	npc_timer.start()

func _start_random_train_timer():
	var wait = randf_range(8.0, 12.0)  # Between 8 and 12 seconds
	train_timer.wait_time = wait
	train_timer.start()

func _on_npc_timer_timeout():
	_spawn_npc()
	_start_random_npc_timer()  # Restart with new random interval

func _on_train_timer_timeout():
	# if there is a train already, we are not replacing it with a new one
	if $Traincar.current_train_car and $Traincar.current_train_car.current_path_progress() < 0.8:
		_start_random_train_timer()
		return
	
	_spawn_train()
	_start_random_train_timer()

func _spawn_npc():
	var new_npc = $NPC.spawn_npc()
	# assign the NPC scene signals to activate the main level manager's functions
	new_npc.npc_arrived_at_location.connect(_on_npc_location_change)
	new_npc.npc_moved.connect(_on_npc_location_change)

func _spawn_train():
	$Traincar.spawn_traincar()
	# No need to register the update_fed_npcs signal,
	# since it emits from the train_controller, not train itself



#### ### ### ### ### ### ###
##  GAMESTATE UPDATES
#### ### ### ### ### ### ###

func _on_npc_location_change(_npc_location) -> void:
	level_state.npc_occupied_positions = npc_waiting_area.all_occuped_positions()

func _on_train_passed(amount_fed : int) -> void:
	level_state.npc_occupied_positions = npc_waiting_area.all_occuped_positions()
	level_state.npcs_fed_amount += amount_fed
	_update_humans_fed()



#### ### ### ### ### ### ###
##  DEBUG UI INTERFACE
#### ### ### ### ### ### ###

func _on_spawn_npc_pressed() -> void:
	_spawn_npc()

func _on_spawn_traincar_pressed() -> void:
	_spawn_train()

func _on_void_exit_body_exited(body: Node3D) -> void:
	print("void exited")
	%Traincar.destroy_traincar(body)

func _on_despawn_traincar_pressed() -> void:
	print("force despawn traincar")
	var train = %Traincar.current_train_car
	%Traincar.destroy_traincar(train)



#### ### ### ### ### ### ###
##  GAMEPLAY UI INTERFACE
#### ### ### ### ### ### ###

func _update_humans_fed():
	print("updating label")
	$GameplayUI/PanelContainer/HumansFed.text = "Humans fed: %d" % level_state.npcs_fed_amount
