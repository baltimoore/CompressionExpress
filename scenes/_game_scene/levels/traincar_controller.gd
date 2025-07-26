extends Node3D

@onready var train_spawner = $VoidEnter
@onready var train_despawner = $VoidExit

var traincar_scene = preload("uid://b72fquktom7tn")
var current_train_car : StaticBody3D = null



#### ### ### ### ### ### ###
##  TRAINCAR CONSTRUCTOR & DESTRUCTOR
#### ### ### ### ### ### ###

func spawn_traincar() -> void:
	# if a traincar already exists, delete it
	destroy_traincar(current_train_car)
	
	var path_follow = PathFollow3D.new()
	$Path3D.add_child(path_follow)
	path_follow.progress = 0
	
	# create the train within the traincar node
	var train = traincar_scene.instantiate()
	train.path_follow = path_follow
	self.add_child(train)
	current_train_car = train
	print("spawned traincar: ", train)
	# await their arrival at their waiting spot
	current_train_car.connect("train_path_completed", Callable(self, "_on_train_path_completed"))

func _on_train_path_completed(train : Node3D):
	destroy_traincar(train)

func destroy_traincar(body: Node3D) -> void:
	if current_train_car && body == current_train_car:
		print("destroying traincar: ", body)
		current_train_car.queue_free()
		current_train_car = null
