extends Node2D

enum Tile_Colors { color_1, color_2, color_3, color_4, color_5, color_6 }
export(Tile_Colors) var color

var move_tween
var matched = false

func _ready():
	move_tween = get_node("move_tween")

# move the tile
func move(target):
	move_tween.interpolate_property(self, "position", position, target, 0.3, 
	                            Tween.TRANS_SINE, Tween.EASE_OUT)
	move_tween.start()

func dim():
	get_node("Sprite").modulate = Color(1, 1, 1, .5)
