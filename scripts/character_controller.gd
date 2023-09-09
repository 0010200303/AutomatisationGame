extends CharacterBody3D

@onready var world := $".."
@onready var environment := $"../Environment"

@onready var head := $"Head"
@onready var eyes := $"Head/Eyes"
@onready var camera := $"Head/Eyes/Camera3D"

@onready var standing_collision := $"Standing Collision"
@onready var crouching_collision := $"Crouching Collision"
@onready var head_collision_ray := $"Head Collision Ray"

@onready var animation_player := $"Head/Eyes/AnimationPlayer"

@onready var building_ray := $"Head/Eyes/Camera3D/Building Ray"

@export_group("walking")
@export var walk_speed := 3.0
@export var run_speed := 6.0
@export var sprint_speed := 8.0
@export var crouch_speed := 4.0
@export var lerp_speed := 10.0

@export_group("jumping")
@export var jump_force := 7.0
@export var gravity := 13.0
@export var air_control := 0.2

@export_group("crouching")
@export var head_height := 1.8
@export var crouching_depth := 0.8

@export_group("looking")
@export var mouse_sensitivity_x := 0.15
@export var mouse_sensitivity_y := 0.15
@export var max_camera_x_rotation := 89.0
@export var max_free_look_angle := 120.0
@export var free_look_tilt := 0.1

@export_group("head bobbing")
@export var head_bobbing_walking_speed := 8.0
@export var head_bobbing_running_speed := 14.0
@export var head_bobbing_sprinting_speed := 18.0
@export var head_bobbing_crouching_speed := 10.0

@export var head_bobbing_walking_intensity := 0.03
@export var head_bobbing_running_intensity := 0.10
@export var head_bobbing_sprinting_intensity := 0.18
@export var head_bobbing_crouching_intensity := 0.05

@export_group("building")
@export var max_hotbars := 4

var current_direction := Vector3.ZERO
var current_speed := 0.0
var last_velocity := Vector3.ZERO

var is_walking := false
var is_sprinting := false
var is_crouching := false
var is_free_looking := false
var is_sliding := false

var head_bobbing_vector := Vector2.ZERO
var head_bobbing_index := 0.0
var current_head_bobbing_intensity := 0.0

var build_mode := false
var current_building:Building = null
var current_hotbar := 0
var current_hotslot := 0
var hotbars := [] as Array[Array]

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	_remove_later()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion == false:
		return
	event = event as InputEventMouseMotion
	
	eyes.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity_y))
	eyes.rotation_degrees.x = clampf(eyes.rotation_degrees.x, -max_camera_x_rotation, max_camera_x_rotation)
	
	if is_free_looking == true:
		head.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity_x))
		head.rotation_degrees.y = clampf(head.rotation_degrees.y, -max_free_look_angle, max_free_look_angle)
	else:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity_x))

func _physics_process(delta: float) -> void:
	# lock/unlock cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if build_mode == true:
			if current_building != null:
				current_building.queue_free()
				current_building = null
			build_mode = false
		else:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# get inputs
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	
	if Input.is_action_pressed("crouch"):
		head.position.y = lerp(head.position.y, head_height - crouching_depth, lerp_speed * delta)
		crouching_collision.disabled = false
		standing_collision.disabled = true
		
		is_crouching = true
		is_sprinting = false
		is_walking = false
	elif head_collision_ray.is_colliding() == false:
		head.position.y = lerp(head.position.y, head_height, lerp_speed * delta)
		standing_collision.disabled = false
		crouching_collision.disabled = true
		
		if Input.is_action_pressed("sprint"):
			is_sprinting = true
			is_crouching = false
			is_walking = false
		elif Input.is_action_pressed("walk"):
			is_walking = true
			is_crouching = false
			is_sprinting = false
		else:
			is_crouching = false
			is_sprinting = false
			is_walking = false
	if Input.is_action_pressed("free_look"):
		is_free_looking = true
		eyes.rotation_degrees.z = -head.rotation_degrees.y * free_look_tilt
	else:
		is_free_looking = false
		eyes.rotation_degrees.z = lerp(eyes.rotation_degrees.z, 0.0, lerp_speed * delta)
		head.rotation_degrees.y = lerp(head.rotation_degrees.y, 0.0, lerp_speed * delta)
	
	# set speed and head bobbing
	if is_crouching == true:
		current_speed = lerp(current_speed, crouch_speed, lerp_speed * delta)
		current_head_bobbing_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed * delta
	elif is_sprinting == true:
		current_speed = lerp(current_speed, sprint_speed, lerp_speed * delta)
		current_head_bobbing_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
	elif is_walking == true:
		current_speed = lerp(current_speed, walk_speed, lerp_speed * delta)
		current_head_bobbing_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta
	else:
		current_speed = lerp(current_speed, run_speed, lerp_speed * delta)
		current_head_bobbing_intensity = head_bobbing_running_intensity
		head_bobbing_index += head_bobbing_running_speed * delta
	
	# head bobbing
	if is_on_floor() && is_sliding == false && input_dir != Vector2.ZERO:
		head_bobbing_vector.x = sin(head_bobbing_index / 2.0) + 0.5
		head_bobbing_vector.y = sin(head_bobbing_index)
		
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x * current_head_bobbing_intensity, lerp_speed * delta)
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y * (current_head_bobbing_intensity / 2.0), lerp_speed * delta)
	else:
		eyes.position.x = lerp(eyes.position.x, 0.0, lerp_speed * delta)
		eyes.position.y = lerp(eyes.position.y, 0.0, lerp_speed * delta)
	
	
	# change direction
	if is_on_floor() == true:
		current_direction = lerp(current_direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), lerp_speed * delta)
		
		# handle landing
		if last_velocity.y < -0.5:
			animation_player.play("Player/land")
		
	else:
		if input_dir != Vector2.ZERO:
			current_direction = lerp(current_direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), air_control * lerp_speed * delta)
		
		# apply gravity
		velocity.y -= gravity * delta
	
	# jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		animation_player.play("Player/jump")
	
	# apply movement
	if current_direction != Vector3.ZERO:
		velocity.x = current_direction.x * current_speed
		velocity.z = current_direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	last_velocity = velocity
	move_and_slide()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("build_mode"):
		build_mode = !build_mode
	
	if Input.is_action_pressed("change_hotbar"):
		if Input.is_action_just_pressed("first"):
			select_slot(0, current_hotslot)
		elif Input.is_action_just_pressed("second"):
			select_slot(1, current_hotslot)
		elif Input.is_action_just_pressed("third"):
			select_slot(2, current_hotslot)
		elif Input.is_action_just_pressed("fourth"):
			select_slot(3, current_hotslot)
		elif Input.is_action_just_pressed("fifth"):
			select_slot(4, current_hotslot)
		elif Input.is_action_just_pressed("sixth"):
			select_slot(5, current_hotslot)
		elif Input.is_action_just_pressed("seventh"):
			select_slot(6, current_hotslot)
		elif Input.is_action_just_pressed("eighth"):
			select_slot(7, current_hotslot)
		elif Input.is_action_just_pressed("ninth"):
			select_slot(8, current_hotslot)
		elif Input.is_action_just_pressed("tenth"):
			select_slot(9, current_hotslot)
	else:
		if Input.is_action_just_pressed("first"):
			select_slot(current_hotbar, 0)
		elif Input.is_action_just_pressed("second"):
			select_slot(current_hotbar, 1)
		elif Input.is_action_just_pressed("third"):
			select_slot(current_hotbar, 2)
		elif Input.is_action_just_pressed("fourth"):
			select_slot(current_hotbar, 3)
		elif Input.is_action_just_pressed("fifth"):
			select_slot(current_hotbar, 4)
		elif Input.is_action_just_pressed("sixth"):
			select_slot(current_hotbar, 5)
		elif Input.is_action_just_pressed("seventh"):
			select_slot(current_hotbar, 6)
		elif Input.is_action_just_pressed("eighth"):
			select_slot(current_hotbar, 7)
		elif Input.is_action_just_pressed("ninth"):
			select_slot(current_hotbar, 8)
		elif Input.is_action_just_pressed("tenth"):
			select_slot(current_hotbar, 9)
	
	if build_mode == true:
		building()
	
	if current_building != null:
		if building_ray.is_colliding() == true:
			current_building.visible = true
			current_building.position = building_ray.get_collision_point()
		else:
			current_building.visible = false

func building() -> void:
	if current_building == null:
		printerr("no building selected")
		build_mode = false
		return
	
	if Input.is_action_just_pressed("primary"):
		try_build()
	
	if Input.is_action_pressed("change_hotbar") == true:
		if Input.is_action_just_pressed("scroll_up"):
			select_slot(current_hotbar + 1, current_hotslot)
		elif Input.is_action_just_pressed("scroll_down"):
			select_slot(current_hotbar - 1, current_hotslot)
	else:
		if Input.is_action_just_pressed("scroll_up"):
			select_slot(current_hotbar, current_hotslot + 1)
		elif Input.is_action_just_pressed("scroll_down"):
			select_slot(current_hotbar, current_hotslot - 1)

func try_build() -> void:
	if world.can_build(current_building) == true:
		build()

func build() -> void:
	world.instantiate_building(current_building)

func select_slot(hotbar:int, hotslot:int):
	hotbar = clamp(hotbar, 0, max_hotbars)
	hotslot = clamp(hotslot, 0, 9)
	
	if current_hotbar == hotbar && current_hotslot == hotslot && build_mode == true:
		return
	current_hotbar = hotbar
	current_hotslot = hotslot
	
	if current_building != null:
		current_building.queue_free()
	
	var temp := hotbars[current_hotbar][current_hotslot] as SlotBuilding
	if temp.type == SlotBuilding.BuildingType.MACHINE:
		current_building = MachineStore.get_building(temp.name)
	elif temp.type == SlotBuilding.BuildingType.STORAGE:
		current_building = StorageHall.get_building(temp.name)
	elif temp.type == SlotBuilding.BuildingType.CONVEYORBELT:
		current_building = null
		printerr("Not implemented yet!")
		return
	else:
		current_building = null
		printerr(temp.type, " is unknown")
		return
	
	environment.add_child(current_building)
	build_mode = true

func _remove_later() -> void:
	hotbars.resize(max_hotbars)
	for hotbar in hotbars:
		hotbar.resize(10)
	
	var slot = SlotBuilding.new()
	slot.name = "Miner"
	slot.type = SlotBuilding.BuildingType.MACHINE
	hotbars[0][0] = slot
	hotbars[1][1] = slot
	
	slot = SlotBuilding.new()
	slot.name = "Small Container"
	slot.type = SlotBuilding.BuildingType.STORAGE
	hotbars[0][1] = slot
	hotbars[1][0] = slot
