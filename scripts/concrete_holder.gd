extends Node2D

signal remove_concrete

var concrete_pieces := []
var width = 8
var height = 10
var concrete = preload("res://scenes/concrete.tscn")

func make_2d_array() -> Array:
	var array := []
	for i in width:
		array.append([])
		for y in height:
			array[i].append(null)
	return array


func _on_grid_make_concrete(board_position: Vector2) -> void:
	if concrete_pieces.size() == 0:
		concrete_pieces = make_2d_array()
	var current = concrete.instance()
	add_child(current)
	current.position = Vector2(board_position.x * 64 + 64, 800 - board_position.y * 64)
	concrete_pieces[board_position.x][board_position.y] = current


func _on_grid_damage_concrete(board_position: Vector2) -> void:
	if concrete_pieces[board_position.x][board_position.y] != null and is_instance_valid(concrete_pieces[board_position.x][board_position.y]):
		concrete_pieces[board_position.x][board_position.y].take_damage(1)
		if concrete_pieces[board_position.x][board_position.y].health <= 0:
			concrete_pieces[board_position.x][board_position.y].queue_free()
			concrete_pieces[board_position.x][board_position.y] == null
			emit_signal("remove_concrete", board_position)
