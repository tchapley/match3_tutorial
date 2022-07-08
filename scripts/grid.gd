extends Node2D

signal damage_ice
signal make_ice
signal make_lock
signal damage_lock
signal make_concrete
signal damage_concrete
signal make_slime
signal damage_slime

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
export(PoolVector2Array) var lock_spaces
export(PoolVector2Array) var concrete_spaces
export(PoolVector2Array) var slime_spaces

var all_pieces := []
var current_matches := []
var first_touch := Vector2.ZERO
var final_touch := Vector2.ZERO
var controlling := false
var state := MOVE
var piece_one: Node2D = null
var piece_two: Node2D = null
var last_place := Vector2.ZERO
var last_direction := Vector2.ZERO
var move_checked := false
var damaged_slime := false
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
	spawn_lock()
	spawn_concrete()
	spawn_slime()


func _process(_delta: float) -> void:
	if state == MOVE:
		touch_input()


func restricted_fill(place: Vector2) -> bool:
	if is_in_array(empty_spaces, place):
		return true
	if is_in_array(concrete_spaces, place):
		return true
	if is_in_array(slime_spaces, place):
		return true

	return false


func restricted_move(place: Vector2) -> bool:
	if is_in_array(lock_spaces, place):
		return true
	return false


func is_in_array(array: Array, item: Vector2) -> bool:
	for i in array.size():
		if item == array[i]:
			return true
	return false


func remove_from_array(array: Array, item: Vector2) -> void:
	pass


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
			if !restricted_fill(Vector2(i, j)):
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


func spawn_lock() -> void:
	for i in lock_spaces.size():
		emit_signal("make_lock", lock_spaces[i])


func spawn_concrete() -> void:
	for i in concrete_spaces.size():
		emit_signal("make_concrete", concrete_spaces[i])


func spawn_slime() -> void:
	for i in slime_spaces.size():
		emit_signal("make_slime", slime_spaces[i])


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
			if first_touch == final_touch:
				var piece = possible_pieces[0].instance()
				add_child(piece)
				piece.position = grid_to_pixel(final_touch.x, final_touch.y)
				all_pieces[final_touch.x][final_touch.y].queue_free()
				all_pieces[final_touch.x][final_touch.y] = piece
				return
			else:
				touch_difference(first_touch, final_touch)


func swap_pieces(col: int, row: int, direction: Vector2) -> void:
	var first_piece = all_pieces[col][row]
	var other_piece = all_pieces[col + direction.x][row + direction.y]
	if first_piece != null and other_piece != null:
		if !restricted_move(Vector2(col, row)) and !restricted_move(Vector2(col, row) + direction):
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
									match_and_dim(all_pieces[i - 1][j])
									match_and_dim(all_pieces[i][j])
									match_and_dim(all_pieces[i + 1][j])
									add_to_array(Vector2(i - 1, j))
									add_to_array(Vector2(i, j))
									add_to_array(Vector2(i + 1, j))
				if j > 0 and j < height - 1:
					if all_pieces[i][j - 1] != null \
						and all_pieces[i][j + 1] != null:
							if all_pieces[i][j - 1].color == current_color \
								and all_pieces[i][j + 1].color ==  current_color:
									match_and_dim(all_pieces[i][j - 1])
									match_and_dim(all_pieces[i][j])
									match_and_dim(all_pieces[i][j + 1])
									add_to_array(Vector2(i, j - 1))
									add_to_array(Vector2(i, j))
									add_to_array(Vector2(i, j + 1))
	get_parent().get_node("destory_timer").start()


func add_to_array(value: Vector2, array_to_add = current_matches) -> void:
	if !array_to_add.has(value):
		array_to_add.append(value)


func is_piece_null(col: int, row: int) -> bool:
	if all_pieces[col][row] == null:
		return true
	return false


func match_and_dim(item: Node2D) -> void:
	item.matched = true
	item.dim()


func find_bombs() -> void:
	for i in current_matches.size():
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		var current_color = all_pieces[current_column][current_row].color
		var col_matched = 0
		var row_matched = 0
		for j in current_matches.size():
			var this_column = current_matches[j].x
			var this_row = current_matches[j].y
			var this_color = all_pieces[current_column][current_row].color
			if this_column == current_column and this_color == current_color:
				col_matched += 1
			if this_row == current_row and this_color == current_color:
				row_matched += 1

			if col_matched == 5 or row_matched == 5:
				print("color bomb")
				return
			if col_matched >= 3 and row_matched >= 3:
				make_bomb(0, current_color)
				return
			if col_matched == 4:
				make_bomb(1, current_color)
				return
			if row_matched == 4:
				make_bomb(2, current_color)
				return


func make_bomb(bomb_type, color):
	for i in current_matches.size():
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		if all_pieces[current_column][current_row] == piece_one and piece_one.color == color:
			piece_one.matched = false
			change_bomb(bomb_type, piece_one)
		if all_pieces[current_column][current_row] == piece_two and piece_two.color == color:
			piece_two.matched = false
			change_bomb(bomb_type, piece_two)


func change_bomb(bomb_type, piece):
	if bomb_type == 0:
		piece.make_adjacent_bomb()
	if bomb_type == 1:
		piece.make_row_bomb()
	if bomb_type == 2:
		piece.make_column_bomb()


func destroy_matched() -> void:
	find_bombs()
	var was_matched := false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					was_matched = true
					damage_special(i, j)
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null

	move_checked = true
	if was_matched:
		get_parent().get_node("collapse_timer").start()
	else:
		swap_back()
	current_matches.clear()


func check_concrete(col: int, row: int) -> void:
	if col < width - 1:
		emit_signal("damage_concrete", Vector2(col + 1, row))
	if col > 0:
		emit_signal("damage_concrete", Vector2(col - 1, row))
	if row < height - 1:
		emit_signal("damage_concrete", Vector2(col, row + 1))
	if row > 0:
		emit_signal("damage_concrete", Vector2(col, row - 1))


func check_slime(col: int, row: int) -> void:
	if col < width - 1:
		emit_signal("damage_slime", Vector2(col + 1, row))
	if col > 0:
		emit_signal("damage_slime", Vector2(col - 1, row))
	if row < height - 1:
		emit_signal("damage_slime", Vector2(col, row + 1))
	if row > 0:
		emit_signal("damage_slime", Vector2(col, row - 1))


func damage_special(col: int, row: int) -> void:
	emit_signal("damage_ice", Vector2(col, row))
	emit_signal("damage_lock", Vector2(col, row))
	check_concrete(col, row)
	check_slime(col, row)


func collapse_columns() -> void:
	for i in width:
		for j in height:
			if all_pieces[i][j] == null and !restricted_fill(Vector2(i, j)):
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()


func refill_columns() -> void:
	for i in width:
		for j in height:
			if all_pieces[i][j] == null and !restricted_fill(Vector2(i, j)):
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
	if !damaged_slime:
		generate_slime()
	state = MOVE
	move_checked = false
	damaged_slime = false


func generate_slime():
	if slime_spaces.size() > 0:
		var slime_made = false
		var tracker = 0
		while !slime_made and tracker < 100:
			var random_num = floor(rand_range(0, slime_spaces.size()))
			var curr_x = slime_spaces[random_num].x
			var curr_y = slime_spaces[random_num].y
			var neighbor = find_normal_neighbor(curr_x, curr_y)
			if neighbor != Vector2.INF:
				slime_made = true
				all_pieces[neighbor.x][neighbor.y].queue_free()
				all_pieces[neighbor.x][neighbor.y] = null
				slime_spaces.append(Vector2(neighbor.x, neighbor.y))
				emit_signal("make_slime", Vector2(neighbor.x, neighbor.y))

			tracker += 1


func find_normal_neighbor(col: int, row: int) -> Vector2:
	if is_in_grid(Vector2(col + 1, row)):
		if all_pieces[col + 1][row] != null:
			return Vector2(col + 1, row)
	if is_in_grid(Vector2(col - 1, row)):
		if all_pieces[col - 1][row] != null:
			return Vector2(col - 1, row)
	if is_in_grid(Vector2(col, row + 1)):
		if all_pieces[col][row + 1] != null:
			return Vector2(col, row + 1)
	if is_in_grid(Vector2(col, row - 1)):
		if all_pieces[col][row - 1] != null:
			return Vector2(col, row - 1)
	return Vector2.INF


func _on_destory_timer_timeout() -> void:
	destroy_matched()


func _on_collapse_timer_timeout() -> void:
	collapse_columns()


func _on_refill_timer_timeout() -> void:
	refill_columns()


func _on_lock_holder_remove_lock(place: Vector2) -> void:
	for i in range(lock_spaces.size() - 1, -1, -1):
		if lock_spaces[i] == place:
			lock_spaces.remove(i)


func _on_concrete_holder_remove_concrete(place: Vector2) -> void:
	for i in range(concrete_spaces.size() - 1, -1, -1):
		if concrete_spaces[i] == place:
			concrete_spaces.remove(i)


func _on_slime_holder_remove_slime(place: Vector2) -> void:
	damaged_slime = true
	for i in range(slime_spaces.size() - 1, -1, -1):
		if slime_spaces[i] == place:
			slime_spaces.remove(i)
