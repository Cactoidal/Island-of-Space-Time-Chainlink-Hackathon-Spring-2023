extends Node

var auth_token = ""
var refresh_token
var open_ai_key
var base_node
var http_request_delete
var initialized = false
var user_address
var user_balance
var ai_query = null
var images = []

var relay_operational = false

var curr_maximum = 0

var creature_list = []
var got_list = false

#IMAGINARY.CREATURES
var biscuit = redacted

func _ready():
	pass 

var time = 349
func _process(delta):
	if initialized == true:
			time += delta
			if time > 350:
				time = 0
				if refresh_token != "":
					refresh_sxt()
				else:
					get_creatures()
					

func refresh_sxt():
	var http_request = HTTPRequest.new()
	base_node.add_child(http_request)
	http_request_delete = http_request
	http_request.connect("request_completed", self, "refresh_attempted")
	
	base_node.get_node("DataEntry").get_node("Log").text += "\nRefreshing SxT Access..."
	base_node.get_node("DataEntry").reset_log_fade()
	
	var error = http_request.request("https://hackathon.spaceandtime.dev/v1/auth/refresh", ["accept: */*", "authorization: Bearer " + refresh_token], true, HTTPClient.METHOD_POST, "")
	

func refresh_attempted(result, response_code, headers, body):
	
	var get_result = parse_json(body.get_string_from_ascii())
	
	if response_code == 200:
		auth_token = get_result["accessToken"]
		refresh_token = get_result["refreshToken"]
	
		base_node.get_node("DataEntry").get_node("Log").text += "\nAccess Token Refreshed"
		base_node.get_node("DataEntry").reset_log_fade()
		http_request_delete.queue_free()
		get_creatures()
		#base_node.get_node("Chamber/PoolDisplay/Viewport/Pool").get_images()
	
	

	else:
		base_node.get_node("DataEntry").get_node("Log").text += "\nRefresh token invalid!"
		base_node.get_node("DataEntry").reset_log_fade()
		refresh_token = ""
		http_request_delete.queue_free()
		if base_node.get_node("Player").initialized == false:
			base_node.get_node("Player").initialized = true
			base_node.get_node("DataEntry").get_node("Loading").visible = false
	


func get_creatures():
	
	if base_node.get_node("Player").summoning_ongoing == true:
		return
	
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	KeyGen.get_creature(content, base_node.get_node("DataEntry"))
	var total = base_node.get_node("DataEntry").pending_creature_id
	if total <= curr_maximum:
		file.close()
		return
		
	elif total > curr_maximum:
		
		var ids = []
		for number in range(curr_maximum, total):
			KeyGen.get_creature_object(content, float(number), base_node.get_node("DataEntry"))
			if parse_json(base_node.get_node("DataEntry").creature_object)["initialized"] == true:
				ids.append(number)
		curr_maximum = total
		if ids.size() > 20:
			total = 20
		else:
			total = ids.size()
		randomize()
		ids.shuffle()
		var query_values = ""
		for number in range(total):
			query_values += str(ids[number])
			if number != total - 1:
				query_values += ","
		
		if refresh_token == "":
			KeyGen.check_operational(content, base_node.get_node("DataEntry"))
			if User.relay_operational == true:
				KeyGen.request_token(content, base_node.get_node("DataEntry"))
		file.close()
		
		if auth_token != "":
			base_node.get_node("DataEntry").get_node("Log").text += "\nRetrieving creatures..."
			base_node.get_node("DataEntry").reset_log_fade()
		var http_request = HTTPRequest.new()
		base_node.get_node("Player").add_child(http_request)
		http_request_delete = http_request
		http_request.connect("request_completed", self, "creatures_obtained")

		var body = JSON.print({"resourceId": "IMAGINARY.CREATURES", "sqlText": "SELECT * FROM IMAGINARY.CREATURES WHERE ID IN (" + query_values + ");"})
			
		var error = http_request.request("https://hackathon.spaceandtime.dev/v1/sql/dql", ["accept: application/json", "authorization: Bearer " + auth_token, "biscuit: " + biscuit, "content-type: application/json"], true, HTTPClient.METHOD_POST, body)
	

var hash_compare = false

func creatures_obtained(result, response_code, headers, body):
	
	if response_code == 200:
		base_node.get_node("DataEntry").get_node("Log").text += "\nGot Creatures"
		base_node.get_node("DataEntry").reset_log_fade()
		got_list = true
		
		var get_result = parse_json(body.get_string_from_ascii())
			
		for entry in range(get_result.size()):
			var file = File.new()
			file.open("user://keystore", File.READ)
			var content = file.get_buffer(32)
			KeyGen.check_hash(content, get_result[entry]["HASH"], get_result[entry]["ID"], base_node.get_node("DataEntry"))
			file.close()
			if hash_compare == true:
				var new_creature = []
				new_creature.append(get_result[entry]["HASH"])
				new_creature.append(get_result[entry]["ID"])
				var image = Image.new()
				var new_image = get_result[entry]["IMAGE"]
				image.load_png_from_buffer(Marshalls.base64_to_raw(new_image))
				var texture = ImageTexture.new()
				texture.create_from_image(image)
				new_creature.append(texture)
				creature_list.append(new_creature)
			hash_compare = false
		
	if base_node.get_node("Player").initialized == false:
		base_node.get_node("Player").initialized = true
		base_node.get_node("DataEntry").get_node("Loading").visible = false
	http_request_delete.queue_free()
	http_request_delete = null
