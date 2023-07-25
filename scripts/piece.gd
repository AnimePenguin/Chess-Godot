extends Sprite2D
class_name Piece

const MOVE_TIME = 0.15

@export_enum("white", "black") var color := "white"
@export_range(0, 5) var piece_id: int

@onready var game := get_node("/root/Game")
@onready var tile_size = game.TILE_SIZE

var piece_value: int
var last_move_round: int # Used for pawn and king movement

var pos: Vector2:
	get: return position/tile_size

func _ready():
	texture = load("res://assets/%s.png" % color)
	frame = piece_id

	piece_value = [1, 3, 3, 5, 9, 0][piece_id]

func move_animation(new_pos: Vector2):
	var new_position: Vector2 = new_pos * tile_size
	
	# So that the piece always appears on the top
	z_index += 1
	
	await create_tween() \
		.tween_property(self, "position", new_position, MOVE_TIME) \
		.set_ease(Tween.EASE_IN_OUT).finished
	
	z_index -= 1

func get_moves(board: Array) -> Dictionary:
	match piece_id:
		0: return Moves.pawn(pos, board, game.round_num)
		1: return Moves.basic(pos, board, Moves.L_SHAPE)
		2: return Moves.line(pos, board, Moves.DIAGONAL)
		3: return Moves.line(pos, board, Moves.ORTHOGONAL)
		4: return Moves.line(pos, board, Moves.OCTO)
		5: return Moves.king(pos, board)
	
	return {}
