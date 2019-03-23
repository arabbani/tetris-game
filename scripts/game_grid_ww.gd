extends Node2D

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
				var grid_position = tetromino_to_grid_coordinate(offset, column, row)
				grid_tiles[grid_position.x][grid_position.y] = column_tiles[row]
	if game_state != GameStates.GAME_OVER:
		#find_matches()
		active_tetromino = null
		create_new_tetromino()

func _on_destroy_timer_timeout():
	destroy_matched()

func _on_collapse_timer_timeout():
	collapse_columns()




# check whether a match is there in the grid
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

# destroy the matched tiles
func destroy_matched():
	for column in columns:
		for row in rows:
			if !is_tile_null(column, row):
				if grid_tiles[column][row].matched:
					grid_tiles[column][row].queue_free()
					grid_tiles[column][row] = null
					#emit_signal("update_score", piece_value * streak)
	get_parent().get_node("collapse_timer").start()
	current_matches.clear()

# collapse the empty places
func collapse_columns():
	for column in columns:
		for row in range(rows - 1, 0, -1):
			if is_tile_null(column, row):
				if !is_tile_null(column, row - 1):
					grid_tiles[column][row - 1].move(grid_to_pixel(grid_x_start, grid_y_start, column, row))
					grid_tiles[column][row] = grid_tiles[column][row - 1]
					grid_tiles[column][row - 1] = null
	active_tetromino = null
	create_new_tetromino()

# check whether a match is there in the grid after collapse
func match_after_collapse():
	for column in columns:
		for row in rows:
			if !is_piece_null(column, row):
				if match_at(column, row, grid_pieces[column][row].color):
					find_matches()
					return
