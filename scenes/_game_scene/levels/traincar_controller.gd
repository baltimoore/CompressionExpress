extends Node3D

@onready var train_spawner = $VoidEnter
@onready var train_despawner = $VoidExit

var traincar_scene = preload("res://assets/modular_train_pack/train.tscn")
var current_train_car: Node3D = null

func _on_train_spawn_triggered() -> void:
	var train = traincar_scene.instantiate()
	train.global_transform.origin = train_spawner.global_transform.origin - Vector3(5, 0, 0) # adjust as needed
	# create the train within the traincar node
	add_child(train)
	current_train_car = train

func _on_void_exit_body_exited(body: Node3D) -> void:
	if current_train_car && body == current_train_car:
		current_train_car.queue_free()
		current_train_car = null
