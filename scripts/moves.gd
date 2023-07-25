class_name Moves

enum {MOVE, CAPTURE, PROMOTE, CASTLE, EN_PASSANT}

const ORTHOGONAL = [[1, 0], [-1, 0], [0, 1], [0, -1]]
const DIAGONAL = [[1, 1], [-1, -1], [-1, 1], [1, -1]]
const OCTO = ORTHOGONAL + DIAGONAL

const L_SHAPE = [[ 2,  1], [ 1,  2], [-1,  2], [-2,  1], 
				 [-2, -1], [-1, -2], [ 1, -2], [ 2, -1]]

static func not_in_range(x, y): return x < 0 or x > 7 or y < 0 or y > 7

static func basic(pos: Vector2, board: Array, directions: Array) -> Dictionary:
	var moves := {}
	
	var color = board[pos.y][pos.x].color
	
	for dir in directions:
		var x = pos.x + dir[0]
		var y = pos.y + dir[1]

		if not_in_range(x, y):
			continue

		var tile = board[y][x]
		
		if !tile:
			moves[Vector2(x, y)] = {"type": MOVE}
		elif color != tile.color:
			moves[Vector2(x, y)] = {
					"type": CAPTURE, "take_piece": tile
				}

	return moves

static func line(pos: Vector2, board: Array, directions: Array) -> Dictionary:
	var moves := {}
	
	var color = board[pos.y][pos.x].color
	
	for dir in directions:
		for i in range(1, 10):
			var x = pos.x + (dir[0] * i)
			var y = pos.y + (dir[1] * i)

			if not_in_range(x, y):
				break

			var tile = board[y][x]
			
			if !tile:
				moves[Vector2(x, y)] = {"type": MOVE}
				continue
				
			if color != tile.color:
				moves[Vector2(x, y)] = {
						"type": CAPTURE, "take_piece": tile
					}

			break

	return moves

static func pawn(pos: Vector2, board: Array, round_num: int) -> Dictionary:
	var moves := {}

	var piece = board[pos.y][pos.x]
	
	var move_dir = 1 if piece.color == "black" else -1
	
	# Move
	var possible_moves := [Vector2(0, move_dir)]
	
	if not piece.last_move_round:
		possible_moves.append(Vector2(0, move_dir * 2))
	
	for move in possible_moves:
		if board[pos.y + move.y][pos.x]:
			break
			
		moves[pos + move] = {"type": MOVE}
	
	# Attack
	for attack_dir in [-1, 1]:
		var x = pos.x + attack_dir
		var y = pos.y + move_dir
		
		if not_in_range(x, y) or not board[y][x]:
			continue
		
		if piece.color != board[y][x].color:
			moves[Vector2(x, y)] = {
					"type": CAPTURE, "take_piece": board[y][x]
				}
	
	return moves

static func king(pos: Vector2, board: Array) -> Dictionary:
	var moves := {}
	
	var piece = board[pos.y][pos.x]
	
	moves.merge(basic(pos, board, OCTO))
	
	var castle = func():
		if piece.last_move_round:
			return
		
	castle.call()
	
	return moves
