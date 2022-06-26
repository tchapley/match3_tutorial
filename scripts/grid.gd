extends Node2D

export(int) var width
export(int) var height
export(int) var x_start
export(int) var y_start
export(int) var offset

var all_pieces := []
var first_touch := Vector2.ZERO
var final_touch := Vector2.ZERO
var possible_pieces := [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
]


func _ready() -> void:
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()


func _process(_delta: float) -> void:
	touch_input()


func make_2d_array() -> Array:
	var array := []
	for i in width:
		array.append([])
		for y in height:
			array[i].append(null)
	return array


func grid_to_pixel(column: int, row: int) -> Vector2:
	var new_x: int = x_start + offset * column
	var new_y: int = y_start + -offset * row
	return Vector2(new_x, new_y)


func pixel_to_grid(x: float, y: float) -> Vector2:
	var new_x = round((x - x_start) / offset)
	var new_y = round((y - y_start) / -offset)
	return Vector2(new_x, new_y)


func spawn_pieces() -> void:
	for i in width:
		for j in height:
			var rand: int = floor(rand_range(0, possible_pieces.size()))
			var piece: Node2D = possible_pieces[rand].instance()
			var loops := 0
			while match_at(i, j, piece.color) and loops < 100:
				loops += 1
				rand = floor(rand_range(0, possible_pieces.size()))
				piece = possible_pieces[rand].instance()
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			all_pieces[i][j] = piece


func match_at(col: int, row: int, color: String) -> bool:
	if col > 1:
		if all_pieces[col - 1][row] != null and all_pieces[col - 2][row] != null:
				if all_pieces[col - 1][row].color == color and all_pieces[col - 2][row].color == color:
					return true
	if row > 1:
		if all_pieces[col][row - 1] != null and all_pieces[col][row - 2] != null:
				if all_pieces[col][row - 1].color == color and all_pieces[col][row - 2].color == color:
					return true
	return false


func touch_input() -> void:
	if Input.is_action_just_pressed("ui_touch"):
		first_touch = get_global_mouse_position()
		var grid_position: Vector2 = pixel_to_grid(first_touch.x, first_touch.y)
		print(grid_position)
	if Input.is_action_just_released("ui_touch"):
		final_touch = get_global_mouse_position()
