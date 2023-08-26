extends Sprite2D
class_name Piece

const MOVE_TIME = 0.15

enum {
	PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING
}

var team := "white"
var piece_id = PAWN

@onready var game := get_node("/root/Game")
@onready var TILE_SIZE = Global.TILE_SIZE

var piece_value: int
var last_move_round: int # Used for pawn and king movement

var pos: Vector2i:
	get: return position/TILE_SIZE

func _ready():
	texture = load("res://assets/%s.png" % team)
	frame = piece_id

	piece_value = [1, 3, 3, 5, 9, 0][piece_id]

func move_animation(new_pos: Vector2i):
	var new_position: Vector2 = new_pos * TILE_SIZE
	
	# So that the piece always appears on the top
	z_index += 1
	
	await create_tween() \
		.tween_property(self, "position", new_position, MOVE_TIME) \
		.set_ease(Tween.EASE_IN_OUT).finished
	
	z_index -= 1

func get_moves(board: Array) -> Dictionary:
	match piece_id:
		PAWN: return Moves.pawn(pos, board, game.round_num)
		KNIGHT: return Moves.basic(pos, board, Moves.L_SHAPE)
		BISHOP: return Moves.line(pos, board, Moves.DIAGONAL)
		ROOK: return Moves.line(pos, board, Moves.ORTHOGONAL)
		QUEEN: return Moves.line(pos, board, Moves.OCTO)
		KING: return Moves.king(pos, board)
	
	return {}
