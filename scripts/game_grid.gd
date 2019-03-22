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
		"y_offset": [-2],
		"rotate": false
	}
]
var grid_tiles = []
var current_tetromino = null

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
	draw_tiles()

# draw tiles
func draw_tiles():
	var tile_index = 0
	var active_tetromino = current_tetromino.active_tetromino
	for i in active_tetromino.size():
		var positions = active_tetromino[i]
		for j in positions.size():
			if positions[j]:
				var tile = current_tetromino.tiles[tile_index]
				tile_index += 1
				add_child(tile)
				tile.position = grid_to_pixel(new_tetromino_x_start, new_tetromino_y_start + tile_size * current_tetromino.tetromino["y_offset"][current_tetromino.active_tetromino_index], j, i)

# convert grid position to pixel position
func grid_to_pixel(x_start, y_start, column, row):
	var pixel_x = x_start + column * tile_size
	var pixel_y = y_start + row * tile_size
	return Vector2(pixel_x, pixel_y)

# make grid tiles
func make_grid_tiles():
	var array = []
	for column in columns:
		array.append([])
		for row in rows:
			array[column].append(null)
	return array

# choose a random number
func random_number(end):
	return floor(rand_range(0, end))



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


