extends Node2D

const TILE_SIZE := Global.TILE_SIZE

enum State {RUNNING, ENDED, PROMOTING}

var board: Array

var selected_piece: Piece
var moves: Dictionary

var round_num: int = 1
var turn := "white"

var state: State = State.RUNNING

func _ready():
	var values = Create.create_board(Create.DEFAULT_BOARD)
	board = values["board"]

	values["node"].name = "Pieces"
	add_child(values["node"])

func _unhandled_input(event):
	if state: return # if the state is not RUNNING, then return
	
	if event.is_action_pressed("left_click"):
		var pos := get_tile_pos()

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

	# When rotated, the board goes out of the viewport, this moves it back
	var movement = Vector2.ONE * TILE_SIZE * 8
	position += -movement if position else movement

func get_tile_pos() -> Vector2i:
	var mouse_pos = get_local_mouse_position()
	var pos = (mouse_pos / TILE_SIZE).floor()

	return pos.clamp(Vector2i.ZERO, Vector2i(7, 7))

func get_legal_moves(piece: Piece) -> Dictionary:
	var piece_moves = piece.get_moves(board)
	
	var original_pos := piece.pos
	
	for move in piece_moves.keys():
		var take_piece: Piece = null

		if piece_moves[move].type == Moves.CAPTURE:
			take_piece = piece_moves[move].take_piece
			board[take_piece.pos.y][take_piece.pos.x] = null

		board[piece.pos.y][piece.pos.x] = null
		board[move.y][move.x] = piece
		piece.pos = move

		if is_in_check(): piece_moves.erase(move)
		
		piece.pos = original_pos
		board[move.y][move.x] = null
		board[piece.pos.y][piece.pos.x] = piece

		if take_piece:
			board[take_piece.pos.y][take_piece.pos.x] = take_piece
	
	return piece_moves

func no_legal_moves() -> bool:
	for row in board:
		for piece in row:
			if !piece or piece.team != turn:
				continue
			
			if get_legal_moves(piece).size():
				return false
			
	return true

func is_in_check() -> bool:
	for row in board:
		for piece in row:
			if !piece or piece.team == turn:
				continue
			
			var piece_moves: Dictionary = piece.get_moves(board)
			
			for move in piece_moves.values():
				if move.type != Moves.CAPTURE:
					continue
				
				if move.take_piece.piece_id == Piece.KING:
					return true
	
	return false

func show_moves(pos: Vector2i):
	if !board[pos.y][pos.x]:
		return

	var piece: Piece = board[pos.y][pos.x]

	if piece.team != turn:
		return

	if selected_piece == piece:
		moves.clear()
		selected_piece = null
		return

	moves = get_legal_moves(piece)
	selected_piece = piece

func game_over_dialog(text: String):
	var dialog := $GameOver

	dialog.dialog_text = text

	dialog.add_cancel_button("Quit")

	dialog.confirmed.connect(get_tree().reload_current_scene)
	dialog.canceled.connect(get_tree().quit)

	dialog.popup_centered()

func move_piece(pos: Vector2i, piece: Piece):
	board[piece.pos.y][piece.pos.x] = null
	board[pos.y][pos.x] = piece
	
	piece.last_move_round = round_num
	
	piece.pos = pos
	piece.move_animation(pos)

func make_move(pos: Vector2i):
	var move = moves[pos]
	moves.clear()
	
	move_piece(pos, selected_piece)
	
	round_num += 1

	if move.type == Moves.CAPTURE:
		var timer = get_tree().create_timer(Piece.MOVE_TIME)
		timer.timeout.connect(move.take_piece.queue_free)
		
	elif move.type == Moves.CASTLE and not is_in_check():
		var rook: Piece
		var x := pos.x
		
		if move.side == "long":
			rook = board[pos.y][0]
			x += 1
		else:
			rook = board[pos.y][7]
			x -= 1
			
		move_piece(Vector2i(x, pos.y), rook)
	
	if move.has("promote"):
		$Board.queue_redraw()
		
		state = State.PROMOTING
		
		await selected_piece.promote_menu(pos)
		
		state = State.RUNNING

	turn = "black" if turn == "white" else "white"
	selected_piece = null
	
	if no_legal_moves():
		state = State.ENDED
		
		if not is_in_check():
			game_over_dialog("Stalemate!")
		
		game_over_dialog(turn.capitalize() + " is Checkmated!")
		
	if is_in_check():
		print("Check!")
