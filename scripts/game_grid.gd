extends Node2D

# grid variables
export(int) var columns
export(int) var rows
export(int) var tile_size
export(int) var grid_x_start
export(int) var grid_y_start

# tiles
var available_tiles : = [
	preload("res://scenes/tile_1.tscn"),
	preload("res://scenes/tile_2.tscn"),
	preload("res://scenes/tile_3.tscn"),
	preload("res://scenes/tile_4.tscn"),
	preload("res://scenes/tile_5.tscn"),
	preload("res://scenes/tile_6.tscn")
]
var blank_tile = preload("res://scenes/blank_tile.tscn")

# game states
enum GameStates { PLAYING, GAME_OVER }
enum MoveStates { ACTIVE, INACTIVE }
var game_state
var movement

# tetromino variables
var grid_tiles = []
var grid_tetrominoes = []
var active_tetromino : Tetromino = null

# obstacles
export(PoolVector2Array) var blank_spaces



################################## DUMMY ######################################

func dummy_tile():
	var tile = available_tiles[1].instance()
	grid_tiles[23][7] = {
		"tile": tile
	}
	add_child(tile)
	tile.position = grid_to_pixel(23, 7)



################################## METHOD OVERRIDE ######################################

func _ready() -> void:
	randomize()
	create_grid()

#warning-ignore:unused_argument
func _process(delta : float) -> void:
	if !is_movement_active():
		check_movement()



################################## CREATE GRID ######################################

# create initial grid
func create_grid() -> void:
	grid_tiles = make_grid_array()
	draw_blank_spaces()

# make grid array
func make_grid_array() -> Array:
	var array = []
	for row in rows:
		array.append([])
		for column in columns:
			array[row].append(null)
	return array



################################## CREATE OBSTACLES ######################################

# draw the blank spaces
func draw_blank_spaces() -> void:
	for i in blank_spaces.size():
		var tile = blank_tile.instance()
		add_child(tile)
		tile.position = grid_to_pixel(blank_spaces[i].y, blank_spaces[i].x)
	start_game()

func start_game() -> void:
	game_state = GameStates.PLAYING
	set_movement_active()
	#dummy_tile()
	create_tetromino()



################################## CREATE TETROMINO ######################################

# create new tetromino
func create_tetromino() -> void:
	active_tetromino = null
	active_tetromino = Tetromino.new()
	grid_tetrominoes.append(active_tetromino)
	create_tetromino_tiles()

# select tiles for the current tetromino
func create_tetromino_tiles() -> void:
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
						"J", "T", "L":
							while tetromino_tile_tripple_match(row, column, tile.type) and loops < 100:
								loops += 1
								tile = create_tile()
						"O":
							while tetromino_tile_box_match(row, column, tile.type) and loops < 100:
								loops += 1
								tile = create_tile()
						"I":
							while (tetromino_tile_tripple_match(row, column, tile.type) or tetromino_tile_duo_match(row, column, tile.type)) and loops < 100:
								loops += 1
								tile = create_tile()
					add_child(tile)
					tile.position = grid_to_pixel(row, column, active_tetromino.offset())
					active_tetromino.tiles[row][column] = tile
		initial_move()

# create a new tile
func create_tile() -> Tile:
	return available_tiles[floor(rand_range(0, available_tiles.size()))].instance()

# check if the tetromino tile is a tripple match
func tetromino_tile_tripple_match(row : int, column : int, type) -> bool:
	if column > 1:
		if !is_tetromino_tile_null(row, column - 1) and !is_tetromino_tile_null(row, column - 2):
			return is_matched_tetromino_tile(row, column - 1, type) and is_matched_tetromino_tile(row, column - 2, type)
	if row > 1:
		if !is_tetromino_tile_null(row - 1, column) and !is_tetromino_tile_null(row - 2, column):
			return is_matched_tetromino_tile(row - 1, column, type) and is_matched_tetromino_tile(row - 2, column, type)
	return false

# check if the tetromino tile is a box match
func tetromino_tile_box_match(row, column, type):
	if column > 0 and row > 0:
		if !is_tetromino_tile_null(row, column - 1) and !is_tetromino_tile_null(row - 1, column) and !is_tetromino_tile_null(row - 1, column - 1):
			return is_matched_tetromino_tile(row, column - 1, type) and is_matched_tetromino_tile(row - 1, column, type) and is_matched_tetromino_tile(row - 1, column - 1, type)
	return false

# check if the tetromino tile is a duo match
func tetromino_tile_duo_match(row : int, column : int, type) -> bool:
	if column > 2:
		if !is_tetromino_tile_null(row, column - 1) and !is_tetromino_tile_null(row, column - 2) and !is_tetromino_tile_null(row, column - 3):
			return is_matched_tetromino_tile(row, column - 1, type) and is_matched_tetromino_tile(row, column - 3, get_tetromino_tile(row, column - 2).type)
	return false

# check if the tetromino tile is null
func is_tetromino_tile_null(row : int, column : int) -> bool:
	return get_tetromino_tile(row, column) == null

# check if the tetromino tiles are of same type
func is_matched_tetromino_tile(row : int, column : int, type) -> bool:
	return get_tetromino_tile(row, column).type == type

# get the tetromino tile
func get_tetromino_tile(row : int, column : int) -> Tile:
	return active_tetromino.tiles[row][column]



################################## MOVE TETROMINOES ######################################

# initially move the tetromino into grid
func initial_move() -> void:
	for i in active_tetromino.initial_move():
		move_down()
	start_move_down_timer()
	set_movement_inactive()

# move tetromino left
func move_left() -> void:
	if move_allowed(active_tetromino.get_pattern(), active_tetromino.offset() + Vector2(-1, 0)):
		active_tetromino.move_left()
		move_tetromino()

# move tetromino right
func move_right() -> void:
	if move_allowed(active_tetromino.get_pattern(), active_tetromino.offset() + Vector2(1, 0)):
		active_tetromino.move_right()
		move_tetromino()

# rotate tetromino
func rotate_tetris() -> void:
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
		active_tetromino.rotate_tetris(rotated_index)
		if wall_kick > 0:
			active_tetromino.move_right()
		elif wall_kick < 0:
			active_tetromino.move_left()
		move_tetromino()

# move tetromino down
func move_down() -> void:
	if move_allowed(active_tetromino.get_pattern(), active_tetromino.offset() + Vector2(0, 1)):
		active_tetromino.move_down()
		move_tetromino()
	else:
		stop_move_down_timer()
		set_movement_active()
		lock_tetromino()

# move tetromino down in one move
func move_down_fast() -> void:
	while move_allowed(active_tetromino.get_pattern(), active_tetromino.offset() + Vector2(0, 1)):
		active_tetromino.move_down()
	move_tetromino()
	lock_tetromino()

# move tetromino
func move_tetromino(tetromino : = active_tetromino) -> void:
	var pattern = tetromino.get_pattern()
	for row in range(pattern.size() - 1, -1, -1):
		for column in pattern[row].size():
			if pattern[row][column]:
				var tile = tetromino.tiles[row][column]
				if tile != null:
					tile.move(grid_to_pixel(row, column, tetromino.offset()))

# check whether the move is allowed
func move_allowed(pattern, offset) -> bool:
	for row in range(pattern.size() - 1, -1, -1):
		for column in pattern[row].size(): 
			if pattern[row][column]:
				var grid_position = tetromino_to_grid_coordinate(row, column, offset)
				if grid_position.x < 0 or grid_position.x >= columns or grid_position.y >= rows:
					return false
				if grid_position.y < 0:
					continue 
				if restricted_move(grid_position):
					return false
				if !is_grid_tile_null(grid_position.y, grid_position.x):
					if row + 1 < pattern.size():
						if !pattern[row + 1][column]:
							return false
					else:
						return false
	return true

# check if obstacles exist
func restricted_move(place : Vector2) -> bool:
	if is_in_array(blank_spaces, place):
		return true
	return false

func is_in_array(array : Array, item : Vector2) -> bool:
	for column in array.size():
		if array[column] == item:
			return true
	return false



################################## DESTROY MATCHED TILES ######################################

# locks the current tetromino
func lock_tetromino() -> void:
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
func find_matches() -> void:
	var match_found = false
	for row in rows:
		for column in columns:
			if !is_grid_tile_null(row, column):
				var type = get_grid_tile(row, column).type
				if row > 0 and row < rows - 1:
					if !is_grid_tile_null(row - 1, column) and !is_grid_tile_null(row + 1, column):
						if is_matched_grid_tile(row - 1, column, type) and is_matched_grid_tile(row + 1, column, type):
							match_found = true
							match_tile(row - 1, column)
							match_tile(row, column)
							match_tile(row + 1, column)
				if column > 0 and column < columns - 1:
					if !is_grid_tile_null(row, column - 1) and !is_grid_tile_null(row, column + 1):
						if is_matched_grid_tile(row, column - 1, type) and is_matched_grid_tile(row, column + 1, type):
							match_found = true
							match_tile(row, column - 1)
							match_tile(row, column)
							match_tile(row, column + 1)
	if match_found:
		get_parent().get_node("destroy_timer").start()
	else:
		create_tetromino()

# check if the grid tile is a tripple match
func grid_tile_tripple_match(row : int, column : int, type) -> bool:
	if column > 1:
		if !is_grid_tile_null(row, column - 1) and !is_grid_tile_null(row, column - 2):
			return is_matched_grid_tile(row, column - 1, type) and is_matched_grid_tile(row, column - 2, type)
	if row > 1:
		if !is_grid_tile_null(row - 1, column) and !is_grid_tile_null(row - 2, column):
			return is_matched_grid_tile(row - 1, column, type) and is_matched_grid_tile(row - 2, column, type)
	return false

# check if the grid tile is a box match
func grid_tile_box_match(row, column, type):
	if column > 0 and row > 0:
		if !is_grid_tile_null(row, column - 1) and !is_grid_tile_null(row - 1, column) and !is_grid_tile_null(row - 1, column - 1):
			return is_matched_grid_tile(row, column - 1, type) and is_matched_grid_tile(row - 1, column, type) and is_matched_grid_tile(row - 1, column - 1, type)
	return false

# check if the grid tile is a duo match
func grid_tile_duo_match(row : int, column : int, type) -> bool:
	if column > 2:
		if !is_grid_tile_null(row, column - 1) and !is_grid_tile_null(row, column - 2) and !is_grid_tile_null(row, column - 3):
			return is_matched_grid_tile(row, column - 1, type) and is_matched_grid_tile(row, column - 3, get_grid_tile(row, column - 2).type)
	return false

# check if the grid tile is null
func is_grid_tile_null(row : int, column : int) -> bool:
	return grid_tiles[row][column] == null

# check whether the tiles are of same type
func is_matched_grid_tile(row : int, column : int, type) -> bool:
	return get_grid_tile(row, column).type == type

func get_grid_tile(row : int, column : int) -> Tile:
	return grid_tiles[row][column]["tile"]

# set the tile as matched
func match_tile(row, column) -> void:
	var tile = get_grid_tile(row, column)
	tile.matched = true
	tile.dim()

# destroy matched tiles
func destroy_matched_tiles() -> void:
	for row in rows:
		for column in columns:
			if !is_grid_tile_null(row, column):
				if get_grid_tile(row, column).matched:
					var tetromino = grid_tiles[row][column]["tetromino"]
					tetromino.remove_tile(grid_to_tetromino_coordinate(row, column, tetromino.offset()))
					grid_tiles[row][column] = null
	remove_cleared_tetromino()

func remove_cleared_tetromino() -> void:
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
func collapse_tetrominoes() -> void:
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

func after_collapse() -> void:
	for row in rows:
		for column in columns:
			if !is_grid_tile_null(row, column):
				var type = get_grid_tile(row, column).type
				if grid_tile_tripple_match(row, column, type) or grid_tile_box_match(row, column, type) or grid_tile_duo_match(row, column, type):
					#find_matches()
					get_parent().get_node("find_matches_timer").start()
					return
	create_tetromino()



################################## CONDITION CHECK ######################################

# check movement
func check_movement() -> void:
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
		rotate_tetris()
		start_move_down_timer()
		set_movement_inactive()
	elif Input.is_action_just_pressed("ui_down"):
		stop_move_down_timer()
		set_movement_active()
		move_down_fast()

# set movement active
func set_movement_active() -> void:
	movement = MoveStates.ACTIVE

# set movement inactive
func set_movement_inactive() -> void:
	movement = MoveStates.INACTIVE

# check if movement is active
func is_movement_active() -> bool:
	return movement == MoveStates.ACTIVE



################################## UTILITY METHODS ######################################

# convert grid coordinate to tetromino coordinate
func grid_to_tetromino_coordinate(row : int, column : int, offset : Vector2) -> Vector2:
	return Vector2(column - offset.x, row - offset.y)

# convert tetromino coordinate to grid coordinate
func tetromino_to_grid_coordinate(row : int, column : int, offset : Vector2) -> Vector2:
	return Vector2(column + offset.x, row + offset.y)

# convert grid position to pixel position
func grid_to_pixel(row : int, column : int, offset : = Vector2(0 , 0)) -> Vector2:
	var pixel_x = grid_x_start + (column + offset.x) * tile_size
	var pixel_y = grid_y_start + (row + offset.y) * tile_size
	return Vector2(pixel_x, pixel_y)



################################## TIMER ######################################

func stop_move_down_timer() -> void:
	if !get_move_down_timer().is_stopped():
		get_move_down_timer().stop()

func start_move_down_timer() -> void:
	if get_move_down_timer().is_stopped():
		get_move_down_timer().start()

func get_move_down_timer() -> Node:
	return get_parent().get_node("move_down_timer")

func _on_move_down_timer_timeout() -> void:
	move_down()

func _on_find_matches_timer_timeout() -> void:
	find_matches()

func _on_destroy_timer_timeout() -> void:
	destroy_matched_tiles()

func _on_collapse_timer_timeout() -> void:
	collapse_tetrominoes()
