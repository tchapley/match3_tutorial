extends Node2D

export(int) var width
export(int) var height
export(int) var x_start
export(int) var y_start
export(int) var offset

var all_pieces := []


func _ready() -> void:
	all_pieces = make_2d_array()
	print(all_pieces)


func make_2d_array() -> Array:
	var array := []
	for x in width:
		array.append([])
		for y in height:
			array[x].append(null)

	return array
