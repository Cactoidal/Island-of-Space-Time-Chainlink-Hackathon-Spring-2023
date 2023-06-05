var http_request_delete
func summon():
	var http_request = HTTPRequest.new()
	get_parent().get_node("Summoning").add_child(http_request)
	http_request_delete = http_request
	http_request.connect("request_completed", self, "upload_image")

	var body = JSON.print({"prompt": User.ai_query, "n": 1, "size": "256x256", "response_format": "b64_json"})
		
	var error = http_request.request("https://api.openai.com/v1/images/generations", 
	["Content-Type: application/json", "authorization: Bearer " + User.open_ai_key], 
	true, 
	HTTPClient.METHOD_POST, 
	body)
	
	get_parent().get_node("DataEntry/Log").text += "\nSummoning..."
	get_parent().get_node("DataEntry").reset_log_fade()

func upload_image(result, response_code, headers, body):
	
	if response_code == 200:
	
		get_parent().get_node("DataEntry/Log").text += "\nSummoning Returned"
		get_parent().get_node("DataEntry").reset_log_fade()
		
		var image_string = parse_json(body.get_string_from_ascii())["data"][0]["b64_json"]
		
		if User.refresh_token == "":
			var file = File.new()
			file.open("user://keystore", File.READ)
			var content = file.get_buffer(32)
			KeyGen.check_operational(content, get_parent().get_node("DataEntry"))
			if User.relay_operational == true:
				KeyGen.request_token(content, get_parent().get_node("DataEntry"))
			file.close()
		
		pending_hash = generate_hash()
		
		var http_request = HTTPRequest.new()
		get_parent().get_node("Uploading").add_child(http_request)
		
		http_request.connect("request_completed", self, "image_uploaded")

		var request_body = JSON.print({"resourceId": "IMAGINARY.CREATURES", 
		"sqlText": "INSERT INTO IMAGINARY.CREATURES(HASH, ID, IMAGE) VALUES ('" + pending_hash + "', '" + str(pending_creature_id) + "', '" + image_string + "')"})
		
		var error = http_request.request("https://hackathon.spaceandtime.dev/v1/sql/dml", 
		["accept: application/json", "authorization: Bearer " + User.auth_token, "biscuit: " + User.biscuit, "content-type: application/json"], 
		true, 
		HTTPClient.METHOD_POST, 
		request_body)
		
		http_request_delete.queue_free()
		http_request_delete = http_request
		
	else:
		get_parent().get_node("DataEntry/Log").text += "\nSummoning Failed!\nInvalid OpenAI Key!"
		get_parent().get_node("DataEntry").reset_log_fade()
		summoning_ongoing = false
	
		http_request_delete.queue_free()


func image_uploaded(result, response_code, headers, body):
	if response_code == 200:
		get_parent().get_node("DataEntry/Log").text += "\nSummoning Uploaded"
		get_parent().get_node("DataEntry").reset_log_fade()
		
		initialize_creature()
	else:
		get_parent().get_node("DataEntry/Log").text += "\nSummoning Failed!\nInvalid SxT Token!"
		get_parent().get_node("DataEntry").reset_log_fade()
		summoning_ongoing = false
	http_request_delete.queue_free()
	http_request_delete = null
	

func initialize_creature():
	randomize()
	var demeanor = randi()%2+1;
	randomize()
	var location = randi()%3+1;
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	KeyGen.initialize_creature(content, pending_creature_id, pending_hash, location, demeanor)
	file.close()
	get_parent().get_node("DataEntry/Log").text += "\nCreature Initialized"
	get_parent().get_node("DataEntry").reset_log_fade()
	summoning_ongoing = false
	recheck_menu = true
	User.get_creatures()
