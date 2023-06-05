extends Control

var menu = preload("res://PauseMenu.tscn")
var menu_exists = false
var pending_creature_id = 0
var start_check = false
var get_query = false

func _ready():
	get_parent().get_node("WaterSounds").playing = true
	$Proceed.connect("pressed", self, "proceed")
	$CopyAddress.connect("pressed", self, "copy")
	$FaucetLink.connect("pressed", self, "faucet")
	check_keystore()
	get_address()
	
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	KeyGen.check_operational(content, self)
	if User.relay_operational == true:
		$Panel/RelayStatus.text = "Relay Status: ONLINE"
		$Panel/Indicator.color = Color(0,255,0,255)
	else:
		$Panel/RelayStatus.text = "Relay Status: OFFLINE"
		$Panel/Indicator.color = Color(255,0,0,255)
	file.close()

	

var log_timer = 4
var log_fade = false
var copied_timer = 0
var need_matic_timer = 0
var check_timer = 7
var water_sounds_timer = 0
func _process(delta):
	if copied_timer > 0:
		copied_timer -= delta
		if copied_timer < 0:
			if menu_exists == false:
				$CopyAddress/Label.visible = false
			else:
				$PauseMenu/CopyAddress/Label.visible = false
			copied_timer = 0
	
	if need_matic_timer > 0:
		need_matic_timer -= delta
		if need_matic_timer < 0:
			$Log/Eprompt/Matic.visible = false
			need_matic_timer = 0
	
	if log_timer > 0:
		log_timer -= delta
		if log_fade == true:
			$Log.modulate.a -= delta
		if log_timer < 0:
			if log_fade == false:
				log_fade = true
				log_timer = 4
			else:
				log_fade = false
				$Log.visible = false
				$Log.modulate.a = 1
				log_timer = 0
	
	if water_sounds_timer > 0:
		water_sounds_timer -= delta
		get_parent().get_node("WaterSounds").set_volume_db(get_parent().get_node("WaterSounds").get_volume_db() - delta*20)
		if water_sounds_timer < 0:
			get_parent().get_node("WaterSounds").queue_free()
			water_sounds_timer = 0
	
	if start_check == true:
		check_timer -= delta
		if check_timer < 0:
			check_timer = 7
			check_query()
	
	if get_query == true:
		get_query = false
		get_query()
	
	

func proceed():
	copied_timer = 0
	User.refresh_token = $RefreshToken.text
	User.open_ai_key = $APIKey.text
	User.base_node = get_parent()
	User.initialized = true
	$Loading.visible = true
	for node in get_children():
		if node.name != "Log":
			if node.name != "Loading":
				node.queue_free()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_parent().get_node("Player").mouse_captured = true
	$Log.text += "\nStarted\n"
	reset_log_fade()
	var new_menu = menu.instance()
	add_child(new_menu)
	new_menu.get_node("CopyAddress").connect("pressed", self, "copy")
	new_menu.get_node("FaucetLink").connect("pressed", self, "faucet")
	new_menu.get_node("Prompt/Proceed").connect("pressed", self, "accept")
	new_menu.get_node("Prompt/Nevermind").connect("pressed", self, "cancel")
	new_menu.get_node("Return").connect("pressed", self, "return_to_game")
	menu_exists = true

func copy():
	copied_timer = 3
	if menu_exists == false:
		$CopyAddress/Label.visible = true
	else:
		$PauseMenu/CopyAddress/Label.visible = true
	OS.set_clipboard(User.user_address)

func faucet():
	OS.shell_open("https://faucet.polygon.technology")
	
	
func check_keystore():
	var file = File.new()
	if file.file_exists("user://keystore") != true:
		var bytekey = Crypto.new()
		var content = bytekey.generate_random_bytes(32)
		file.open("user://keystore", File.WRITE)
		file.store_buffer(content)
		file.close()
		$Log.text += "\nCreated Keystore"
		reset_log_fade()

func get_address():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	User.user_address = KeyGen.get_address(content)
	file.close()
	$Log.text += "\nGot Address: " + User.user_address

func get_balance():
	KeyGen.get_balance(User.user_address, self)

func set_balance(var balance):
	User.user_balance = balance
	$PauseMenu/Balance.text = "MATIC balance: " + balance

func return_to_game():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_parent().get_node("Player").menu_open = false
	get_parent().get_node("Player").mouse_captured = true
	if get_parent().get_node("Player").near_summoner == true:
		$Log/Eprompt.visible = true
	$PauseMenu.visible = false
	

func summon_prompt():
	$Log/Eprompt.visible = false
	$PauseMenu.visible = true
	$PauseMenu/Prompt/Proceed.text = "Proceed"
	$PauseMenu/CopyAddress.visible = false
	$PauseMenu/FaucetLink.visible = false
	$PauseMenu/Return.visible = false
	$PauseMenu/Prompt.text = "You will need an OpenAI API key to summon creatures.\n\nThe summoning process may take several minutes.\n\nExploring outside the chamber will not interrupt the summoning.\n\nContinue?"
	$PauseMenu/Prompt.visible = true


func accept():
	if User.user_balance == "0":
		$PauseMenu/Prompt/Proceed.text = "Need MATIC! Press ESC"
		return
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	KeyGen.get_creature(content, self)
	KeyGen.do_vrf(content)
	file.close()
	$Log.text += "\nCalling Chainlink VRF..."
	reset_log_fade()
	$Log/Eprompt.visible = true
	$PauseMenu/CopyAddress.visible = true
	$PauseMenu/FaucetLink.visible = true
	$PauseMenu/Return.visible = true
	$PauseMenu.visible = false
	$PauseMenu/Prompt.text = ""
	$PauseMenu/Prompt.visible = false
	get_parent().get_node("Player").summoning_ongoing = true
	get_parent().get_node("Player").summoning = false
	get_parent().get_node("Player").menu_open = false
	get_parent().get_node("Player").mouse_captured = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	start_check = true

func set_creature_id(var id):
	pending_creature_id = id

func cancel():
	$Log/Eprompt.visible = true
	$PauseMenu/CopyAddress.visible = true
	$PauseMenu/FaucetLink.visible = true
	$PauseMenu/Return.visible = true
	$PauseMenu.visible = false
	$PauseMenu/Prompt.text = ""
	$PauseMenu/Prompt.visible = false
	get_parent().get_node("Player").summoning = false
	get_parent().get_node("Player").menu_open = false
	get_parent().get_node("Player").mouse_captured = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)



func check_query():
	$Log.text += "\nAwaiting emanation..."
	reset_log_fade()
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	KeyGen.check_query_return(content, pending_creature_id, self)
	file.close()

var returned = "false"
func query_checked(var check_status):
	returned = check_status
	print(returned)
	if returned == "true":
		print("ready to get")
		start_check = false
		check_timer = 7
		get_query = true


func get_query():
	print("getting query")
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	KeyGen.get_query(content, pending_creature_id, self)
	file.close()

func set_query(var incoming_query):
	print("got query")
	User.ai_query = incoming_query
	print(User.ai_query)
	get_parent().get_node("Player").pending_creature_id = pending_creature_id
	get_parent().get_node("Player").summon()



func reset_log_fade():
	log_fade = false
	$Log.visible = true
	$Log.modulate.a = 1
	$Log.scroll_vertical = float($Log.get_line_count())
	log_timer = 4


func hash_checked(var check):
	if check == "true":
		User.hash_compare = true


func _on_Fall_body_entered(body):
	water_sounds_timer = 2

func checked_relay_status(var status):
	if status == "true":
		User.relay_operational = true
	else:
		User.relay_operational = false

func got_token(var token):
	User.auth_token = token


var creature_object
func got_creature_object(var creature):
	creature_object = creature
