extends Node2D

export(String) var color

onready var move_tween = $move_tween

func _ready() -> void:
	pass


func move(target) -> void:
	move_tween.interpolate_property(self, "position", position, target, .3,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	move_tween.start()
