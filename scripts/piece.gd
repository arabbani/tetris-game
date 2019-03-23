extends Node2D

export(String) var color
export(Texture) var row_bomb_texture
export(Texture) var column_bomb_texture
export(Texture) var adjacent_bomb_texture

var move_tween
var matched = false
var is_row_bomb = false
var is_column_bomb = false
var is_adjacent_bomb = false

func _ready():
	move_tween = get_node("move_tween")

func move(target):
	move_tween.interpolate_property(self, "position", position, target, 0.3, 
	                            Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	move_tween.start()

func make_column_bomb():
	is_column_bomb = true
	$Sprite.texture = column_bomb_texture
	$Sprite.modulate = Color(1, 1, 1, 1)

func make_row_bomb():
	is_row_bomb = true
	$Sprite.texture = row_bomb_texture
	$Sprite.modulate = Color(1, 1, 1, 1)

func make_adjacent_bomb():
	is_adjacent_bomb = true
	$Sprite.texture = adjacent_bomb_texture
	$Sprite.modulate = Color(1, 1, 1, 1)

func dim():
	get_node("Sprite").modulate = Color(1, 1, 1, .5)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
