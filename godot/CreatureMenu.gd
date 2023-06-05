extends Control

var unit = preload("res://CreatureUnit.tscn")
var prompt = preload("res://CreatureMenuPrompt.tscn")

var right = false

var player
var data

var player_creatures = []
var player_list = []

var loading = false

func _ready():
	
	player = get_parent()
	player_list = player.player_list
	data = get_parent().get_parent().get_node("DataEntry")
	
	
	player.menu_open = true
	
	$Return.connect("pressed", self, "close")
	
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	KeyGen.get_creatures(content, self)
	
	
	loading = true
	if player_list == []:
		print("player's list is empty")
		start_get_creature_list()
	elif player.recheck_menu == true:
		print("rechecking menu")
		start_get_creature_list()
	
	
	else:
		print("no other conditions met")
		load_menu()
	file.close()
		
	
func close():
	if loading == false:
		player.menu_open = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		queue_free()
	

var http_request_delete
func start_get_creature_list():	
	player.recheck_menu = false
	if player_creatures == []:
		print("player creatures array is reporting empty")
		load_menu()
	else:
		var http_request = HTTPRequest.new()
		get_parent().get_parent().get_node("LoadingMenu").add_child(http_request)
		http_request_delete = http_request
		http_request.connect("request_completed", self, "get_creature_list")
	
		data.get_node("Log").text += "\nRetrieving Your Summons.."
		data.reset_log_fade()
		print("attempting to get summons")
		var id_filter = []
		var query_values = ""
		for preid in player_creatures:
			if !preid in player.player_creatures:
				id_filter.append(preid)
		for id in id_filter:
			query_values += str(id)
			if id != player_creatures[id_filter.size() - 1]:
				query_values += ","
		print("query values: " + query_values)
		if query_values.ends_with(","):
			query_values.erase(query_values.length() - 1, 1)
		print("query values modded: " + query_values)
		var body = JSON.print({"resourceId": "IMAGINARY.CREATURES", "sqlText": "SELECT * FROM IMAGINARY.CREATURES WHERE ID IN (" + query_values + ");"})
			
		var error = http_request.request("https://hackathon.spaceandtime.dev/v1/sql/dql", ["accept: application/json", "authorization: Bearer " + User.auth_token, "biscuit: " + User.biscuit, "content-type: application/json"], true, HTTPClient.METHOD_POST, body)
	player.player_creatures = player_creatures


func got_player_creatures(var creatures):
	player_creatures = parse_json(creatures)

func get_creature_list(result, response_code, headers, body):

	if response_code == 200:
		var get_result = parse_json(body.get_string_from_ascii())
		if get_result == []:
			load_menu()
		else:
			data.get_node("Log").text += "\nSummoned Creatures Retrieved"
			data.reset_log_fade()
			
			var file = File.new()
			file.open("user://keystore", File.READ)
			var content = file.get_buffer(32)

			var incoming_creatures = []
			
			for entry in range(get_result.size()):
				KeyGen.check_hash(content, get_result[entry]["HASH"], get_result[entry]["ID"], get_parent().get_parent().get_node("DataEntry"))
				if User.hash_compare == true:
					var new_creature = []
					new_creature.append(get_result[entry]["HASH"])
					new_creature.append(get_result[entry]["ID"])
					var image = Image.new()
					var new_image = get_result[entry]["IMAGE"]
					image.load_png_from_buffer(Marshalls.base64_to_raw(new_image))
					var texture = ImageTexture.new()
					texture.create_from_image(image)
					new_creature.append(texture)
					incoming_creatures.append(new_creature)
				User.hash_compare = false
			
			if incoming_creatures != []:
				for creature in incoming_creatures:
					var new_creature = {}
					KeyGen.get_creature_object(content, creature[1], self)
					new_creature["id"] = creature[1]
					new_creature["hp"] = parse_json(creature_object)["hp"].hex_to_int()
					new_creature["attack"] = parse_json(creature_object)["attack"].hex_to_int()
					new_creature["image"] = creature[2]
				
					player.player_list.append(new_creature)
				
			file.close()
			load_menu()
	http_request_delete.queue_free()
	http_request_delete = null


func load_menu():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var start_position = Vector2(25, 50)
	for creature in player_list:
		var new_unit = unit.instance()
		new_unit.get_node("HP").text = "HP: " + str(creature["hp"])
		new_unit.get_node("Attack").text = "Attack: " + str(creature["attack"])
		new_unit.get_node("Location").connect("pressed", self, "prompt_location", [creature["id"], creature["image"]])
		new_unit.get_node("Demeanor").connect("pressed", self, "prompt_demeanor", [creature["id"], creature["image"]])
		new_unit.get_node("Quest").connect("pressed", self, "prompt_quest", [creature["id"], creature["image"]])
		new_unit.get_node("Image").texture = creature["image"]
		new_unit.get_node("Image").rect_scale = Vector2(0.35,0.35)
		
		$ScrollContainer/Creatures.add_child(new_unit)
		new_unit.rect_position = start_position
		if right == false:
			right = true
			start_position += Vector2(400, 0)
			$ScrollContainer/Creatures.rect_min_size += Vector2(0, 235)
		else:
			right = false
			start_position += Vector2(-400, 235)
	$ScrollContainer/Creatures.rect_min_size += Vector2(0, 50)
	loading = false
	if player_list == []:
		$Loading.text = "No Summoned Creatures Yet"
	else:
		$Loading.visible = false


func check_hash(var creature, var hash_key):
	KeyGen.check_hash(creature, hash_key)

func prompt_location(var creature, var image):
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	KeyGen.get_creature_object(content, creature, self)
	file.close()
	var curr_location = parse_json(creature_object)["location"].substr(2)
	
	if curr_location == "1":
		curr_location = "Beach"
	elif curr_location == "2":
		curr_location = "Mountain"
	elif curr_location == "3":
		curr_location = "Cave"
	
	var new_prompt = prompt.instance()
	new_prompt.get_node("FrontPanel/Image").texture = image
	new_prompt.get_node("FrontPanel/Image").rect_scale = Vector2(0.35,0.35)
	new_prompt.get_node("FrontPanel/Location").visible = true
	new_prompt.get_node("FrontPanel/Location/Beach").connect("pressed", self, "change_location", [creature, 1, new_prompt])
	new_prompt.get_node("FrontPanel/Location/Mountain").connect("pressed", self, "change_location", [creature, 2, new_prompt])
	new_prompt.get_node("FrontPanel/Location/Cave").connect("pressed", self, "change_location", [creature, 3, new_prompt])
	new_prompt.get_node("FrontPanel/Cancel").connect("pressed", self, "cancel", [new_prompt])
	new_prompt.get_node("FrontPanel/Label").text = "Manifest in which Location?\nCurrent Location: " + curr_location
	data.get_balance()
	new_prompt.get_node("FrontPanel/MATIC").text = "MATIC Balance: " + str(User.user_balance)
	add_child(new_prompt)

func change_location(var creature, var location, var prompt):
	data.get_node("Log").text += "\nManifesting..."
	data.reset_log_fade()
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	KeyGen.change_location(content, creature, location)
	file.close()
	data.get_node("Log").text += "\nLocation Changed"
	data.reset_log_fade()
	prompt.queue_free()
	

func prompt_demeanor(var creature, var image):
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	KeyGen.get_creature_object(content, creature, self)
	file.close()
	var curr_demeanor = parse_json(creature_object)["demeanor"].substr(2)
	
	if curr_demeanor == "1":
		curr_demeanor = "Friendly"
	elif curr_demeanor == "2":
		curr_demeanor = "Aggressive"
		
	var new_prompt = prompt.instance()
	new_prompt.get_node("FrontPanel/Image").texture = image
	new_prompt.get_node("FrontPanel/Image").rect_scale = Vector2(0.35,0.35)
	new_prompt.get_node("FrontPanel/Demeanor").visible = true
	new_prompt.get_node("FrontPanel/Demeanor/Friendly").connect("pressed", self, "change_demeanor", [creature, 1, new_prompt])
	new_prompt.get_node("FrontPanel/Demeanor/Aggressive").connect("pressed", self, "change_demeanor", [creature, 2, new_prompt])
	new_prompt.get_node("FrontPanel/Cancel").connect("pressed", self, "cancel", [new_prompt])
	new_prompt.get_node("FrontPanel/Label").text = "Change to which Demeanor?\nCurrent Demeanor: " + curr_demeanor
	data.get_balance()
	new_prompt.get_node("FrontPanel/MATIC").text = "MATIC Balance: " + str(User.user_balance)
	add_child(new_prompt)
	
func change_demeanor(var creature, var location, var prompt):
	data.get_node("Log").text += "\nAltering Behavior..."
	data.reset_log_fade()
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	KeyGen.change_demeanor(content, creature, location)
	file.close()
	data.get_node("Log").text += "\nDemeanor Changed"
	data.reset_log_fade()
	prompt.queue_free()


var creature_object
func got_creature_object(var creature):
	creature_object = creature
	


func cancel(var prompt):
	if http_request_delete != null:
		http_request_delete.queue_free()
	prompt.queue_free()
