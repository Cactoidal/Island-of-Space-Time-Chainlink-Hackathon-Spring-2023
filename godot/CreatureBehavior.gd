extends KinematicBody




var movement_behavior
var bounds = []

var id = 0
var hp = 0
var attack = 0
var abilities = []
var location = "Beach"
var demeanor = "Friendly"
var image = preload("res://icon.png")

var floor_found = false

var aggression = false

func initialize(var varietal):
	id = varietal["id"]
	hp = varietal["hp"]
	attack = varietal["attack"]
	location = varietal["location"]
	demeanor = varietal["demeanor"]
	image = varietal["image"]


func _ready():
	randomize()
	var random_move = randi()%2+1
	match random_move:
		1: movement_behavior = "Lazy"
		2: movement_behavior = "Adventurous"

	$Sprite3D/Viewport/Image.texture = image
	$RayCast.set_enabled(true)



#position must exceed min values
func set_bounds(var x_min_bound, var z_min_bound, var x_max_bound = 508, var z_max_bound = 508):
	bounds = [x_min_bound, z_min_bound, x_max_bound, z_max_bound]



var wait_timer = 0
var waiting = false
var shift = false
func _physics_process(delta):
	if floor_found == false:
		find_floor()
	move_and_slide(Vector3(0,-delta * 20,0), Vector3.UP)
	move(delta)
	if followed_up == false:
		follow_up()
	

var stored_loc
func find_floor():
	if $RayCast.get_collision_point() != null:
		stored_loc = $RayCast.get_collision_point()
		global_transform.origin = $RayCast.get_collision_point()
		global_transform.origin.y += 2
		floor_found = true
		$RayCast.queue_free()

var followed_up = false
func follow_up():
	global_transform.origin = stored_loc
	global_transform.origin.y += 2
	followed_up = true



var move_direction = Vector3(1,0,0)


func move(delta):
		wait_timer -= delta
		if wait_timer < 0:
			if movement_behavior == "Lazy":
				if waiting == false:
					waiting = true
				else:
					waiting = false
			wait_timer = randi()%5+5
			
			randomize()
			var move_select = randi()%4+1
			match move_select:
				1: move_direction = Vector3(1,0,0)
				2: move_direction = Vector3(0,0,1)
				3: move_direction = Vector3(-1,0,0)
				4: move_direction = Vector3(0,0,-1)
					
			randomize()
			wait_timer = randi()%5+5
			if global_transform.origin.x < bounds[0]:
				move_direction = Vector3(2,0,0)
			elif global_transform.origin.x > bounds[2]:
				move_direction = Vector3(-2,0,0)
			if global_transform.origin.z < bounds[1]:
				move_direction = Vector3(0,0,2)
			elif global_transform.origin.z > bounds[3]:
				move_direction = Vector3(0,0,-2)
					
	
		move_direction.y = -delta * 9
		
		if aggression == true:
			move_direction = (get_parent().get_parent().get_node("Player").global_transform.origin - global_transform.origin) / 2
			move_direction.y = -10
		if waiting == false:
			move_and_slide(move_direction, Vector3.UP)
			


func _on_Aggression_body_entered(body):
	if demeanor == "Aggressive":
		aggression = true
		

func _on_Aggression_body_exited(body):
	aggression = false

