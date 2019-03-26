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


################################## DUMMY ######################################

func dummy_tile():
	var tile = available_tiles[1].instance()
	grid_tiles[23][7] = {
		"tile": tile
	}
	add_child(tile)
	tile.position = grid_to_pixel(23, 7)



################################## METHOD OVERRIDE ######################################

func _ready():
	randomize()
	grid_tiles = make_grid()
	game_state = GameStates.PLAYING
	set_movement_active()
	#dummy_tile()
	create_tetromino()

func _process(delta):
	if !is_movement_active():
		check_movement()



################################## CREATE TETROMINO ######################################

# create new tetromino
func create_tetromino():
	active_tetromino = null
	active_tetromino = Tetromino.new()
	grid_tetrominoes.append(active_tetromino)
	create_tetromino_tiles()

# select tiles for the current tetromino
func create_tetromino_tiles():
	var pattern = active_tetromino.get_pattern()
	if pattern != null:
		for row in pattern.size():
			active_tetromino.tiles.append([])
			for column in pattern[row].size():
				active_tetromino.tiles[row].append(null)
				if pattern[row][column]:
					var loops = 0
					var tile = create_tile()
					match active_tetromino.tetromino["name"]:
						"J", "T", "L", "I":
							while tetromino_tile_match(row, column, tile.color) && loops < 100:
								loops += 1
								tile = create_tile()
					add_child(tile)
					tile.position = grid_to_pixel(row, column, active_tetromino.offset())
					active_tetromino.tiles[row][column] = tile
		initial_move()

# create a new tile
func create_tile():
	return available_tiles[floor(rand_range(0, available_tiles.size()))].instance()

# check if the new tile is a match with the exising tetromino tile
func tetromino_tile_match(row, column, color):
	if column > 1:
		if !is_tetromino_tile_null(row, column - 1) and !is_tetromino_tile_null(row, column - 2):
			return is_tetromino_tile_color_matched(row, column - 1, color) and is_tetromino_tile_color_matched(row, column - 2, color)
	if row > 1:
		if !is_tetromino_tile_null(row - 1, column) and !is_tetromino_tile_null(row - 2, column):
			return is_tetromino_tile_color_matched(row - 1, column, color) and is_tetromino_tile_color_matched(row - 2, column, color)
	return false

# check if the tetromino tile is null
func is_tetromino_tile_null(row, column):
	return get_tetromino_tile(row, column) == null

# check if the tetromino tiles are of same color
func is_tetromino_tile_color_matched(row, column, color):
	return get_tetromino_tile(row, column).color == color

# get the tetromino tile
func get_tetromino_tile(row, column):
	return active_tetromino.tiles[row][column]



################################## MOVE TETROMINOES ######################################

# initially move the tetromino into grid
func initial_move():
	for i in active_tetromino.initial_move():
		move_down()
	set_movement_inactive()
	start_move_down_timer()

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
	var rotated_index =  active_tetromino.next_index()
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
		lock_tetromino()

# move tetromino down in one move
func move_down_fast():
	while move_allowed(active_tetromino.get_pattern(), active_tetromino.offset() + Vector2(0, 1)):
		active_tetromino.move_down()
	move_tetromino()
	lock_tetromino()

# check whether the move is allowed
func move_allowed(pattern, offset):
	for row in range(pattern.size() - 1, -1, -1):
		for column in pattern[row].size():
			if pattern[row][column]:
				var grid_position = tetromino_to_grid_coordinate(row, column, offset)
				if grid_position.x < 0 or grid_position.x >= columns or grid_position.y >= rows:
					return false
				if grid_position.y < 0:
					continue
				if !is_grid_tile_null(grid_position.y, grid_position.x):
					if row + 1 < pattern.size():
						if !pattern[row + 1][column]:
							return false
					else:
						return false
	return true

# move tetromino
func move_tetromino(tetromino = active_tetromino):
	var pattern = tetromino.get_pattern()
	for row in range(pattern.size() - 1, -1, -1):
		for column in pattern[row].size():
			if pattern[row][column]:
				var tile = tetromino.tiles[row][column]
				if tile != null:
					tile.move(grid_to_pixel(row, column, tetromino.offset()))



################################## DESTROY MATCHED TILES ######################################

# locks the current tetromino
func lock_tetromino():
	var tiles = active_tetromino.tiles
	for row in range(tiles.size() - 1, -1, -1):
		var row_tiles = tiles[row]
		for column in row_tiles.size():
			var offset = active_tetromino.offset()
			if row_tiles[column] == null:
				continue
			elif (offset.y + row) < 0:
				game_state = GameStates.GAME_OVER
				stop_move_down_timer()
				set_movement_active()
				break
			elif row_tiles[column] != null:
				var grid_position = tetromino_to_grid_coordinate(row, column, offset)
				grid_tiles[grid_position.y][grid_position.x] = {
					"tile": row_tiles[column],
					"tetromino": active_tetromino
				}
	if game_state != GameStates.GAME_OVER:
		get_parent().get_node("find_matches_timer").start()

# check whether there is a match in the grid
func find_matches():
	var match_found = false
	for row in rows:
		for column in columns:
			if !is_grid_tile_null(row, column):
				var color = get_grid_tile(row, column).color
				if row > 0 and row < rows - 1:
					if !is_grid_tile_null(row - 1, column) and !is_grid_tile_null(row + 1, column):
						if is_matched_color(row - 1, column, color) and is_matched_color(row + 1, column, color):
							match_found = true
							match_tile(row - 1, column)
							match_tile(row, column)
							match_tile(row + 1, column)
				if column > 0 and column < columns - 1:
					if !is_grid_tile_null(row, column - 1) and !is_grid_tile_null(row, column + 1):
						if is_matched_color(row, column - 1, color) and is_matched_color(row, column + 1, color):
							match_found = true
							match_tile(row, column - 1)
							match_tile(row, column)
							match_tile(row, column + 1)
	if match_found:
		get_parent().get_node("destroy_timer").start()
	else:
		create_tetromino()

# set the tile as matched
func match_tile(row, column):
	var tile = get_grid_tile(row, column)
	tile.matched = true
	tile.dim()

# destroy matched tiles
func destroy_matched_tiles():
	for row in rows:
		for column in columns:
			if !is_grid_tile_null(row, column):
				if get_grid_tile(row, column).matched:
					var tetromino = grid_tiles[row][column]["tetromino"]
					tetromino.remove_tile(grid_to_tetromino_coordinate(row, column, tetromino.offset()))
					grid_tiles[row][column] = null
	remove_cleared_tetromino()

func remove_cleared_tetromino():
	var remove_tetrominoes = []
	for i in grid_tetrominoes.size():
		var pattern = grid_tetrominoes[i].get_pattern()
		remove_tetrominoes.append(true)
		for row in pattern.size():
			var is_break = false
			for column in pattern[row].size():
				if pattern[row][column]:
					remove_tetrominoes[i] = false
					is_break = true
					break
			if is_break:
				break
	var array = []
	for i in remove_tetrominoes.size():
		if !remove_tetrominoes[i]:
			array.append(grid_tetrominoes[i])
	grid_tetrominoes = array
	get_parent().get_node("collapse_timer").start()

# collapse the tetrominoes
func collapse_tetrominoes():
	for i in grid_tetrominoes.size():
		var tetromino = grid_tetrominoes[i]
		var move_count = 0
		while move_allowed(tetromino.get_pattern(), tetromino.offset() + Vector2(0, 1)):
			tetromino.move_down() 
			move_count += 1
		if move_count > 0:
			var pattern = tetromino.get_pattern()
			var offset = tetromino.offset()
			for row in range(pattern.size() - 1, -1, -1):
				for column in pattern[row].size():
					if pattern[row][column]:
						var current_position = tetromino_to_grid_coordinate(row, column, offset)
						var previous_position = current_position + Vector2(0, -move_count)
						grid_tiles[current_position.y][current_position.x] = grid_tiles[previous_position.y][previous_position.x]
						grid_tiles[previous_position.y][previous_position.x] = null
			move_tetromino(tetromino)
	after_collapse()

func after_collapse():
	for row in rows:
		for column in columns:
			if !is_grid_tile_null(row, column):
				if is_match(row, column, get_grid_tile(row, column).color):
					find_matches()
					return
	create_tetromino()

# check if match exist in the grid
func is_match(row, column, color):
	if column > 1:
		if !is_grid_tile_null(row, column - 1) and !is_grid_tile_null(row, column - 2):
			return is_matched_color(row, column - 1, color) and is_matched_color(row, column - 2, color)
	if row > 1:
		if !is_grid_tile_null(row - 1, column) and !is_grid_tile_null(row - 2, column):
			return is_matched_color(row - 1, column, color) and is_matched_color(row - 2, column, color)
	return false



################################## CONDITION CHECK ######################################

# check movement
func check_movement():
	if Input.is_action_just_pressed("ui_left"):
		stop_move_down_timer()
		set_movement_active()
		move_left()
		start_move_down_timer()
		set_movement_inactive()
	elif Input.is_action_just_pressed("ui_right"):
		stop_move_down_timer()
		set_movement_active()
		move_right()
		start_move_down_timer()
		set_movement_inactive()
	elif Input.is_action_just_pressed("ui_up"):
		stop_move_down_timer()
		set_movement_active()
		rotate()
		start_move_down_timer()
		set_movement_inactive()
	elif Input.is_action_just_pressed("ui_down"):
		stop_move_down_timer()
		set_movement_active()
		move_down_fast()
		set_movement_inactive()

# set movement active
func set_movement_active():
	movement = MoveStates.ACTIVE

# set movement inactive
func set_movement_inactive():
	movement = MoveStates.INACTIVE

# check if movement is active
func is_movement_active():
	return movement == MoveStates.ACTIVE

# check if the grid tile is null
func is_grid_tile_null(row, column):
	return grid_tiles[row][column] == null

# check whether the tiles are of same color
func is_matched_color(row, column, color):
	return get_grid_tile(row, column).color == color



################################## UTILITY METHODS ######################################

# convert grid coordinate to tetromino coordinate
func grid_to_tetromino_coordinate(row, column, offset):
	return Vector2(column - offset.x, row - offset.y)

# convert tetromino coordinate to grid coordinate
func tetromino_to_grid_coordinate(row, column, offset):
	return Vector2(column + offset.x, row + offset.y)

# convert grid position to pixel position
func grid_to_pixel(row, column, offset = Vector2(0 , 0)):
	var pixel_x = grid_x_start + (column + offset.x) * tile_size
	var pixel_y = grid_y_start + (row + offset.y) * tile_size
	return Vector2(pixel_x, pixel_y)

func get_grid_tile(row, column):
	return grid_tiles[row][column]["tile"]

# make grid tiles
func make_grid():
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
	
	func initial_move():
		return tetromino["initial_move"][active_index]
	
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
			var row_tiles = tiles[i]
			var size = row_tiles.size()
			for j in size:
				array[i].append(null)
				array[i][j] = tiles[size - 1 - j][i]
		tiles = array
	
	func remove_tile(position):
		tetromino["patterns"][active_index][position.y][position.x] = 0
		tiles[position.y][position.x].free()
		#tiles[position.y][position.x].queue_free()
		tiles[position.y][position.x] = null
	
