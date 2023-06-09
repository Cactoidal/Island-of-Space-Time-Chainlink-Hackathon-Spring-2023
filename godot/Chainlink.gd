extends MeshInstance

var circle_flat = false

var terrain = preload("res://Forest.tscn")
var player
var terrain_created = false
var environment
var pink_sky = preload("res://PinkSunset.tscn")

func _ready():
	player = get_parent().get_parent().get_node("Player")
	environment = get_parent().get_parent().get_node("AllSkyFree_EpicGloriousPink")

func _process(delta):
		rotate_y(deg2rad(0.25))


func _on_Area_body_entered(body):
	get_parent().visible = true
	get_parent().get_parent().get_node("Water").queue_free()
	get_parent().get_node("MakeVisible").queue_free()


func _on_MakeLid_body_entered(body):
	get_parent().get_node("Lid/CollisionShape").disabled = false
	get_parent().get_parent().get_node("IslandWalls").queue_free()
	get_parent().get_parent().get_node("FallWalls").queue_free()
	get_parent().get_node("Wind1").playing = true
	get_parent().get_node("Wind2").playing = true
	get_parent().get_node("MakeLid").queue_free()


func _on_ActivationZone_body_entered(body):
	get_parent().get_node("Plinth/EPrompt").visible = true
	player.near_summoner = true


func _on_ActivationZone_body_exited(body):
	get_parent().get_node("Plinth/EPrompt").visible = false
	player.near_summoner = false


func _on_ScreenActivationZone_body_entered(body):
	get_parent().get_node("PoolDisplay/EPrompt").visible = true
	player.near_screen = true

func _on_ScreenActivationZone_body_exited(body):
	get_parent().get_node("PoolDisplay/EPrompt").visible = false
	player.near_screen = false


var curr_terrain
func _on_EastGate_body_entered(body):
	if terrain_created == false:
		terrain_created = true
		var new_terrain = terrain.instance()
		curr_terrain = new_terrain
		player.curr_terrain = curr_terrain
		environment.queue_free()
		get_parent().get_parent().add_child(new_terrain)
		player.global_transform.origin = new_terrain.get_node("Location1").global_transform.origin
		get_parent().visible = false
		get_parent().get_node("Wind1").playing = false
		get_parent().get_node("Wind2").playing = false
		get_parent().get_parent().get_node("Island").visible = false

func _on_WestGate_body_entered(body):
	if terrain_created == false:
		terrain_created = true
		var new_terrain = terrain.instance()
		curr_terrain = new_terrain
		player.curr_terrain = curr_terrain
		environment.queue_free()
		get_parent().get_parent().add_child(new_terrain)
		player.global_transform.origin = new_terrain.get_node("Location2").global_transform.origin
		get_parent().visible = false
		get_parent().get_node("Wind1").playing = false
		get_parent().get_node("Wind2").playing = false
		get_parent().get_parent().get_node("Island").visible = false


func handle_world():
	get_parent().visible = true
	get_parent().get_parent().get_node("Island").visible = true
	get_parent().get_node("Wind1").playing = true
	get_parent().get_node("Wind2").playing = true
	curr_terrain.queue_free()
	var new_sky = pink_sky.instance()
	get_parent().add_child(new_sky)
	environment = new_sky
	terrain_created = false
