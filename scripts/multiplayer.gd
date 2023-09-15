extends Node
class_name Multiplayer

const PORT = 26355

static func get_chr_map() -> Array:
	var map := []
	
	for chr_range in [[97, 122], [65, 90], [48, 57]]:
		for i in range(chr_range[0], chr_range[1] + 1):
			map.append(String.chr(i))
	
	map.append_array(["+", "-"])
	
	return map

static func encode_ip(ip: String) -> String:
	var map := get_chr_map()
	var base := len(map)
	
	var ip_octets := Array(ip.split(".")).map(func(x): return int(x))
	
	var octet_mask := ip_octets.map(func(x): return floor(x / base))
	var masked_octets := ip_octets.map(func(x): return x % base)
	
	var code := ""
	
	for octet in masked_octets:
		code += map[octet]
	
	var mask_as_number := int("".join(octet_mask))
	
	while mask_as_number >= 1:
		code += str(map[mask_as_number % base])
		mask_as_number = floor(mask_as_number / base)

	return code

static func decode_ip(code: String) -> String:
	var map := get_chr_map()
	var base := len(map)
	
	var mask_part := code.substr(4)
	var mask_as_number := 0
	
	for i in range(len(mask_part)):
		mask_as_number += map.find(mask_part[i]) * (base**i)
	
	var octet_mask := str(mask_as_number).lpad(4, "0").split()
	
	var octets := []
	for i in range(4):
		octets.append(map.find(code[i]) + base * int(octet_mask[i]))

	return ".".join(octets)

# TODO: MULTIPLAYER
func upnp_and_host() -> String:
	var upnp = UPNP.new()
	upnp.discover()

	print(upnp.add_port_mapping(PORT, 0, "Chess-UDP", "UDP"))
	print(upnp.add_port_mapping(PORT, 0, "Chess-TCP", "TCP"))
	
	multiplayer.peer_connected.connect(func(id): print(id))
	
	var peer = WebSocketMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	
	return upnp.query_external_address()

func connect_server(ip: String):
	var peer = WebSocketMultiplayerPeer.new()
	peer.create_client("ws://%s:%s" % [ip, PORT])
	multiplayer.multiplayer_peer = peer
