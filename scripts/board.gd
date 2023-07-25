extends Sprite2D

@onready var parent = get_parent()
@onready var tile_size = parent.TILE_SIZE

func _draw():
	var moves = parent.moves
	
	for move in moves:
		var pos = (move + Vector2(0.5, 0.5)) * tile_size
		
		match moves[move].type:
			Moves.MOVE:
				draw_circle(pos, tile_size/8, Color("000", 0.5))
			Moves.CAPTURE:
				draw_arc(pos, tile_size/2.5, 0, TAU, 16, Color("000", 0.7))