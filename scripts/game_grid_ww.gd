extends Node2D

for column in columns:
		for row in range(rows - 1, 0, -1):
			if is_tile_null(column, row):
				if !is_tile_null(column, row - 1):
					grid_tiles[column][row - 1].move(grid_to_pixel(grid_x_start, grid_y_start, column, row))
					grid_tiles[column][row] = grid_tiles[column][row - 1]
					grid_tiles[column][row - 1] = null

# check whether a match is there in the grid after collapse
func match_after_collapse():
	for column in columns:
		for row in rows:
			if !is_piece_null(column, row):
				if match_at(column, row, grid_pieces[column][row].color):
					find_matches()
					return
