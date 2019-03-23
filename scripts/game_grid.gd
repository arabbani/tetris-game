extends Node2D

# grid variables
export(int) var columns
export(int) var rows
export(int) var tile_size
export(int) var grid_x_start
export(int) var grid_y_start

var available_tiles = [
	preload("res://scenes/tile_1.tscn"),
	preload("res://scenes/tile_2.tscn"),
	preload("res://scenes/tile_3.tscn"),
	preload("res://scenes/tile_4.tscn"),
	preload("res://scenes/tile_5.tscn"),
	preload("res://scenes/tile_6.tscn")
]
var available_tetrominoes = [
	{
		"name": "Z",
		"patterns": [
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
		]
	},
	{
		"name": "S",
		"patterns": [
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
		]
	},
	{
		"name": "J",
		"patterns": [
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
		]
	},
	{
		"name": "T",
		"patterns": [
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
		]
	},
	{
		"name": "L",
		"patterns": [
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
		]
	},
	{
		"name": "I",
		"patterns": [
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
		]
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
		]
	}
]

enum GameStates { PLAYING, GAME_OVER }
enum MoveStates { ACTIVE, INACTIVE }
var game_state
var movement

var grid_tiles = []
var grid_tetrominoes = []
var active_tetromino = null
var current_matches = []


################################## DUMMY ######################################

func dummy_tile():
	var tile = available_tiles[0].instance()
	grid_tiles[7][5] = tile
	add_child(tile)
	tile.position = grid_to_pixel(7, 5)




################################## METHOD OVERRIDE ######################################

func _ready():
	randomize()
	grid_tiles = make_grid_tiles()
	game_state = GameStates.PLAYING
	movement = MoveStates.INACTIVE
	#dummy_tile()
	create_new_tetromino()

func _process(delta):
	if movement != MoveStates.ACTIVE:
		check_movement()



################################## CREATE TETROMINO ######################################

# create new tetromino
func create_new_tetromino():
	active_tetromino = null
	var tetromino = available_tetrominoes[random_number(available_tetrominoes.size())]
	#var tetromino = available_tetrominoes[6]
	active_tetromino = Tetromino.new(tetromino)
	create_tetromino_tiles()

# select tiles for the current tetromino
func create_tetromino_tiles():
	var pattern = active_tetromino.get_pattern()
	if pattern != null:
		for column in pattern.size():
			var pattern_flags = pattern[column]
			active_tetromino.tiles.append([])
			for row in pattern_flags.size():
				active_tetromino.tiles[column].append(null)
				if pattern_flags[row]:
					var loops = 0
					var tile = create_tile()
					while match_at(column, row, tile.color) && loops < 100:
						loops += 1
						tile = create_tile()
					add_child(tile)
					tile.position = grid_to_pixel(column, row, active_tetromino.offset())
					active_tetromino.tiles[column][row] = tile
		start_timer()



################################## MOVE TETROMINOES ######################################

# move tetromino left
func move_left():
	if move_allowed(active_tetromino.get_pattern(), active_tetromino.offset() + Vector2(-1, 0)):
		active_tetromino.move_left()
		move_tetromino()

# move tetromino right
func move_right():
	if move_allowed(active_tetromino.get_pattern(), active_tetromino.offset() + Vector2(1, 0)):
		active_tetromino.move_right()
		move_tetromino()

# rotate tetromino
func rotate():
	var rotated_index = active_tetromino.next_index()
	var rotated_pattern = active_tetromino.get_pattern(rotated_index)
	var offset = active_tetromino.offset(rotated_index)
	var wall_kick = 0
	if !move_allowed(rotated_pattern, offset):
		if offset.x < columns / 2:
			wall_kick = 1
		else:
			wall_kick = -1
	if move_allowed(rotated_pattern, offset + Vector2(wall_kick , 0)):
		active_tetromino.rotate(rotated_index)
		if wall_kick > 0:
			active_tetromino.move_right()
		elif wall_kick < 0:
			active_tetromino.move_left()
		move_tetromino()

# move tetromino down
func move_down():
	if move_allowed(active_tetromino.get_pattern(), active_tetromino.offset() + Vector2(0, 1)):
		active_tetromino.move_down()
		move_tetromino()
	else:
		stop_timer()
		lock_tetromino()

# move tetromino down in one move
func move_down_fast():
	while move_allowed(active_tetromino.get_pattern(), active_tetromino.offset() + Vector2(0, 1)):
		active_tetromino.move_down()
	move_tetromino()
	lock_tetromino()

# move tetromino
func move_tetromino():
	var pattern = active_tetromino.get_pattern()
	for column in pattern.size():
		var pattern_flags = pattern[column]
		for row in pattern_flags.size():
			if pattern_flags[row]:
				var tile = active_tetromino.tiles[column][row]
				if tile != null:
					tile.move(grid_to_pixel(column, row, active_tetromino.offset()))



################################## DESTROY MATCHED TILES ######################################

# locks the current tetromino
func lock_tetromino():
	var tiles = active_tetromino.tiles
	for column in tiles.size():
		var column_tiles = tiles[column]
		for row in column_tiles.size():
			var offset = active_tetromino.offset()
			if column_tiles[row] == null:
				continue
			elif (offset.y + row) < 0:
				game_state = GameStates.GAME_OVER
				break
			elif column_tiles[row] != null:
				var grid_position = tetromino_to_grid_coordinate(column, row, offset)
				grid_tiles[grid_position.x][grid_position.y] = column_tiles[row]
	grid_tetrominoes.append(active_tetromino)
	if game_state != GameStates.GAME_OVER:
		find_matches()

# check whether there is a match in the grid
func find_matches():
	for column in columns:
		for row in rows:
			if !is_tile_null(column, row):
				var current_color = grid_tiles[column][row].color
				if column > 0 and column < columns - 1:
					if !is_tile_null(column - 1, row) and !is_tile_null(column + 1, row):
						if grid_tiles[column - 1][row].color == current_color and grid_tiles[column + 1][row].color == current_color:
							set_match(grid_tiles[column - 1][row])
							set_match(grid_tiles[column][row])
							set_match(grid_tiles[column + 1][row])
							add_to_matched_array(Vector2(column, row))
							add_to_matched_array(Vector2(column + 1, row))
							add_to_matched_array(Vector2(column - 1, row))
				if row > 0 and row < rows - 1:
					if !is_tile_null(column, row - 1) and !is_tile_null(column, row + 1):
						if grid_tiles[column][row - 1].color == current_color and grid_tiles[column][row + 1].color == current_color:
							set_match(grid_tiles[column][row - 1])
							set_match(grid_tiles[column][row])
							set_match(grid_tiles[column][row + 1])
							add_to_matched_array(Vector2(column, row))
							add_to_matched_array(Vector2(column, row + 1))
							add_to_matched_array(Vector2(column, row - 1))
	get_parent().get_node("destroy_timer").start()

func set_match(item):
	item.matched = true
	item.dim()

func add_to_matched_array(value):
	if !current_matches.has(value):
		current_matches.append(value)

# destroy matched tiles
func destroy_matched_tiles():
	for column in columns:
		for row in rows:
			if !is_tile_null(column, row):
				if grid_tiles[column][row].matched:
					grid_tiles[column][row].queue_free()
					grid_tiles[column][row] = null
					#emit_signal("update_score", piece_value * streak)
	get_parent().get_node("collapse_timer").start()
	current_matches.clear()

# collapse the tetrominoes
func collapse_tetrominoes():
	#for i in grid_tetrominoes.size():
		
	
	create_new_tetromino()



################################## CONDITION CHECK ######################################

# check movement
func check_movement():
	if Input.is_action_just_pressed("ui_left"):
		stop_timer()
		movement = MoveStates.ACTIVE
		move_left()
		start_timer()
		movement = MoveStates.INACTIVE
	elif Input.is_action_just_pressed("ui_right"):
		stop_timer()
		movement = MoveStates.ACTIVE
		move_right()
		start_timer()
		movement = MoveStates.INACTIVE
	elif Input.is_action_just_pressed("ui_up"):
		stop_timer()
		movement = MoveStates.ACTIVE
		rotate()
		start_timer()
		movement = MoveStates.INACTIVE
	elif Input.is_action_just_pressed("ui_down"):
		stop_timer()
		movement = MoveStates.ACTIVE
		move_down_fast()
		movement = MoveStates.INACTIVE

# check whether tile is null
func is_tile_null(column, row):
	return grid_tiles[column][row] == null

# check whether the tile is a match
func match_at(column, row, color):
	if column > 1:
		if !is_tile_null(column - 1, row) && !is_tile_null(column - 2, row):
			if grid_tiles[column - 1][row].color == color && grid_tiles[column - 2][row].color == color:
				return true
	if row > 1:
		if !is_tile_null(column, row - 1) && !is_tile_null(column, row - 2):
			if grid_tiles[column][row - 1].color == color && grid_tiles[column][row - 2].color == color:
				return true
	return false

# check whether the move is allowed
func move_allowed(pattern, offset):
	for column in pattern.size():
		var pattern_flags = pattern[column]
		for row in pattern_flags.size():
			if pattern_flags[row]:
				var grid_position = tetromino_to_grid_coordinate(column, row, offset)
				if grid_position.x < 0 or grid_position.x >= columns or grid_position.y >= rows:
					return false
				if grid_position.y < 0:
					continue
				if !is_tile_null(grid_position.x, grid_position.y):
					return false
	return true



################################## UTILITY METHODS ######################################

# convert tetromino coordinate to grid coordinate
func tetromino_to_grid_coordinate(column, row, offset):
	var pixel_position = grid_to_pixel(column, row, offset)
	return pixel_to_grid(pixel_position.x, pixel_position.y)

# convert pixel position to grid position
func pixel_to_grid(pixel_x, pixel_y):
	var column = round((pixel_x - grid_x_start) / tile_size)
	var row = round((pixel_y - grid_y_start) / tile_size)
	return Vector2(column, row)

# convert grid position to pixel position
func grid_to_pixel(column, row, offset = Vector2(0 , 0)):
	var start_pixel = get_start_pixel(offset)
	var pixel_x = start_pixel.x + column * tile_size
	var pixel_y = start_pixel.y + row * tile_size
	return Vector2(pixel_x, pixel_y)

# calculate start pixel
func get_start_pixel(offset):
	var x_start = grid_x_start + tile_size * offset.x
	var y_start = grid_y_start + tile_size * offset.y
	return Vector2(x_start, y_start)

# create a new tile
func create_tile(index = random_number(available_tiles.size())):
	return available_tiles[index].instance()

# choose a random number
func random_number(end):
	return floor(rand_range(0, end))

# make grid tiles
func make_grid_tiles():
	var array = []
	for column in columns:
		array.append([])
		for row in rows:
			array[column].append(null)
	return array



################################## TIMER ######################################

func stop_timer():
	if !get_timer().is_stopped():
		get_timer().stop()

func start_timer():
	if get_timer().is_stopped():
		get_timer().start()

func get_timer():
	return get_parent().get_node("move_down_timer")

func _on_move_down_timer_timeout():
	move_down()

func _on_destroy_timer_timeout():
	destroy_matched_tiles()

func _on_collapse_timer_timeout():
	collapse_tetrominoes()



################################# TETROMINO CLASS ########################################

# Tetromino Class
class Tetromino:
	var tetromino = null
	var active_index = 0
	var tiles = []
	var x_offset = 6
	var y_offset = null
	var tetromino_y_offsets = {
		"Z": [-2, -3, -3, -3],
		"S": [-2, -3, -3, -3],
		"J": [-3, -2, -3, -3],
		"T": [-3, -3, -2, -3],
		"L": [-3, -3, -3, -2],
		"I": [-4, -2, -4, -3],
		"O": [-3, -3, -3, -3]
	}
	
	func _init(tetromino):
		self.tetromino = tetromino
		initialize()
	
	func initialize():
		y_offset = tetromino_y_offsets[tetromino["name"]]
		active_index = floor(rand_range(0, tetromino["patterns"].size()))
	
	func get_pattern(index = active_index):
		return tetromino["patterns"][index]
	
	func offset(index = active_index):
		return Vector2(x_offset, y_offset[index])
	
	func move_down():
		for i in y_offset.size():
			y_offset[i] += 1
	
	func move_left():
		x_offset -= 1
	
	func move_right():
		x_offset += 1
	
	func next_index():
		var index = active_index
		index += 1
		if index >= tetromino["patterns"].size():
			index = 0
		return index
	
	func rotate(index):
		active_index = index
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
	
