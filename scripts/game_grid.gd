extends Node2D

# grid variables
export(int) var columns
export(int) var rows
export(int) var tile_size
export(int) var grid_x_start
export(int) var grid_y_start
export(int) var new_tetromino_x_start
export(int) var new_tetromino_y_start

var available_tiles = [
	preload("res://scenes/tile_1.tscn"),
	preload("res://scenes/tile_2.tscn"),
	preload("res://scenes/tile_3.tscn"),
	preload("res://scenes/tile_4.tscn"),
	preload("res://scenes/tile_5.tscn"),
	preload("res://scenes/tile_6.tscn")
]
var tetrominoes = [
	{
		"name": "Z",
		"position": [
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
		"x_offset": [6, 6, 6, 7],
		"y_offset": [-2, -3, -3, -3],
		"rotate": true
	},
	{
		"name": "S",
		"position": [
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
		"x_offset": [6, 6, 6, 7],
		"y_offset": [-2, -3, -3, -3],
		"rotate": true
	},
	{
		"name": "J",
		"position": [
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
		"x_offset": [7, 6, 6, 6],
		"y_offset": [-3, -2, -3, -3],
		"rotate": true
	},
	{
		"name": "T",
		"position": [
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
		"x_offset": [6, 7, 6, 6],
		"y_offset": [-3, -3, -2, -3],
		"rotate": true
	},
	{
		"name": "L",
		"position": [
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
		"x_offset": [6, 6, 7, 6],
		"y_offset": [-3, -3, -3, -2],
		"rotate": true
	},
	{
		"name": "I",
		"position": [
			[
				[0, 1, 0, 0],
				[0, 1, 0, 0],
				[0, 1, 0, 0],
				[0, 1, 0, 0]
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
				[0, 0, 1, 0]
			],
			[
				[0, 0, 0, 0],
				[0, 0, 0, 0],
				[1, 1, 1, 1],
				[0, 0, 0, 0]
			]
		],
		"x_offset": [6, 6, 5, 6],
		"y_offset": [-4, -2, -4, -3],
		"rotate": true
	},
	{
		"name": "O",
		"position": [
			[
				[1, 1],
				[1, 1]
			]
		],
		"x_offset": [7],
		"y_offset": [-2],
		"rotate": false
	}
]
var grid_tiles = []
var current_tetromino = null
enum MoveDirection { LEFT, RIGHT, DOWN }

func _ready():
	randomize()
	grid_tiles = make_grid_tiles()
	create_new_tetromino()

# create new tetromino
func create_new_tetromino():
	var random_number = random_number(tetrominoes.size())
	var tetromino = tetrominoes[random_number]
	var number = 0
	if tetromino["rotate"]:
		number = floor(rand_range(0, 4))
	current_tetromino = Tetromino.new(tetromino, number)
	select_tiles()

# select tiles for the current tetromino
func select_tiles():
	var tiles = []
	for i in 4:
		var random_number = random_number(available_tiles.size())
		tiles.append(available_tiles[random_number].instance())
	current_tetromino.tiles = tiles
	draw_tetromino()

# draw tetromino
func draw_tetromino():
	var tile_index = 0
	var active_tetromino = current_tetromino.active_tetromino
	for row in active_tetromino.size():
		var positions = active_tetromino[row]
		for column in positions.size():
			if positions[column]:
				var tile = current_tetromino.tiles[tile_index]
				tile_index += 1
				add_child(tile)
				tile.position = grid_to_pixel(get_x_start(), get_y_start(), row, column)
	get_parent().get_node("move_down_timer").start()

# move tetromino down
func move_tetromino_down():
	current_tetromino.move_down()
	move_tetromino()

# move tetromino left
func move_tetromino_left():
	current_tetromino.move_left()
	move_tetromino()

# move tetromino right
func move_tetromino_right():
	current_tetromino.move_right()
	move_tetromino()

# move tetromino
func move_tetromino():
	var tile_index = 0
	var active_tetromino = current_tetromino.active_tetromino
	for row in active_tetromino.size():
		var positions = active_tetromino[row]
		for column in positions.size():
			if positions[column]:
				var tile = current_tetromino.tiles[tile_index]
				tile_index += 1
				tile.move(grid_to_pixel(get_x_start(), get_y_start(), row, column))

# check whether the move is allowed
func move_allowed(move_direction):
	var x_start = get_x_start()
	var y_start = get_y_start()
	match move_direction:
		MoveDirection.LEFT:
			x_start -= tile_size
		MoveDirection.RIGHT:
			x_start += tile_size
		MoveDirection.DOWN:
			y_start += tile_size
	var active_tetromino = current_tetromino.active_tetromino
	for i in active_tetromino.size():
		var positions = active_tetromino[i]
		for j in positions.size():
			if positions[j]:
				#var tile = current_tetromino.tiles[tile_index]
				#tile_index += 1
				grid_to_pixel(x_start, y_start, i, j)

# convert grid position to pixel position
func grid_to_pixel(x_start, y_start, row, column):
	var pixel_x = x_start + column * tile_size
	var pixel_y = y_start + row * tile_size
	return Vector2(pixel_x, pixel_y)

# make grid tiles
func make_grid_tiles():
	var array = []
	for row in rows:
		array.append([])
		for column in columns:
			array[row].append(null)
	return array

# choose a random number
func random_number(end):
	return floor(rand_range(0, end))

# choose x_start to draw the tetromino
func get_x_start():
	return grid_x_start + tile_size * current_tetromino.current_x_offset()

# choose y_start to draw the tetromino
func get_y_start():
	return grid_y_start + tile_size * current_tetromino.current_y_offset()

func _on_move_down_timer_timeout():
	move_tetromino_down()


# Tetromino Class
class Tetromino:
	var tetromino = null
	var active_tetromino_index = 0
	var active_tetromino = null
	var tiles = []
	
	func _init(tetromino, active_tetromino_index):
		self.tetromino = tetromino
		self.active_tetromino_index = active_tetromino_index
		active_tetromino = tetromino["position"][active_tetromino_index]
	
	func rotate():
		if tetromino["rotate"]:
			active_tetromino_index += 1
			if active_tetromino_index >= 4:
				active_tetromino_index = 0
	
	func current_x_offset():
		return tetromino["x_offset"][active_tetromino_index]
	
	func current_y_offset():
		return tetromino["y_offset"][active_tetromino_index]
	
	func move_down():
		for i in tetromino["y_offset"].size():
			tetromino["y_offset"][i] += 1
	
	func move_left():
		for i in tetromino["x_offset"].size():
			tetromino["x_offset"][i] -= 1
	
	func move_right():
		for i in tetromino["x_offset"].size():
			tetromino["x_offset"][i] += 1
