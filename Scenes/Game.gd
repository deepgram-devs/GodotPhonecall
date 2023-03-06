extends Node

var client = WebSocketClient.new()

var code = null

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

func _on_data():
	var message = client.get_peer(1).get_packet().get_string_from_utf8()
	
	if code == null:
		code = message
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
						$CanvasLayer/StreamingTranscriptLabel.text = full_transcript
					

func _process(_delta):
	client.poll()
