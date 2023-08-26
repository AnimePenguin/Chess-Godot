class_name Create

const Piece = preload("res://scenes/piece.tscn")

const DEFUALT_BOARD := [
	["R", "N", "B", "Q", "K", "B", "N", "R"],
	["P", "P", "P", "P", "P", "P", "P", "P"],
	["",  "",  "",  "",  "",  "",  "",  "" ],
	["",  "",  "",  "",  "",  "",  "",  "" ],
	["",  "",  "",  "",  "",  "",  "",  "" ],
	["",  "",  "",  "",  "",  "",  "",  "" ],
	["p", "p", "p", "p", "p", "p", "p", "p"],
	["r", "n", "b", "q", "k", "b", "n", "r"],
]

enum Symbols {P, N, B, R, Q, K}

static func create_piece(symbol: String, x: int, y: int) -> Piece:
	# If symbol is lower case, it's white
	# If symbol is upper case, it's black
	var color = "white" if symbol == symbol.to_lower() else "black"
	
	var piece = Piece.instantiate()
	
	piece.piece_id = Symbols[symbol.to_upper()]
	piece.team = color
	piece.position = Vector2(x, y) * Global.TILE_SIZE
	
	return piece

static func create_board(from_board: Array) -> Dictionary:
	var board := [[], [], [], [], [], [], [], []]
	var anchor_node := Node2D.new() # A node to keep the pieces
	
	for y in range(8):
		for x in range(8):
			if !from_board[y][x]:
				board[y].append(null)
				continue
				
			var piece = create_piece(DEFUALT_BOARD[y][x], x, y)
			board[y].append(piece)
			anchor_node.add_child(piece)
	
	return {"board": board, "node": anchor_node}
