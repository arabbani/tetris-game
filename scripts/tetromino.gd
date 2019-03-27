extends Object

class_name Tetromino

var tetromino: Dictionary = {}
var active_index : int = 0
var tiles : = []
var available_tetrominoes : = [
		{
			"name": "Z",
			"patterns": [
				[
					[1, 1, 0],
					[0, 1, 1],
					[0, 0, 0]
				],
				[
					[0, 0, 1],
					[0, 1, 1],
					[0, 1, 0]
				],
				[
					[0, 0, 0],
					[1, 1, 0],
					[0, 1, 1]
				],
				[
					[0, 1, 0],
					[1, 1, 0],
					[1, 0, 0]
				]
			],
			"x_offset": 6,
			"y_offset": [-2, -3, -3, -3],
			"initial_move": [2, 3, 2, 3]
		},
		{
			"name": "S",
			"patterns": [
				[
					[0, 1, 1],
					[1, 1, 0],
					[0, 0, 0]
				],
				[
					[0, 1, 0],
					[0, 1, 1],
					[0, 0, 1]
				],
				[
					[0, 0, 0],
					[0, 1, 1],
					[1, 1, 0]
				],
				[
					[1, 0, 0],
					[1, 1, 0],
					[0, 1, 0]
				]
			],
			"x_offset": 6,
			"y_offset": [-2, -3, -3, -3],
			"initial_move": [2, 3, 2, 3]
		},
		{
			"name": "J",
			"patterns": [
				[
					[0, 1, 0],
					[0, 1, 0],
					[1, 1, 0]
				],
				[
					[1, 0, 0],
					[1, 1, 1],
					[0, 0, 0]
				],
				[
					[0, 1, 1],
					[0, 1, 0],
					[0, 1, 0]
				],
				[
					[0, 0, 0],
					[1, 1, 1],
					[0, 0, 1]
				]
			],
			"x_offset": 6,
			"y_offset": [-3, -2, -3, -3],
			"initial_move": [3, 2, 3, 2]
		},
		{
			"name": "T",
			"patterns": [
				[
					[0, 0, 0],
					[1, 1, 1],
					[0, 1, 0]
				],
				[
					[0, 1, 0],
					[1, 1, 0],
					[0, 1, 0]
				],
				[
					[0, 1, 0],
					[1, 1, 1],
					[0, 0, 0]
				],
				[
					[0, 1, 0],
					[0, 1, 1],
					[0, 1, 0]
				]
			],
			"x_offset": 6,
			"y_offset": [-3, -3, -2, -3],
			"initial_move": [2, 3, 2, 3]
		},
		{
			"name": "L",
			"patterns": [
				[
					[0, 1, 0],
					[0, 1, 0],
					[0, 1, 1]
				],
				[
					[0, 0, 0],
					[1, 1, 1],
					[1, 0, 0]
				],
				[
					[1, 1, 0],
					[0, 1, 0],
					[0, 1, 0]
				],
				[
					[0, 0, 1],
					[1, 1, 1],
					[0, 0, 0]
				]
			],
			"x_offset": 6,
			"y_offset": [-3, -3, -3, -2],
			"initial_move": [3, 2, 3, 2]
		},
		{
			"name": "I",
			"patterns": [
				[
					[0, 1, 0, 0],
					[0, 1, 0, 0],
					[0, 1, 0, 0],
					[0, 1, 0, 0],
				],
				[
					[0, 0, 0, 0],
					[1, 1, 1, 1],
					[0, 0, 0, 0],
					[0, 0, 0, 0]
				],
				[
					[0, 0, 1, 0],
					[0, 0, 1, 0],
					[0, 0, 1, 0],
					[0, 0, 1, 0],
				],
				[
					[0, 0, 0, 0],
					[0, 0, 0, 0],
					[1, 1, 1, 1],
					[0, 0, 0, 0]
				]
			],
			"x_offset": 6,
			"y_offset": [-4, -2, -4, -3],
			"initial_move": [4, 1, 4, 1]
		},
		{
			"name": "O",
			"patterns": [
				[
					[0, 0, 0, 0],
					[0, 1, 1, 0],
					[0, 1, 1, 0],
					[0, 0, 0, 0]
				],
				[
					[0, 0, 0, 0],
					[0, 1, 1, 0],
					[0, 1, 1, 0],
					[0, 0, 0, 0]
				],
				[
					[0, 0, 0, 0],
					[0, 1, 1, 0],
					[0, 1, 1, 0],
					[0, 0, 0, 0]
				],
				[
					[0, 0, 0, 0],
					[0, 1, 1, 0],
					[0, 1, 1, 0],
					[0, 0, 0, 0]
				]
			],
			"x_offset": 6,
			"y_offset": [-3, -3, -3, -3],
			"initial_move": [2, 2, 2, 2]
		}
]
	
func _init():
	tetromino = available_tetrominoes[floor(rand_range(0, available_tetrominoes.size()))]
	active_index = floor(rand_range(0, tetromino["patterns"].size()))
	
func initial_move() -> int:
	return tetromino["initial_move"][active_index]
	
func get_pattern(index : = active_index) -> Array:
	return tetromino["patterns"][index]
	
func offset(index : = active_index) -> Vector2:
	return Vector2(tetromino["x_offset"], tetromino["y_offset"][index])
	
func move_left() -> void:
	tetromino["x_offset"] -= 1
	
func move_right() -> void:
	tetromino["x_offset"] += 1
	
func move_down() -> void:
	for i in tetromino["y_offset"].size():
		tetromino["y_offset"][i] += 1
	
func next_index() -> int:
	var index = active_index + 1
	if index >= tetromino["patterns"].size():
		index = 0
	return index
	
func rotate_tetris(index : int) -> void:
	active_index = index
	var array = []
	for i in tiles.size():
		array.append([])
		var row_tiles = tiles[i]
		var size = row_tiles.size()
		for j in size:
			array[i].append(null)
			array[i][j] = tiles[size - 1 - j][i]
	tiles = array
	
func remove_tile(position : Vector2) -> void:
	tetromino["patterns"][active_index][position.y][position.x] = 0
	tiles[position.y][position.x].free()
	#tiles[position.y][position.x].queue_free()
	tiles[position.y][position.x] = null
