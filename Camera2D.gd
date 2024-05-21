extends Camera2D

var speed = 500
var cam_direction = Vector2(0,0)

const CAM_X_BOUND_LOWER = 0
const CAM_X_BOUND_UPPER = 1920
const CAM_Y_BOUND_LOWER = 0
const CAM_Y_BOUND_UPPER = 1080
var CAM_Y_BOUND = 10.24

func _physics_process(delta):
	cam_direction.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	cam_direction.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	cam_direction = cam_direction.normalized()
	position += cam_direction * speed * delta
	check_bounds()
	
func check_bounds():
	# Check X Axis
	if position.x > CAM_X_BOUND_UPPER:
		position.x = CAM_X_BOUND_UPPER
	elif position.x < CAM_X_BOUND_LOWER:
		position.x = CAM_X_BOUND_LOWER
	# Bounds the y axis of the camera
	if position.y > CAM_Y_BOUND_UPPER:
		position.y = CAM_Y_BOUND_UPPER
	elif position.y < CAM_Y_BOUND_LOWER:
		position.y = CAM_Y_BOUND_LOWER
