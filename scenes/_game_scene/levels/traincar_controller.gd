extends Node3D

@onready var train_spawner = $VoidEnter
@onready var train_despawner = $VoidExit

var traincar_scene = preload("uid://b72fquktom7tn")
var current_train_car : Node3D = null
var path_follow : PathFollow3D



#### ### ### ### ### ### ###
##  TRAINCAR CONSTRUCTOR & DESTRUCTOR
#### ### ### ### ### ### ###

func spawn_traincar() -> void:
	print("spawning traincar")
	var path_follow = PathFollow3D.new()
	$Path3D.add_child(path_follow)
	path_follow.progress = 0
	
	# create the train within the traincar node
	var train = traincar_scene.instantiate()
	train.path_follow = path_follow
	self.add_child(train)
	current_train_car = train

func destroy_traincar(body: Node3D) -> void:
	print("destroying traincar")
	if current_train_car && body == current_train_car:
		current_train_car.queue_free()
		current_train_car = null
