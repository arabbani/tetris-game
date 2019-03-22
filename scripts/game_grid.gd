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
				[1, 0, 0],
				[1, 1, 0],
				[0, 1, 0]
			],
			[
				[0, 0, 0],
				[0, 1, 1],
				[1, 1, 0]
			],
			[
				[0, 1, 0],
				[0, 1, 1],
				[0, 0, 1]
			],
			[
				[0, 1, 1],
				[1, 1, 0],
				[0, 0, 0]
			]
		],
		"x_offset": 6,
		"y_offset": [-2, -3, -3, -3],
		"rotate": true
	},
	{
		"name": "S",
		"position": [
			[
				[0, 1, 0],
				[1, 1, 0],
				[1, 0, 0]
			],
			[
				[0, 0, 0],
				[1, 1, 0],
				[0, 1, 1]
			],
			[
				[0, 0, 1],
				[0, 1, 1],
				[0, 1, 0]
			],
			[
				[1, 1, 0],
				[0, 1, 1],
				[0, 0, 0]
			]
		],
		"x_offset": 6,
		"y_offset": [-2, -3, -3, -3],
		"rotate": true
	},
	{
		"name": "J",
		"position": [
			[
				[0, 0, 1],
				[1, 1, 1],
				[0, 0, 0]
			],
			[
				[1, 1, 0],
				[0, 1, 0],
				[0, 1, 0]
			],
			[
				[0, 0, 0],
				[1, 1, 1],
				[1, 0, 0]
			],
			[
				[0, 1, 0],
				[0, 1, 0],
				[0, 1, 1]
			]
		],
		"x_offset": 6,
		"y_offset": [-3, -2, -3, -3],
		"rotate": true
	},
	{
		"name": "T",
		"position": [
			[
				[0, 1, 0],
				[0, 1, 1],
				[0, 1, 0]
			],
			[
				[0, 1, 0],
				[1, 1, 1],
				[0, 0, 0]
			],
			[
				[0, 1, 0],
				[1, 1, 0],
				[0, 1, 0]
			],
			[
				[0, 0, 0],
				[1, 1, 1],
				[0, 1, 0]
			]
		],
		"x_offset": 6,
		"y_offset": [-3, -3, -2, -3],
		"rotate": true
	},
	{
		"name": "L",
		"position": [
			[
				[0, 0, 0],
				[1, 1, 1],
				[0, 0, 1]
			],
			[
				[0, 1, 1],
				[0, 1, 0],
				[0, 1, 0]
			],
			[
				[1, 0, 0],
				[1, 1, 1],
				[0, 0, 0]
			],
			[
				[0, 1, 0],
				[0, 1, 0],
				[1, 1, 0]
			]
		],
		"x_offset": 6,
		"y_offset": [-3, -3, -3, -2],
		"rotate": true
	},
	{
		"name": "I",
		"position": [
			[
				[0, 0, 0, 0],
				[1, 1, 1, 1],
				[0, 0, 0, 0],
				[0, 0, 0, 0]
			],
			[
				[0, 1, 0, 0],
				[0, 1, 0, 0],
				[0, 1, 0, 0],
				[0, 1, 0, 0]
			],
			[
				[0, 0, 0, 0],
				[0, 0, 0, 0],
				[1, 1, 1, 1],
				[0, 0, 0, 0]
			],
			[
				[0, 0, 1, 0],
				[0, 0, 1, 0],
				[0, 0, 1, 0],
				[0, 0, 1, 0],
			]
		],
		"x_offset": 6,
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
		"x_offset": 7,
		"y_offset": [-2],
		"rotate": false
	}
]
var grid_tiles = []
var current_tetromino = null
enum MoveAction { MOVE_LEFT, MOVE_RIGHT, MOVE_DOWN, ROTATE }

func _ready():
	randomize()
	grid_tiles = make_grid_tiles()
	create_new_tetromino()

# create new tetromino
func create_new_tetromino():
	current_tetromino = Tetromino.new(tetrominoes[random_number(tetrominoes.size())])
	select_tiles()

# select tiles for the current tetromino
func select_tiles():
	var tiles = []
	var active_tetromino = current_tetromino.active_tetromino
	for column in active_tetromino.size():
		var positions = active_tetromino[column]
		tiles.append([])
		for row in positions.size():
			tiles[column].append(null)
			if positions[row]:
				var random_number = random_number(available_tiles.size())
				tiles[column][row] = available_tiles[random_number].instance()
	current_tetromino.tiles = tiles
	draw_tetromino()

# draw tetromino
func draw_tetromino():
	var active_tetromino = current_tetromino.active_tetromino
	for column in active_tetromino.size():
		var positions = active_tetromino[column]
		for row in positions.size():
			if positions[row]:
				var tile = current_tetromino.tiles[column][row]
				add_child(tile)
				tile.position = grid_to_pixel(get_x_start(current_tetromino.current_x_offset()), get_y_start(current_tetromino.current_y_offset()), column, row)
	get_timer().start()

# move tetromino down
func move_tetromino_down():
	var tile = available_tiles[0].instance()
	grid_tiles[7][3] = tile
	add_child(tile)
	tile.position = grid_to_pixel(grid_x_start, grid_y_start, 7, 3)
	if move_allowed(get_x_start(current_tetromino.current_x_offset()), get_y_start(current_tetromino.current_y_offset()), MoveAction.MOVE_DOWN, current_tetromino.active_tetromino):
		current_tetromino.move_down()
		move_tetromino()
	else:
		get_timer().stop()

# move tetromino left
func move_tetromino_left():
	if move_allowed(get_x_start(current_tetromino.current_x_offset()), get_y_start(current_tetromino.current_y_offset()), MoveAction.MOVE_LEFT, current_tetromino.active_tetromino):
		current_tetromino.move_left()
		move_tetromino()

# move tetromino right
func move_tetromino_right():
	if move_allowed(get_x_start(current_tetromino.current_x_offset()), get_y_start(current_tetromino.current_y_offset()), MoveAction.MOVE_RIGHT, current_tetromino.active_tetromino):
		current_tetromino.move_right()
		move_tetromino()

# rotate tetromino
func rotate_tetromino():
	if current_tetromino.tetromino["rotate"]:
		var rotated_index = current_tetromino.next_active_tetromino_index()
		var rotated_tetromino = current_tetromino.tetromino["position"][rotated_index]
		var x_start = get_x_start(current_tetromino.tetromino["x_offset"])
		var y_start = get_y_start(current_tetromino.tetromino["y_offset"][rotated_index])
		if move_allowed(x_start, y_start, MoveAction.ROTATE, rotated_tetromino):
			current_tetromino.rotate(rotated_index)
			move_tetromino()

# move tetromino
func move_tetromino():
	var active_tetromino = current_tetromino.active_tetromino
	for column in active_tetromino.size():
		var positions = active_tetromino[column]
		for row in positions.size():
			if positions[row]:
				var tile = current_tetromino.tiles[column][row]
				tile.move(grid_to_pixel(get_x_start(current_tetromino.current_x_offset()), get_y_start(current_tetromino.current_y_offset()), column, row))

# check whether the move is allowed
func move_allowed(tetromino_x, tetromino_y, move_direction, tetromino):
	var offset = Vector2(0, 0)
	match move_direction:
		MoveAction.MOVE_LEFT:
			offset.x -= tile_size
		MoveAction.MOVE_RIGHT:
			offset.x += tile_size
		MoveAction.MOVE_DOWN:
			offset.y += tile_size
	for column in tetromino.size():
		var positions = tetromino[column]
		for row in positions.size():
			if positions[row]:
				var pixel_position = grid_to_pixel(tetromino_x, tetromino_y, column, row) + offset
				var grid_position = pixel_to_grid(grid_x_start, grid_y_start, pixel_position.x, pixel_position.y)
				if grid_position.x < 0 or grid_position.x >= columns or grid_position.y >= rows:
					return false
				if grid_position.y < 0:
					continue
				if grid_tiles[grid_position.x][grid_position.y] != null:
					return false
	return true

# check whether move button is pressed
func check_move_input():
	if Input.is_action_just_pressed("ui_left"):
		move_tetromino_left()
	elif Input.is_action_just_pressed("ui_right"):
		move_tetromino_right()
	elif Input.is_action_just_pressed("ui_up"):
		rotate_tetromino()

# convert grid position to pixel position
func grid_to_pixel(x_start, y_start, column, row):
	var pixel_x = x_start + column * tile_size
	var pixel_y = y_start + row * tile_size
	return Vector2(pixel_x, pixel_y)

# convert pixel position to grid position
func pixel_to_grid(x_start, y_start, pixel_x, pixel_y):
	var column = round((pixel_x - x_start) / tile_size)
	var row = round((pixel_y - y_start) / tile_size)
	return Vector2(column, row)

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

func get_timer():
	return get_parent().get_node("move_down_timer")

# choose x_start to draw the tetromino
func get_x_start(x_offset):
	return grid_x_start + tile_size * x_offset

# choose y_start to draw the tetromino
func get_y_start(y_offset):
	return grid_y_start + tile_size * y_offset

func _on_move_down_timer_timeout():
	move_tetromino_down()

func _process(delta):
	check_move_input()


# Tetromino Class
class Tetromino:
	var tetromino = null
	var active_tetromino_index = 0
	var active_tetromino = null
	var tiles = []
	
	func _init(tetromino):
		self.tetromino = tetromino
		if tetromino["rotate"]:
			active_tetromino_index = floor(rand_range(0, tetromino["position"].size()))
		select_active_tetromino()
	
	func select_active_tetromino():
		active_tetromino = tetromino["position"][active_tetromino_index]
	
	func next_active_tetromino_index():
		var index = active_tetromino_index
		index += 1
		if index >= 4:
			index = 0
		return index
	
	func rotate(index):
		active_tetromino_index = index
		select_active_tetromino()
		rotate_tiles()

	func rotate_tiles():
		var array = []
		for i in tiles.size():
			array.append([])
			var tile_row = tiles[i]
			var size = tile_row.size()
			for j in size:
				array[i].append(null)
		for i in tiles.size():
			var tile_row = tiles[i]
			var size = tile_row.size()
			for j in size:
				array[j][i] = tiles[i][size - 1 - j]
		tiles = array

	func current_x_offset():
		return tetromino["x_offset"]
	
	func current_y_offset():
		return tetromino["y_offset"][active_tetromino_index]
	
	func move_down():
		for i in tetromino["y_offset"].size():
			tetromino["y_offset"][i] += 1
	
	func move_left():
		tetromino["x_offset"] -= 1
	
	func move_right():
		tetromino["x_offset"] += 1

