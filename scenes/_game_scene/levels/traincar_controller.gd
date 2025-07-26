extends Node3D

var traincar_scene = preload("uid://b72fquktom7tn")
var current_train_car : StaticBody3D = null

signal update_fed_npcs(amount : int)



#### ### ### ### ### ### ###
##  TRAINCAR CONSTRUCTOR & DESTRUCTOR
#### ### ### ### ### ### ###

func spawn_traincar() -> StaticBody3D:
	# if a traincar already exists, delete it
	destroy_traincar(current_train_car)
	
	var path_follow = PathFollow3D.new()
	$Path3D.add_child(path_follow)
	path_follow.progress = 0
	
	# create the train within the traincar node
	var train = traincar_scene.instantiate()
	train.path_follow = path_follow
	current_train_car = train
	self.add_child(train)
	print("spawned traincar: ", train)

	# await their arrival at their waiting spot
	current_train_car.train_path_completed.connect(destroy_traincar)
	return current_train_car

func destroy_traincar(body: Node3D) -> void:
	if current_train_car && body == current_train_car:
		print("destroying traincar: ", body)
		# -1, because of the container
		var npc_count : int = current_train_car.find_child("TraincarArea").get_child_count() - 1
		print("amount of NPCs just fed: ", npc_count)
		current_train_car.queue_free()
		current_train_car = null

		emit_signal("update_fed_npcs", npc_count)
