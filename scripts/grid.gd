extends Node2D

signal damage_ice
signal make_ice

enum {
	WAIT,
	MOVE,
}

export(int) var width
export(int) var height
export(int) var x_start
export(int) var y_start
export(int) var offset
export(int) var y_offset
export(PoolVector2Array) var empty_spaces
export(PoolVector2Array) var ice_spaces

var all_pieces := []
var first_touch := Vector2.ZERO
var final_touch := Vector2.ZERO
var controlling := false
var state := MOVE
var piece_one: Node2D = null
var piece_two: Node2D = null
var last_place := Vector2.ZERO
var last_direction := Vector2.ZERO
var move_checked := false
var possible_pieces := [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
]


func _ready() -> void:
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()
	spawn_ice()


func _process(_delta: float) -> void:
	if state == MOVE:
		touch_input()


func restricted_movement(place: Vector2) -> bool:
	for i in empty_spaces.size():
		if empty_spaces[i] == place:
			return true
	return false


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
			if !restricted_movement(Vector2(i, j)):
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


func spawn_ice() -> void:
	for i in ice_spaces.size():
		emit_signal("make_ice", ice_spaces[i])

func match_at(col: int, row: int, color: String) -> bool:
	if col > 1:
		if all_pieces[col - 1][row] != null and all_pieces[col - 2][row] != null:
				if all_pieces[col - 1][row].color == color \
					and all_pieces[col - 2][row].color == color:
					return true
	if row > 1:
		if all_pieces[col][row - 1] != null and all_pieces[col][row - 2] != null:
				if all_pieces[col][row - 1].color == color \
					and all_pieces[col][row - 2].color == color:
					return true
	return false


func touch_input() -> void:
	if Input.is_action_just_pressed("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)):
			first_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			controlling = true
	if Input.is_action_just_released("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)) and controlling:
			controlling = false
			final_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			touch_difference(first_touch, final_touch)


func swap_pieces(col: int, row: int, direction: Vector2) -> void:
	var first_piece = all_pieces[col][row]
	var other_piece = all_pieces[col + direction.x][row + direction.y]
	if first_piece != null and other_piece != null:
		state = WAIT
		store_info(first_piece, other_piece, Vector2(col, row), direction)
		all_pieces[col][row] = other_piece
		all_pieces[col + direction.x][row + direction.y] = first_piece
		first_piece.move(other_piece.position)
		other_piece.move(grid_to_pixel(col, row))
		if !move_checked:
			find_matches()


func store_info(first_piece: Node2D, other_piece: Node2D, place: Vector2, direction: Vector2) -> void:
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction


func swap_back() -> void:
	#Move the previously swapped pieces back to their
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = MOVE
	move_checked = false
	pass


func touch_difference(grid1: Vector2, grid2: Vector2) -> void:
	var difference = grid2 - grid1
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid1.x, grid1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid1.x, grid1.y, Vector2(-1, 0))
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid1.x, grid1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid1.x, grid1.y, Vector2(0, -1))


func is_in_grid(grid_position: Vector2) -> bool:
	if grid_position.x >= 0 and grid_position.x < width:
		if grid_position.y >= 0 and grid_position.y < height:
			return true
	return false


func find_matches() -> void:
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color: String = all_pieces[i][j].color
				if i > 0 and i < width - 1:
					if all_pieces[i - 1][j] != null \
						and all_pieces[i + 1][j] != null:
							if all_pieces[i - 1][j].color == current_color \
								and all_pieces[i + 1][j].color ==  current_color:
									all_pieces[i - 1][j].matched = true
									all_pieces[i - 1][j].dim()
									all_pieces[i][j].matched = true
									all_pieces[i][j].dim()
									all_pieces[i + 1][j].matched = true
									all_pieces[i + 1][j].dim()

				if j > 0 and j < height - 1:
					if all_pieces[i][j - 1] != null \
						and all_pieces[i][j + 1] != null:
							if all_pieces[i][j - 1].color == current_color \
								and all_pieces[i][j + 1].color ==  current_color:
									all_pieces[i][j - 1].matched = true
									all_pieces[i][j - 1].dim()
									all_pieces[i][j].matched = true
									all_pieces[i][j].dim()
									all_pieces[i][j + 1].matched = true
									all_pieces[i][j + 1].dim()
	get_parent().get_node("destory_timer").start()


func collapse_columns() -> void:
	for i in width:
		for j in height:
			if all_pieces[i][j] == null and !restricted_movement(Vector2(i, j)):
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()

func destroy_matched() -> void:
	var was_matched := false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					emit_signal("damage_ice", Vector2(i, j))
					print("emitted signal")
					was_matched = true
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null

	move_checked = true
	if was_matched:
		get_parent().get_node("collapse_timer").start()
	else:
		swap_back()


func refill_columns() -> void:
	for i in width:
		for j in height:
			if all_pieces[i][j] == null and !restricted_movement(Vector2(i, j)):
				var rand: int = floor(rand_range(0, possible_pieces.size()))
				var piece: Node2D = possible_pieces[rand].instance()
				var loops := 0
				while match_at(i, j, piece.color) and loops < 100:
					loops += 1
					rand = floor(rand_range(0, possible_pieces.size()))
					piece = possible_pieces[rand].instance()
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				all_pieces[i][j] = piece

	after_refill()

func after_refill() -> void:
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if match_at(i, j, all_pieces[i][j].color):
					find_matches()
					get_parent().get_node("destory_timer").start()
					return

	state = MOVE
	move_checked = false


func _on_destory_timer_timeout() -> void:
	destroy_matched()


func _on_collapse_timer_timeout() -> void:
	collapse_columns()


func _on_refill_timer_timeout() -> void:
	refill_columns()
