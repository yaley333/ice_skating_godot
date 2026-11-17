extends Node3D

@export var lifetime: = 6.0

func _ready():
	await get_tree().create_timer(lifetime).timeout
	queue_free()
