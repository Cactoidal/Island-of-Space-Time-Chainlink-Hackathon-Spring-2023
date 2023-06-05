extends KinematicBody

var initialized = false

var test_menu = preload("res://CreatureMenu.tscn")

var speed = 10
var h_acceleration = 6
var air_acceleration = 1
var normal_acceleration = 6
var gravity = 20
var jump = 10
var full_contact = false

var mouse_sensitivity = 0.12

var menu_open = false
var near_summoner = false
var near_screen = false

var summoning_ongoing = false
var recheck_menu = false

var curr_terrain


var direction = Vector3()
var h_velocity = Vector3()
var movement = Vector3()
var gravity_vec = Vector3()

var mouse_captured = false

var pending_creature_id = 0
var pending_hash = ""

var player_creatures = []
var player_list = []


onready var head = $Head
onready var ground_check = $GroundCheck

var summoning = false

func _input(event):
	
	if initialized == true:
		if menu_open == false:
		
			if event is InputEventMouseMotion:
				rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
				head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
				head.rotation.x = clamp(head.rotation.x, deg2rad(-150), deg2rad(0))


func _physics_process(delta):
	spawn_creatures_beach()
	spawn_creatures_mountain()
	
	if global_transform.origin.y < -190:
		global_transform.origin = get_parent().get_node("Chamber/Chainlink").global_transform.origin
		creatures_spawned_beach = false
		creatures_spawned_cave = false
		creatures_spawned_mountain = false
		get_parent().get_node("Chamber/Chainlink").handle_world()
		
	if initialized == true:
		
		if Input.is_action_just_pressed("confirm"):
			if near_summoner == true:
				if menu_open == false:
					if summoning_ongoing == false:
						Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
						menu_open = true
						mouse_captured = false
						summoning = true
						get_parent().get_node("DataEntry").get_balance()
						get_parent().get_node("DataEntry").summon_prompt()
			elif near_screen == true:
				if menu_open == false:
					add_child(test_menu.instance())
		
		if Input.is_action_just_pressed("capture") and mouse_captured == false and summoning == false:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_parent().get_node("DataEntry").get_node("PauseMenu").visible = false
			menu_open = false
			mouse_captured = true
			if near_summoner == true:
				get_parent().get_node("DataEntry").get_node("Log").get_node("Eprompt").visible = true
		elif Input.is_action_just_pressed("capture") and mouse_captured == true and menu_open == false:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_parent().get_node("DataEntry").get_balance()
			get_parent().get_node("DataEntry").get_node("PauseMenu").visible = true
			menu_open = true
			mouse_captured = false
			if near_summoner == true:
				get_parent().get_node("DataEntry").get_node("Log").get_node("Eprompt").visible = false
		
		direction = Vector3()
		
		full_contact = ground_check.is_colliding()
		
		
		if Input.is_action_just_pressed("run"):
			speed = 15
		
		if Input.is_action_just_released("run"):
			speed = 10
		
		if not is_on_floor():
			gravity_vec += Vector3.DOWN * gravity * delta
			h_acceleration = air_acceleration
		elif is_on_floor() and full_contact:
			gravity_vec = -get_floor_normal() * gravity
			h_acceleration = normal_acceleration
		else:
			gravity_vec = -get_floor_normal()
			h_acceleration = normal_acceleration
		
		if Input.is_action_just_pressed("jump") and is_on_floor() or ground_check.is_colliding():
			if menu_open == false:
				gravity_vec = Vector3.UP * jump
		
		if menu_open == false:
			if Input.is_action_pressed("forward"):
				direction -= transform.basis.y
			elif Input.is_action_pressed("back"):
				direction += transform.basis.y
			if Input.is_action_pressed("left"):
				direction -= transform.basis.x
			elif Input.is_action_pressed("right"):
				direction += transform.basis.x
		
		direction = direction.normalized()
		h_velocity = h_velocity.linear_interpolate(direction * speed, h_acceleration * delta)
		movement.z = h_velocity.z + gravity_vec.z
		movement.x = h_velocity.x + gravity_vec.x
		movement.y = gravity_vec.y
		
		move_and_slide(movement, Vector3.UP)


var http_request_delete
func summon():
	var http_request = HTTPRequest.new()
	get_parent().get_node("Summoning").add_child(http_request)
	http_request_delete = http_request
	http_request.connect("request_completed", self, "upload_image")

	var body = JSON.print({"prompt": User.ai_query, "n": 1, "size": "256x256", "response_format": "b64_json"})
		
	var error = http_request.request("https://api.openai.com/v1/images/generations", ["Content-Type: application/json", "authorization: Bearer " + User.open_ai_key], true, HTTPClient.METHOD_POST, body)
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

		var request_body = JSON.print({"resourceId": "IMAGINARY.CREATURES", "sqlText": "INSERT INTO IMAGINARY.CREATURES(HASH, ID, IMAGE) VALUES ('" + pending_hash + "', '" + str(pending_creature_id) + "', '" + image_string + "')"})
		
		var error = http_request.request("https://hackathon.spaceandtime.dev/v1/sql/dml", ["accept: application/json", "authorization: Bearer " + User.auth_token, "biscuit: " + User.biscuit, "content-type: application/json"], true, HTTPClient.METHOD_POST, request_body)
		
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
	

func generate_hash():
	var hash_string = ""
	for number in range(24):
		randomize()
		var chunk = randi()%7777
		var chunk_string = str(chunk)
		if chunk < 1000:
			chunk_string = "0" + chunk_string
		if chunk < 100:
			chunk_string = "0" + chunk_string
		if chunk < 10:
			chunk_string = "0" + chunk_string
		hash_string += chunk_string
	return hash_string.sha256_text()


var creature = preload("res://Creature.tscn")
var creatures_spawned_beach = false
var beach_region_creatures = []
func spawn_creatures_beach():
	if User.got_list == true:
		
		
		if creatures_spawned_beach == false:
			if global_transform.origin.x > 305:
				beach_region_creatures = []
				for creature in User.creature_list:
					var file = File.new()
					file.open("user://keystore", File.READ)
					var content = file.get_buffer(32)
					KeyGen.get_creature_object(content, creature[1], get_parent().get_node("DataEntry"))
					file.close()
					var creature_object = get_parent().get_node("DataEntry").creature_object
					if parse_json(creature_object)["location"].substr(2) == "1":
						var incoming_creature = {}
						incoming_creature["id"] = creature[1]
						incoming_creature["hp"] = str(parse_json(creature_object)["hp"].hex_to_int())
						incoming_creature["attack"] = str(parse_json(creature_object)["attack"].hex_to_int())
						incoming_creature["location"] = "Beach"
						var curr_demeanor = parse_json(creature_object)["demeanor"].substr(2)
						if curr_demeanor == "1":
							incoming_creature["demeanor"] = "Friendly"
						elif curr_demeanor == "2":
							incoming_creature["demeanor"] = "Aggressive"
						incoming_creature["image"] = creature[2]
						beach_region_creatures.append(incoming_creature)
					
				if beach_region_creatures != []:
					for number in range(7):
						var varietal = beach_region_creatures[randi()%beach_region_creatures.size()]
						var new_creature = creature.instance()
						new_creature.initialize(varietal)
						curr_terrain.add_child(new_creature)
						randomize()
						var rand_x = randi()%183 + 325
						randomize() 
						var rand_z = randi()%508
						new_creature.global_transform.origin = Vector3(rand_x, global_transform.origin.y + 200, rand_z)
						new_creature.set_bounds(325, 1)
					creatures_spawned_beach = true


var creatures_spawned_mountain = false
var mountain_region_creatures = []
func spawn_creatures_mountain():
	if User.got_list == true:
		
		if creatures_spawned_mountain == false:
			if global_transform.origin.x < 305 && global_transform.origin.x > 100:
				mountain_region_creatures = []
				for creature in User.creature_list:
					var file = File.new()
					file.open("user://keystore", File.READ)
					var content = file.get_buffer(32)
					KeyGen.get_creature_object(content, creature[1], get_parent().get_node("DataEntry"))
					file.close()
					var creature_object = get_parent().get_node("DataEntry").creature_object
					if parse_json(creature_object)["location"].substr(2) == "2":
						var incoming_creature = {}
						incoming_creature["id"] = creature[1]
						incoming_creature["hp"] = str(parse_json(creature_object)["hp"].hex_to_int())
						incoming_creature["attack"] = str(parse_json(creature_object)["attack"].hex_to_int())
						incoming_creature["location"] = "Mountain"
						var curr_demeanor = parse_json(creature_object)["demeanor"].substr(2)
						if curr_demeanor == "1":
							incoming_creature["demeanor"] = "Friendly"
						elif curr_demeanor == "2":
							incoming_creature["demeanor"] = "Aggressive"
						incoming_creature["image"] = creature[2]
						mountain_region_creatures.append(incoming_creature)
					
				if mountain_region_creatures != []:
					for number in range(15):
						var varietal = mountain_region_creatures[randi()%mountain_region_creatures.size()]
						var new_creature = creature.instance()
						new_creature.initialize(varietal)
						curr_terrain.add_child(new_creature)
						randomize()
						var rand_x = randi()%300+1
						randomize() 
						var rand_z = randi()%508+1
						new_creature.global_transform.origin = Vector3(rand_x, global_transform.origin.y + 500, rand_z)
						new_creature.set_bounds(1, 1, 325, 508)
					creatures_spawned_mountain = true



var creatures_spawned_cave = false
var cave_region_creatures = []
func spawn_creatures_cave():
	if User.got_list == true:
	
		if creatures_spawned_cave == false:
				cave_region_creatures = []
				for creature in User.creature_list:
					var file = File.new()
					file.open("user://keystore", File.READ)
					var content = file.get_buffer(32)
					KeyGen.get_creature_object(content, creature[1], get_parent().get_node("DataEntry"))
					file.close()
					var creature_object = get_parent().get_node("DataEntry").creature_object
					if parse_json(creature_object)["location"].substr(2) == "3":
						var incoming_creature = {}
						incoming_creature["id"] = creature[1]
						incoming_creature["hp"] = str(parse_json(creature_object)["hp"].hex_to_int())
						incoming_creature["attack"] = str(parse_json(creature_object)["attack"].hex_to_int())
						incoming_creature["location"] = "Cave"
						var curr_demeanor = parse_json(creature_object)["demeanor"].substr(2)
						if curr_demeanor == "1":
							incoming_creature["demeanor"] = "Friendly"
						elif curr_demeanor == "2":
							incoming_creature["demeanor"] = "Aggressive"
						incoming_creature["image"] = creature[2]
						cave_region_creatures.append(incoming_creature)
				
				if cave_region_creatures != []:
					for number in range(7):
						var varietal = cave_region_creatures[randi()%cave_region_creatures.size()]
						var new_creature = creature.instance()
						new_creature.initialize(varietal)
						curr_terrain.add_child(new_creature)
						randomize()
						var rand_x = randi()%27 + 46
						randomize() 
						var rand_z = randi()%29 + 247
						new_creature.global_transform.origin = Vector3(rand_x, -21, rand_z)
						new_creature.set_bounds(45, 246, 74, 276)
					creatures_spawned_cave = true
