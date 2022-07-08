extends Node2D

export(String) var color
export(Texture) var row_texture
export(Texture) var column_texture
export(Texture) var adjacent_texture

var matched := false
var is_row_bomb = false
var is_column_bomb = false
var is_adjacent_bomb = false

onready var move_tween = $move_tween

func move(target) -> void:
	move_tween.interpolate_property(self, "position", position, target, 0.3,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	move_tween.start()


func make_column_bomb():
	is_column_bomb = true
	$sprite.texture = column_texture
	$sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)


func make_row_bomb():
	is_row_bomb = true
	$sprite.texture = row_texture
	$sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)


func make_adjacent_bomb():
	is_adjacent_bomb = true
	$sprite.texture = adjacent_texture
	$sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)


func dim() -> void:
	$sprite.modulate = Color(1.0, 1.0, 1.0, 0.3)
