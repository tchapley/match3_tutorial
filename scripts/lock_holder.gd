extends Node2D

signal remove_lock

var lock_pieces := []
var width = 8
var height = 10
var lock = preload("res://scenes/licorice.tscn")

func make_2d_array() -> Array:
	var array := []
	for i in width:
		array.append([])
		for y in height:
			array[i].append(null)
	return array


func _on_grid_make_lock(board_position: Vector2) -> void:
	if lock_pieces.size() == 0:
		lock_pieces = make_2d_array()
	var current = lock.instance()
	add_child(current)
	current.position = Vector2(board_position.x * 64 + 64, 800 - board_position.y * 64)
	lock_pieces[board_position.x][board_position.y] = current


func _on_grid_damage_lock(board_position: Vector2) -> void:
	if lock_pieces[board_position.x][board_position.y] != null:
		lock_pieces[board_position.x][board_position.y].take_damage(1)
		if lock_pieces[board_position.x][board_position.y].health <= 0:
			lock_pieces[board_position.x][board_position.y].queue_free()
			lock_pieces[board_position.x][board_position.y] == null
			emit_signal("remove_lock", board_position)
