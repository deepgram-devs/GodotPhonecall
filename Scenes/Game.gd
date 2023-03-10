extends Node

var client = WebSocketClient.new()

var phone_number = null
var code = null
var connected_to_phone = false

var full_transcript = ""

func _ready():
	client.connect("connection_closed", self, "_closed")
	client.connect("connection_error", self, "_closed")
	client.connect("connection_established", self, "_connected")
	client.connect("data_received", self, "_on_data")

	var err = client.connect_to_url("https://localhost:5000/game")
	if err != OK:
		print("Unable to connect")
		set_process(false)

func _closed(was_clean = false):
	print("Closed, clean: ", was_clean)
	set_process(false)

func _connected(proto = ""):
	print("Connected with protocol: ", proto)
	client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)

func _on_data():
	var message = client.get_peer(1).get_packet().get_string_from_utf8()

	if phone_number == null:
		phone_number = message
		$CanvasLayer/MarginContainer/VBoxContainer/PhoneNumberLabel.text = "PHONE NUMBER: " + message
	elif code == null:
		code = message
		$CanvasLayer/MarginContainer/VBoxContainer/CodeLabel.text = "CODE: " + code
	elif !connected_to_phone:
		if message == "connected":
			connected_to_phone = true
			client.get_peer(1).put_packet("What kind of pizza do you want? We have cheese, pepperoni, and mushroom.".to_utf8())
	else:
		var message_json = JSON.parse(message)
		if message_json.error == OK:
			if typeof(message_json.result) == TYPE_DICTIONARY:
				if message_json.result.has("is_final"):
					var transcript = message_json.result["channel"]["alternatives"][0]["transcript"]
					if transcript != "":
						if full_transcript != "":
							full_transcript += " "
						full_transcript += transcript
						$CanvasLayer/MarginContainer/VBoxContainer/StreamingTranscriptLabel.text = full_transcript

						if "cheese" in transcript:
							client.get_peer(1).put_packet("One cheese pizza coming up.".to_utf8())
							$CanvasLayer/MarginContainer/VBoxContainer/PizzaLabel.text = "PIZZA: CHEESE"
						if "pepperoni" in transcript:
							client.get_peer(1).put_packet("One pepperoni pizza coming up.".to_utf8())
							$CanvasLayer/MarginContainer/VBoxContainer/PizzaLabel.text = "PIZZA: PEPPERONI"
						if "mushroom" in transcript:
							client.get_peer(1).put_packet("One mushroom pizza coming up.".to_utf8())
							$CanvasLayer/MarginContainer/VBoxContainer/PizzaLabel.text = "PIZZA: MUSHROOM"

func _process(_delta):
	client.poll()
