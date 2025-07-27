extends Node3D

var level_state : LevelState

# NPC nodes
@onready var npc_waiting_area = $NPC/WaitingArea
# Timer nodes
@onready var npc_timer = $Timers/NpcTimer
@onready var train_timer = $Timers/TrainTimer
@onready var processing_timer = $Timers/HumanProcessingTimer
var npc_timer_range = Vector2(0.5, 5.0)
var train_timer_range = Vector2(10.0, 20.0)
var decreased_npc_spawns : bool = false

signal level_lost



#### ### ### ### ### ### ###
##  GAME STATE SETUP
#### ### ### ### ### ### ###

func _ready() -> void:
	# Gamestate load
	level_state = GameState.get_level_state(scene_file_path)
	$NPC.setup(level_state.npc_occupied_positions)
	_update_humans_fed()
	# Signal connections
	%Traincar.update_fed_npcs.connect(_on_train_passed)
	npc_waiting_area.no_free_spots.connect(func() : _toggle_free_spots(false))
	npc_waiting_area.has_free_spots.connect(func() : _toggle_free_spots(true))
	# Gameplay initialization
	_start_random_npc_timer()
	_start_random_train_timer()



#### ### ### ### ### ### ###
##  CLOCK METHODS
#### ### ### ### ### ### ###

func _start_random_npc_timer():
	# gotta be careful we don't go into negatives
	npc_timer_range = Vector2(
		maxf(1, npc_timer_range.x),
		maxf(3.0, npc_timer_range.y)
	)
	
	var wait = randf_range(npc_timer_range.x, npc_timer_range.y)
	# if we are in the middle of processing, people stay away
	if decreased_npc_spawns:
		wait *= 3.0
	
	print("NPC timer: ", npc_timer_range)
	npc_timer.wait_time = wait
	npc_timer.start()

func _start_random_train_timer():
	var wait = randf_range(train_timer_range.x, train_timer_range.y)
	train_timer.wait_time = wait
	train_timer.start()

func _on_npc_timer_timeout():
	_spawn_npc()
	_start_random_npc_timer()  # Restart with new random interval

func _on_train_timer_timeout():
	# if there is a train already, we are not replacing it with a new one
	if $Traincar.current_train_car and $Traincar.current_train_car.current_path_progress() < 0.8:
		train_timer_range += Vector2(2.0, 1.0)
		_start_random_train_timer()
		return
	
	_spawn_train()
	_start_random_train_timer()

func _spawn_npc():
	var new_npc = $NPC.spawn_npc()
	# the longer in game you go, the more NPCs spawn
	npc_timer_range -= Vector2(0.01, 0.01)
	# assign the NPC scene signals to activate the main level manager's functions
	new_npc.npc_arrived_at_location.connect(_on_npc_location_change)
	new_npc.npc_moved.connect(_on_npc_location_change)
	# new_npc.npc_stuck.connect(func() : _toggle_free_spots(false))

func _spawn_train():
	$Traincar.spawn_traincar()
	# the more in-game you go, the longer the interval between trains
	train_timer_range += Vector2(0.05, 0.05)
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
	_play_processing_audio(amount_fed)
	_update_humans_fed()
	# people being processed frightens 
	npc_timer_range += Vector2(amount_fed / 15.0, amount_fed / 15.0)

func _toggle_free_spots(has_free_spots : bool) -> void:
	if has_free_spots:
		level_state.overflow = 0
		return
	
	level_state.overflow += 1
	if level_state.overflow > 3:
		level_lost.emit()



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
	$GameplayUI/PanelContainer/HumansFed.text = "Humans compressed: %d" % level_state.npcs_fed_amount



#### ### ### ### ### ### ###
##  GAMEPLAY AUDIO INTERFACE
#### ### ### ### ### ### ###

func _play_processing_audio(amount_fed : int):
	# if nobody was fed, don't play anything
	if amount_fed <= 0:
		return
	# humans don't like sounds
	decreased_npc_spawns = true
	$Audio/HumanProcessing/BoneAudioPlayer.play()
	$Audio/HumanProcessing/FleshAudioPlayer.play()
	processing_timer.wait_time = amount_fed * 1.5
	processing_timer.start()

func _on_human_processing_timer_timeout() -> void:
	$Audio/HumanProcessing/BoneAudioPlayer.stop()
	$Audio/HumanProcessing/FleshAudioPlayer.stop()
	decreased_npc_spawns = false
