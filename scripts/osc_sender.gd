extends Node

var udp := PacketPeerUDP.new()
var target_ip = "127.0.0.1"  # Localhost
var target_port = 9000       # Same port as in your VST plugin

func _ready():
	udp.connect_to_host(target_ip, target_port)
	send_osc_string("/DrumPerformer/setSample", "testPath")

func _osc_pad_string(s: String) -> PackedByteArray:
	var bytes = s.to_utf8_buffer()
	bytes.append(0)  # Null terminator
	while bytes.size() % 4 != 0:
		bytes.append(0)
	return bytes
	
func send_osc_string(address: String, s: String):
	var packet := PackedByteArray()
	packet.append_array(_osc_pad_string(address))
	packet.append_array(_osc_pad_string(",s"))

	var str_bytes = s.to_utf8_buffer()
	str_bytes.append(0)  # OSC requires null terminator
	while str_bytes.size() % 4 != 0:
		str_bytes.append(0)  # 4-byte padding
	packet.append_array(str_bytes)

	udp.put_packet(packet)
