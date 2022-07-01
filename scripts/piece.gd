extends Node2D

export(String) var color

var matched := false

onready var move_tween = $move_tween

func move(target) -> void:
	move_tween.interpolate_property(self, "position", position, target, 0.3,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	move_tween.start()


func dim() -> void:
	$sprite.modulate = Color(1.0, 1.0, 1.0, 0.3)
