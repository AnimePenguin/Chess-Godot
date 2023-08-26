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
	set_window()

	var values = Create.create_board(Create.DEFUALT_BOARD)
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

func set_window():
	var screen_size = DisplayServer.screen_get_size()

	var lowest_dimension = screen_size[screen_size.min_axis_index()]
	get_window().size = Vector2i.ONE * lowest_dimension * 0.75

	DisplayServer.window_set_position(
		DisplayServer.screen_get_position() +
		(DisplayServer.screen_get_size() - DisplayServer.window_get_size())/2
	)

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

func show_moves(pos: Vector2i):
	if !board[pos.y][pos.x]:
		return

	var piece = board[pos.y][pos.x]

	if piece.team != turn:
		return

	if selected_piece == piece:
		moves.clear()
		selected_piece = null
	else:
		moves = piece.get_moves(board)
		selected_piece = piece

func game_over_dialog(winner: String):
	var dialog := $GameOver

	dialog.dialog_text = winner.capitalize() + " Won the Game!"

	dialog.add_cancel_button("Quit")

	dialog.confirmed.connect(get_tree().reload_current_scene)
	dialog.canceled.connect(get_tree().quit)

	dialog.popup_centered()

func promote_menu(new_pos: Vector2i):
	var menu: Control = selected_piece.get_node("PromoteMenu")
	var vbox: VBoxContainer = menu.get_node("VBox")
	
	var options := ButtonGroup.new()
	
	for i in [4,1,3,2]:
		var piece_texture := AtlasTexture.new()
		piece_texture.atlas = load("res://assets/%s.png" % turn)
		piece_texture.region = Rect2(TILE_SIZE * i, 0, TILE_SIZE, TILE_SIZE)

		var option := Button.new()
		option.icon = piece_texture
		option.toggle_mode = true
		option.button_group = options
		option.set_meta("id", i)

		vbox.add_child(option)

	if selected_piece.team == "white":
		menu.position.x = new_pos.x * TILE_SIZE
	else:
		menu.position.x = (7 - new_pos.x) * TILE_SIZE

	if new_pos.x == 7:
		menu.position.x -= TILE_SIZE * 0.5
	
	menu.show()
	
	await options.pressed
	
	menu.hide()
	
	var new_piece_id = options.get_pressed_button().get_meta("id")
	selected_piece.frame = new_piece_id
	selected_piece.piece_id = new_piece_id
	
	for option in options.get_buttons():
		option.queue_free()

func move_piece(pos: Vector2i, piece: Piece):
	board[piece.pos.y][piece.pos.x] = null
	board[pos.y][pos.x] = piece
	
	piece.last_move_round = round_num

	piece.move_animation(pos)

func make_move(pos: Vector2i):
	var move = moves[pos]
	moves.clear()
	
	move_piece(pos, selected_piece)
	
	round_num += 1

	if move.type == Moves.CAPTURE:
		var timer = get_tree().create_timer(Piece.MOVE_TIME)

		# TODO: IMPLEMENT PROPER WIN/LOSS
		if move.take_piece.piece_id == Piece.KING:
			state = State.ENDED
			game_over_dialog(turn)

		timer.timeout.connect(move.take_piece.queue_free)
	elif move.type == Moves.CASTLE:
		var rook: Piece
		var x: int
		
		if move.side == "long":
			rook = board[pos.y][0]
			x = pos.x + 1
		else:
			rook = board[pos.y][7]
			x = pos.x - 1
			
		move_piece(Vector2i(x, pos.y), rook)
	
	if move.has("promote"):
		$Board.queue_redraw()
		
		state = State.PROMOTING
		
		await promote_menu(pos)
		
		state = State.RUNNING

	turn = "black" if turn == "white" else "white"
	selected_piece = null
