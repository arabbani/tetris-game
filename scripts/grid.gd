extends Node2D











for i in grid_tetrominoes.size():
		var tetromino = grid_tetrominoes[i]
		while move_allowed(tetromino.get_pattern(), tetromino.offset() + Vector2(0, 1)):
			print("MOVE DOWN")
			tetromino.move_down() 
			var pattern = tetromino.get_pattern()
			var offset = tetromino.offset()
			for column in pattern.size():
				var pattern_flags = pattern[column]
				for row in pattern_flags.size():
					if pattern_flags[row]:
						var previous_grid_position = tetromino_to_grid_coordinate(column, row, offset - Vector2(0, 1))
						var current_grid_position = tetromino_to_grid_coordinate(column, row, offset)
						grid_tiles[current_grid_position.x][current_grid_position.y] = grid_tiles[previous_grid_position.x][previous_grid_position.y]
						grid_tiles[previous_grid_position.x][previous_grid_position.y] = null
		move_tetromino(tetromino)












# Grid Variables
export(int) var number_of_columns
export(int) var number_of_rows
export(int) var x_start
export(int) var y_start
export(int) var offset
export(int) var refill_y_offset

# available pieces
var available_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn")
]

# The current pieces in the scene
var grid_pieces = []
var current_matches = []

# Touch variables
var first_touch = Vector2(0, 0)
var final_touch = Vector2(0, 0)
var controlling_grid = false

# State machine
enum { wait, move }
var state

# Swap Back variables
var piece_one = null
var piece_two = null
var last_place = Vector2(0,0)
var last_direction = Vector2(0,0)
var move_checked = false

# Obstacles
export(PoolVector2Array) var empty_spaces
export(PoolVector2Array) var ice_spaces
export(PoolVector2Array) var licorice_spaces
export(PoolVector2Array) var concrete_spaces
export(PoolVector2Array) var slime_spaces
var damaged_slime = false

# Obstacle signals
signal make_ice
signal damage_ice
signal make_licorice
signal damage_licorice
signal make_concrete
signal damage_concrete
signal make_slime
signal damage_slime

# Scoring variables
signal update_score
export(int) var piece_value
var streak = 1

func _ready():
	state = move
	randomize()
	grid_pieces = make_2d_array()
	spawn_new_pieces()
	spawn_ice()
	spawn_licorice()
	spawn_concrete()
	spawn_slime()

# Check if fill is not permitted
func restricted_fill(place):
	if is_in_array(empty_spaces, place):
		return true
	if is_in_array(concrete_spaces, place):
		return true
	if is_in_array(slime_spaces, place):
		return true
	return false

# Check if move is not permitted
func restricted_move(place):
	if is_in_array(licorice_spaces, place):
		return true
	return false

func is_in_array(array, item):
	for column in array.size():
		if array[column] == item:
			return true
	return false

# Create new pieces
func spawn_new_pieces():
	for column in number_of_columns:
		for row in number_of_rows:
			if !restricted_fill(Vector2(column, row)):
				var number_of_loops = 0
				# Choose a random number
				var random_number = floor(rand_range(0, available_pieces.size()))
				# Instance the piece from the available_pieces array
				var piece = available_pieces[random_number].instance()
				# Check if the new piece is already a match and run the loop for a maximum of 100 times
				while(match_at(column, row, piece.color) && number_of_loops < 100):
					random_number = floor(rand_range(0, available_pieces.size()))
					number_of_loops += 1
					piece = available_pieces[random_number].instance()
				add_child(piece)
				piece.position = grid_to_pixel(column, row)
				grid_pieces[column][row] = piece

# Spawn ice
func spawn_ice():
	for column in ice_spaces.size():
		emit_signal("make_ice", ice_spaces[column])

# Spawn licorice
func spawn_licorice():
	for column in licorice_spaces.size():
		emit_signal("make_licorice", licorice_spaces[column])

# Spawn concrete
func spawn_concrete():
	for column in concrete_spaces.size():
		emit_signal("make_concrete", concrete_spaces[column])

# Spawn slime
func spawn_slime():
	for column in slime_spaces.size():
		emit_signal("make_slime", slime_spaces[column])

# Check if the user touched the screen
func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)):
			first_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			controlling_grid = true
	if Input.is_action_just_released("ui_touch"):
		if controlling_grid && is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)):
			final_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			swap_direction(first_touch, final_touch)
			controlling_grid = false

# Swap the piece in the direction
func swap_pieces(column, row, direction):
	var first_piece = grid_pieces[column][row]
	var second_piece = grid_pieces[column + direction.x][row + direction.y]
	if first_piece != null && second_piece != null:
		if !restricted_move(Vector2(column, row)) && !restricted_move(Vector2(column, row) + direction):
			store_swap_info(first_piece, second_piece, Vector2(column, row), direction)
			state = wait
			grid_pieces[column][row] = second_piece
			grid_pieces[column + direction.x][row + direction.y] = first_piece
			first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
			second_piece.move(grid_to_pixel(column, row))
			if !move_checked:
				find_matches()

func store_swap_info(first_piece, second_piece, place, direction):
	piece_one = first_piece
	piece_two = second_piece
	last_place = place
	last_direction = direction
	

# Swap back if no match is found
func swap_back():
	if piece_one != null && piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = move
	move_checked = false

# Decide the direction of swap
func swap_direction(first_grid, second_grid):
	var difference = second_grid - first_grid
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(first_grid.x, first_grid.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(first_grid.x, first_grid.y, Vector2(-1, 0))
	elif abs(difference.x) < abs(difference.y):
		if difference.y > 0:
			swap_pieces(first_grid.x, first_grid.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(first_grid.x, first_grid.y, Vector2(0, -1))

# Check whether a match is there in the grid
func find_matches():
	for column in number_of_columns:
		for row in number_of_rows:
			if grid_pieces[column][row] != null:
				var current_color = grid_pieces[column][row].color
				if column > 0 && column < number_of_columns - 1:
					if !is_piece_null(column - 1, row) && !is_piece_null(column + 1, row):
						if grid_pieces[column - 1][row].color == current_color && grid_pieces[column + 1][row].color == current_color:
							match_and_dim(grid_pieces[column - 1][row])
							match_and_dim(grid_pieces[column][row])
							match_and_dim(grid_pieces[column + 1][row])
							add_to_array(Vector2(column, row))
							add_to_array(Vector2(column + 1, row))
							add_to_array(Vector2(column - 1, row))
				if row > 0 && row < number_of_rows - 1:
					if !is_piece_null(column, row - 1) && !is_piece_null(column, row + 1):
						if grid_pieces[column][row - 1].color == current_color && grid_pieces[column][row + 1].color == current_color:
							match_and_dim(grid_pieces[column][row - 1])
							match_and_dim(grid_pieces[column][row])
							match_and_dim(grid_pieces[column][row + 1])
							add_to_array(Vector2(column, row))
							add_to_array(Vector2(column, row + 1))
							add_to_array(Vector2(column, row - 1))
	get_bombed_pieces()
	get_parent().get_node("destroy_timer").start()

func get_bombed_pieces():
	for column in number_of_columns:
		for row in number_of_rows:
			if grid_pieces[column][row] != null:
				if grid_pieces[column][row].matched:
					if grid_pieces[column][row].is_column_bomb:
						match_all_in_column(column)
					elif grid_pieces[column][row].is_row_bomb:
						match_all_in_row(row)
					elif grid_pieces[column][row].is_adjacent_bomb:
						find_adjacent_pieces(column, row)

func add_to_array(value, array_to_add = current_matches):
	if !array_to_add.has(value):
		array_to_add.append(value)

func is_piece_null(column, row):
	if grid_pieces[column][row] == null:
		return true
	return false

func match_and_dim(item):
	item.matched = true
	item.dim()

func find_bombs():
	# Iterate over the current_matches array
	for column in current_matches.size():
		# Store some values for this match
		var current_column = current_matches[column].x
		var current_row = current_matches[column].y
		var current_color = grid_pieces[current_column][current_row].color
		var column_matched = 0
		var row_matched = 0
		# Iterate over the current_matches to check for column, row and color
		for i in current_matches.size():
			var this_column = current_matches[i].x
			var this_row = current_matches[i].y
			var this_color = grid_pieces[current_column][current_row].color
			if this_column == current_column && this_color == current_color:
				column_matched += 1
			if this_row == current_row && this_color == current_color:
				row_matched += 1
		if column_matched == 5 or row_matched == 5:
			print("Color Bomb")
			return
		elif column_matched == 3 and row_matched == 3:
			make_bomb(0, current_color)
			return
		elif column_matched == 4:
			make_bomb(1, current_color)
			return
		elif row_matched == 4:
			make_bomb(2, current_color)
			return

func make_bomb(bomb_type, color):
	for column in current_matches.size():
		var current_column = current_matches[column].x
		var current_row = current_matches[column].y
		if grid_pieces[current_column][current_row] == piece_one and piece_one.color == color:
			piece_one.matched = false
			change_bomb(bomb_type, piece_one)
		if grid_pieces[current_column][current_row] == piece_two and piece_two.color == color:
			piece_two.matched = false
			change_bomb(bomb_type, piece_two)

func change_bomb(bomb_type, piece):
	if bomb_type == 0:
		piece.make_adjacent_bomb()
	elif bomb_type == 1:
		piece.make_row_bomb()
	elif bomb_type == 2:
		piece.make_column_bomb()

# destroy the matched pieces
func destroy_matched():
	find_bombs()
	var was_matched = false
	for column in number_of_columns:
		for row in number_of_rows:
			if !is_piece_null(column, row):
				if grid_pieces[column][row].matched:
					destroy_special(column, row)
					was_matched = true
					grid_pieces[column][row].queue_free()
					grid_pieces[column][row] = null
					emit_signal("update_score", piece_value * streak)
	move_checked = true
	if was_matched:
		get_parent().get_node("collapse_timer").start()
	else:
		swap_back()
	current_matches.clear()

func check_concrete(column, row):
	if column < number_of_columns - 1:
		emit_signal("damage_concrete", Vector2(column + 1, row))
	if column > 0:
		emit_signal("damage_concrete", Vector2(column - 1, row))
	if row < number_of_rows - 1:
		emit_signal("damage_concrete", Vector2(column, row + 1))
	if row > 0:
		emit_signal("damage_concrete", Vector2(column, row - 1))

func check_slime(column, row):
	if column < number_of_columns - 1:
		emit_signal("damage_slime", Vector2(column + 1, row))
	if column > 0:
		emit_signal("damage_slime", Vector2(column - 1, row))
	if row < number_of_rows - 1:
		emit_signal("damage_slime", Vector2(column, row + 1))
	if row > 0:
		emit_signal("damage_slime", Vector2(column, row - 1))

func destroy_special(column, row):
	emit_signal("damage_ice", Vector2(column, row))
	emit_signal("damage_licorice", Vector2(column, row))
	check_concrete(column, row)
	check_slime(column, row)

# Collapse the empty places
func collapse_columns():
	for column in number_of_columns:
		for row in number_of_rows:
			if is_piece_null(column, row) && !restricted_fill(Vector2(column, row)):
				for k in range(row + 1, number_of_rows):
					if grid_pieces[column][k] != null:
						grid_pieces[column][k].move(grid_to_pixel(column, row))
						grid_pieces[column][row] = grid_pieces[column][k]
						grid_pieces[column][k] = null
						break
	get_parent().get_node("refill_timer").start()

# Refill the empty columns
func refill_columns():
	streak += 1
	for column in number_of_columns:
		for row in number_of_rows:
			if is_piece_null(column, row) && !restricted_fill(Vector2(column, row)):
				var number_of_loops = 0
				# Choose a random number
				var random_number = floor(rand_range(0, available_pieces.size()))
				# Instance the piece from the available_pieces array
				var piece = available_pieces[random_number].instance()
				# Check if the new piece is already a match and run the loop for a maximum of 100 times
				while(match_at(column, row, piece.color) && number_of_loops < 100):
					random_number = floor(rand_range(0, available_pieces.size()))
					number_of_loops += 1
					piece = available_pieces[random_number].instance()
				add_child(piece)
				piece.position = grid_to_pixel(column, row - refill_y_offset)
				piece.move(grid_to_pixel(column, row))
				grid_pieces[column][row] = piece
	after_refill()

# Check whether there is a match after refill
func after_refill():
	for column in number_of_columns:
		for row in number_of_rows:
			if !is_piece_null(column, row):
				if match_at(column, row, grid_pieces[column][row].color):
					find_matches()
					return
	if !damaged_slime:
		generate_slime()
	state = move
	streak = 1
	move_checked = false
	damaged_slime = false

func generate_slime():
	# Make sure there are slime pieces on the board
	if slime_spaces.size() > 0:
		var slime_made = false
		var tracker = 0
		while !slime_made && tracker < 100:
			#Check a random slime
			var random_number = floor(rand_range(0, slime_spaces.size()))
			var current_x = slime_spaces[random_number].x
			var current_y = slime_spaces[random_number].y
			var neighbor = find_normal_neighbor(current_x, current_y)
			if neighbor != null:
				# Turn that neighbor into a slime
				# Remove that piece
				grid_pieces[neighbor.x][neighbor.y].queue_free()
				# Set it to null
				grid_pieces[neighbor.x][neighbor.y] = null
				# Add this new spot to slime array
				slime_spaces.append(Vector2(neighbor.x, neighbor.y))
				# Send a signal to the slime holder to make a new slime
				emit_signal("make_slime", Vector2(neighbor.x, neighbor.y))
				slime_made = true
			tracker +=1

func find_normal_neighbor(column, row):
	# Check right
	if is_in_grid(Vector2(column + 1, row)):
		if grid_pieces[column + 1][row] != null:
			return Vector2(column + 1, row)
	# Check left
	if is_in_grid(Vector2(column - 1, row)):
		if grid_pieces[column - 1][row] != null:
			return Vector2(column - 1, row)
	# Check up
	if is_in_grid(Vector2(column, row + 1)):
		if grid_pieces[column][row + 1] != null:
			return Vector2(column, row + 1)
	# Check down
	if is_in_grid(Vector2(column, row - 1)):
		if grid_pieces[column][row - 1] != null:
			return Vector2(column, row - 1)
	return null

# Check whether the piece is a match
func match_at(column, row, color):
	if column > 1:
		if !is_piece_null(column - 1, row) && !is_piece_null(column - 2, row):
			if grid_pieces[column - 1][row].color == color && grid_pieces[column - 2][row].color == color:
				return true
	if row > 1:
		if !is_piece_null(column, row - 1) && !is_piece_null(column, row - 2):
			if grid_pieces[column][row - 1].color == color && grid_pieces[column][row - 2].color == color:
				return true
	return false

func is_in_grid(grid_position):
	if grid_position.x >= 0 && grid_position.x < number_of_columns:
		if grid_position.y >= 0 && grid_position.y < number_of_rows:
			return true
	return false

# Make a 2d array
func make_2d_array():
	var array = []
	for column in number_of_columns:
		array.append([])
		for row in number_of_rows:
			array[column].append(null)
	return array

# Convert grid position to pixel position
func grid_to_pixel(column, row):
	var pixel_x = x_start + column * offset
	var pixel_y = y_start + row * -offset
	return Vector2(pixel_x, pixel_y)

# Convert pixel position to grid position
func pixel_to_grid(pixel_x, pixel_y):
	var column = round((pixel_x - x_start) / offset)
	var row = round((pixel_y - y_start) / -offset)
	return Vector2(column, row)

func _process(delta):
	if state == move:
		touch_input()

func match_all_in_column(column):
	for row in number_of_rows:
		if grid_pieces[column][row] != null:
			if grid_pieces[column][row].is_row_bomb:
				match_all_in_row(row)
			if grid_pieces[column][row].is_adjacent_bomb:
				find_adjacent_pieces(column, row)
			grid_pieces[column][row].matched = true

func match_all_in_row(row):
	for column in number_of_columns:
		if grid_pieces[column][row] != null:
			if grid_pieces[column][row].is_column_bomb:
				match_all_in_column(column)
			if grid_pieces[column][row].is_adjacent_bomb:
				find_adjacent_pieces(column, row)
			grid_pieces[column][row].matched = true

func find_adjacent_pieces(column, row):
	for i in range(-1, 2):
		for j in range(-1, 2):
			if is_in_grid(Vector2(column + i, row + j)):
				if grid_pieces[column + i][row + j] != null:
					if grid_pieces[column][i].is_row_bomb:
						match_all_in_row(row)
					if grid_pieces[i][row].is_column_bomb:
						match_all_in_column(column)
					grid_pieces[column + i][row + j].matched = true

func _on_destroy_timer_timeout():
	destroy_matched()

func _on_collapse_timer_timeout():
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()

func _on_licorice_holder_remove_licorice(place):
	for i in range(licorice_spaces.size() - 1, -1, -1):
		if licorice_spaces[i] == place:
			licorice_spaces.remove(i)

func _on_concrete_holder_remove_concrete(place):
	for i in range(concrete_spaces.size() - 1, -1, -1):
		if concrete_spaces[i] == place:
			concrete_spaces.remove(i)

func _on_slime_holder_remove_slime(place):
	damaged_slime = true
	for i in range(slime_spaces.size() - 1, -1, -1):
		if slime_spaces[i] == place:
			slime_spaces.remove(i)
