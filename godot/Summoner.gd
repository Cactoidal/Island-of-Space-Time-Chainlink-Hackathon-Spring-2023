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
		start_check = false
		check_timer = 7
		get_query = true
