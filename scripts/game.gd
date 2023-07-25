extends Node2D

const TILE_SIZE := 32

var create = Create.new(TILE_SIZE)

var board: Array

var selected_piece: Piece
var moves: Dictionary

var round_num: int = 1
var turn := "white"

func _ready():
	var values = create.create_board(create.DEFUALT_BOARD)
	board = values["board"]
	
	values["node"].name = "Pieces"
	add_child(values["node"])

func _unhandled_input(event):
	if event.is_action_pressed("left_click"):
		var pos = get_tile_pos()
		
		if moves.has(pos):
			make_move(pos)
		else:
			show_moves(pos)
		
		$Board.queue_redraw()
	if event.is_action_pressed("ui_accept"):
		flip_board()

func flip_board():
	rotate(PI)
	
	for child in $Pieces.get_children():
		child.flip_v = not child.flip_v
		child.flip_h = child.flip_v
	
	var movement = Vector2.ONE * TILE_SIZE * 8
	
	position += -movement if position else movement

func get_tile_pos() -> Vector2:
	var mouse_pos = get_local_mouse_position()
	var pos = (mouse_pos / TILE_SIZE).floor()
	
	return pos.clamp(Vector2.ZERO, Vector2(7, 7))

func show_moves(pos: Vector2):
	if !board[pos.y][pos.x]:
		return

	var piece = board[pos.y][pos.x]
	
	if piece.color != turn:
		return
	
	if selected_piece == piece:
		moves.clear()
		selected_piece = null
	else:
		moves = piece.get_moves(board)
		selected_piece = piece

func make_move(pos: Vector2):
	turn = "black" if turn == "white" else "white"
	
	board[selected_piece.pos.y][selected_piece.pos.x] = null
	board[pos.y][pos.x] = selected_piece
	
	selected_piece.last_move_round = round_num
	round_num += 1
	
	selected_piece.move_animation(pos)
	
	if moves[pos].type == Moves.CAPTURE:
		var timer = get_tree().create_timer(Piece.MOVE_TIME)
		timer.timeout.connect(moves[pos].take_piece.queue_free)

	moves.clear()
	selected_piece = null
