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
	grid_tiles[7][5]["tile"] = tile
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
	active_tetromino = Tetromino.new()
	create_tetromino_tiles()

# select tiles for the current tetromino
func create_tetromino_tiles():
	var pattern = active_tetromino.get_pattern()
	if pattern != null:
		for row in pattern.size():
			var row_flags = pattern[row]
			active_tetromino.tiles.append([])
			for column in row_flags.size():
				active_tetromino.tiles[row].append(null)
				if row_flags[column]:
					#var tile = available_tiles[row].instance()
					var loops = 0
					var tile = create_tile()
					match active_tetromino.tetromino["name"]:
						"J", "T", "L", "I":
							while match_at(row, column, tile.color) && loops < 100:
								loops += 1
								tile = create_tile()
					add_child(tile)
					tile.position = grid_to_pixel(row, column, active_tetromino.offset())
					active_tetromino.tiles[row][column] = tile
		start_move_down_timer()



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
		stop_move_down_timer()
		#lock_tetromino()

# move tetromino down in one move
func move_down_fast():
	while move_allowed(active_tetromino.get_pattern(), active_tetromino.offset() + Vector2(0, 1)):
		active_tetromino.move_down()
	move_tetromino()
	lock_tetromino()

# move tetromino
func move_tetromino(tetromino = active_tetromino):
	var pattern = tetromino.get_pattern()
	for row in range(pattern.size() - 1, -1, -1):
		var row_flags = pattern[row]
		for column in row_flags.size():
			if row_flags[column]:
				var tile = tetromino.tiles[row][column]
				if tile != null:
					tile.move(grid_to_pixel(row, column, tetromino.offset()))




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
				grid_tiles[grid_position.x][grid_position.y] = {
					"tile": column_tiles[row],
					"tetromino": active_tetromino
				}
	if game_state != GameStates.GAME_OVER:
		grid_tetrominoes.append(active_tetromino)
		find_matches()

# check whether there is a match in the grid
func find_matches():
	for column in columns:
		for row in rows:
			if !is_tile_null(column, row):
				var current_color = get_grid_tile(column, row).color
				if column > 0 and column < columns - 1:
					if !is_tile_null(column - 1, row) and !is_tile_null(column + 1, row):
						if get_grid_tile(column - 1, row).color == current_color and get_grid_tile(column + 1, row).color == current_color:
							match_tile(column - 1, row)
							match_tile(column, row)
							match_tile(column + 1, row)
				if row > 0 and row < rows - 1:
					if !is_tile_null(column, row - 1) and !is_tile_null(column, row + 1):
						if get_grid_tile(column, row - 1).color == current_color and get_grid_tile(column, row + 1).color == current_color:
							match_tile(column, row - 1)
							match_tile(column, row)
							match_tile(column, row + 1)
	get_parent().get_node("destroy_timer").start()

# set the tile as matched
func match_tile(column, row):
	var tile = get_grid_tile(column, row)
	tile.matched = true
	tile.dim()
	add_to_matched_array(Vector2(column, row))

# add the tile to matched array
func add_to_matched_array(value):
	if !current_matches.has(value):
		current_matches.append(value)

# destroy matched tiles
func destroy_matched_tiles():
	for column in columns:
		for row in rows:
			if !is_tile_null(column, row):
				if get_grid_tile(column, row).matched:
					get_grid_tile(column, row).queue_free()
					var tetromino = grid_tiles[column][row]["tetromino"]
					tetromino.clear_pattern_flag(grid_to_tetromino_coordinate(column, row, tetromino.offset()))
					grid_tiles[column][row] = null
	get_parent().get_node("collapse_timer").start()
	current_matches.clear()

# collapse the tetrominoes
func collapse_tetrominoes():
	for i in grid_tetrominoes.size():
		var tetromino = grid_tetrominoes[i]
		#print(tetromino.get_pattern())
		print("#####################")
		print(i)
		while move_allowed(tetromino.get_pattern(), tetromino.offset() + Vector2(0, 1)):
			print("MOVE DOWN")
			tetromino.move_down() 
		print("@@@@@@@@@@@@@")
	create_new_tetromino()



################################## CONDITION CHECK ######################################

# check movement
func check_movement():
	if Input.is_action_just_pressed("ui_left"):
		stop_move_down_timer()
		movement = MoveStates.ACTIVE
		move_left()
		start_move_down_timer()
		movement = MoveStates.INACTIVE
	elif Input.is_action_just_pressed("ui_right"):
		stop_move_down_timer()
		movement = MoveStates.ACTIVE
		move_right()
		start_move_down_timer()
		movement = MoveStates.INACTIVE
	elif Input.is_action_just_pressed("ui_up"):
		stop_move_down_timer()
		movement = MoveStates.ACTIVE
		rotate()
		start_move_down_timer()
		movement = MoveStates.INACTIVE
	elif Input.is_action_just_pressed("ui_down"):
		stop_move_down_timer()
		movement = MoveStates.ACTIVE
		move_down_fast()
		movement = MoveStates.INACTIVE

# check whether tile is null
func is_tile_null(row, column):
	return grid_tiles[row][column] == null

# check whether the tiles are of same color
func is_matched_color(row, column, color):
	return grid_tiles[row][column]["tile"].color == color

# check whether the tile is a match
func match_at(row, column, color):
	if column > 1:
		if !is_tile_null(row, column - 1) && !is_tile_null(row, column - 2):
			return is_matched_color(row, column - 1, color) && is_matched_color(row, column - 2, color)
	if row > 1:
		if !is_tile_null(row - 1, column) && !is_tile_null(row - 2, column):
			return is_matched_color(row - 1, column, color) && is_matched_color(row - 2, column, color)
	return false

# check whether the move is allowed
func move_allowed(pattern, offset):
	var flag_exist = false
	for row in range(pattern.size() - 1, 0, -1):
		var row_flags = pattern[row]
		for column in row_flags.size():
			if row_flags[column]:
				flag_exist = true
				var grid_position = tetromino_to_grid_coordinate(row, column, offset)
				if grid_position.x < 0 or grid_position.x >= columns or grid_position.y >= rows:
					return false
				if grid_position.y < 0:
					continue
				if !is_tile_null(grid_position.y, grid_position.x):
					return false
	return flag_exist



################################## UTILITY METHODS ######################################

# convert grid coordinate to tetromino coordinate
func grid_to_tetromino_coordinate(column, row, offset):
	var pixel_position = grid_to_pixel(column, row)
	return pixel_to_grid(pixel_position.x, pixel_position.y, get_start_pixel(offset))

# convert tetromino coordinate to grid coordinate
func tetromino_to_grid_coordinate(row, column, offset):
	return Vector2(column + offset.x, row + offset.y)

# convert pixel position to grid position
func pixel_to_grid(pixel_x, pixel_y, start = Vector2(grid_x_start, grid_y_start)):
	var column = round((pixel_x - start.x) / tile_size)
	var row = round((pixel_y - start.y) / tile_size)
	return Vector2(column, row)

# convert grid position to pixel position
func grid_to_pixel(row, column, offset = Vector2(0 , 0)):
	var pixel_x = grid_x_start + (column + offset.x) * tile_size
	var pixel_y = grid_y_start + (row + offset.y) * tile_size
	return Vector2(pixel_x, pixel_y)

# calculate start pixel
func get_start_pixel(offset):
	var x_start = grid_x_start + tile_size * offset.x
	var y_start = grid_y_start + tile_size * offset.y
	return Vector2(x_start, y_start)

# create a new tile
func create_tile():
	return available_tiles[floor(rand_range(0, available_tiles.size()))].instance()

# make grid tiles
func make_grid_tiles():
	var array = []
	for row in rows:
		array.append([])
		for column in columns:
			array[row].append(null)
	return array



################################## TIMER ######################################

func stop_move_down_timer():
	if !get_move_down_timer().is_stopped():
		get_move_down_timer().stop()

func start_move_down_timer():
	if get_move_down_timer().is_stopped():
		get_move_down_timer().start()

func get_move_down_timer():
	return get_parent().get_node("move_down_timer")

func _on_move_down_timer_timeout():
	move_down()

func _on_find_matches_timer_timeout():
	find_matches()

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
	var available_tetrominoes = [
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
			"y_offset": [-2, -3, -3, -3]
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
			"y_offset": [-2, -3, -3, -3]
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
			"y_offset": [-3, -2, -3, -3]
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
			"y_offset": [-3, -3, -2, -3]
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
			"y_offset": [-3, -3, -3, -2]
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
			"y_offset": [-4, -2, -4, -3]
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
			"y_offset": [-3, -3, -3, -3]
		}
	]
	
	func _init():
		#tetromino = available_tetrominoes[floor(rand_range(0, available_tetrominoes.size()))]
		#active_index = floor(rand_range(0, tetromino["patterns"].size()))
		tetromino = available_tetrominoes[0]
		active_index = 0
	
	func get_pattern(index = active_index):
		return tetromino["patterns"][index]
	
	func offset(index = active_index):
		return Vector2(tetromino["x_offset"], tetromino["y_offset"][index])
	
	func move_left():
		tetromino["x_offset"] -= 1
	
	func move_right():
		tetromino["x_offset"] += 1
	
	func move_down():
		for i in tetromino["y_offset"].size():
			tetromino["y_offset"][i] += 1
	
	func next_index():
		var index = active_index + 1
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
	
	func clear_pattern_flag(position):
		tetromino["patterns"][active_index][position.x][position.y] = 0
	