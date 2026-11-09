extends CharacterBody2D

const MOVE_SPEED := 230.0
const JUMP_VELOCITY := -430.0
const STOMP_BOUNCE := -260.0
const ANIMATION_RATE := 12.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var spawn_position := Vector2.ZERO
var animation_time := 0.0
var visual: Polygon2D
var shot_cooldown := 0.0
var selected_component := "armor"
var weapon_hint: Label
var touch_left := false
var touch_right := false
var touch_jump := false
var touch_fire := false
var touch_controls: CanvasLayer
const PLAYER_PROJECTILE_SCENE: PackedScene = preload("res://scenes/player_projectile.tscn")

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	visual = get_node_or_null("Visual") as Polygon2D
	weapon_hint = Label.new()
	weapon_hint.text = "F: FIRE   1: ARMOR   2: JETPACK   3: BOWSER"
	weapon_hint.position = Vector2(12, 12)
	weapon_hint.add_theme_font_size_override("font_size", 14)
	weapon_hint.add_theme_color_override("font_color", Color("#ffffff"))
	var hud := CanvasLayer.new()
	hud.add_child(weapon_hint)
	get_tree().current_scene.add_child(hud)
	_setup_touch_controls()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	shot_cooldown = maxf(0.0, shot_cooldown - delta)
	_handle_weapon_input()
	if (Input.is_action_just_pressed("ui_accept") or touch_jump) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	if touch_left:
		direction -= 1.0
	if touch_right:
		direction += 1.0
	direction = clampf(direction, -1.0, 1.0)
	velocity.x = direction * MOVE_SPEED
	move_and_slide()
	_check_danger()
	_animate_visual(delta, direction)

func _handle_weapon_input() -> void:
	if Input.is_key_pressed(KEY_1):
		selected_component = "armor"
	elif Input.is_key_pressed(KEY_2):
		selected_component = "jetpack"
	elif Input.is_key_pressed(KEY_3):
		selected_component = "health"
	if weapon_hint != null:
		weapon_hint.text = "F: FIRE   TARGET: " + selected_component.to_upper() + "   (1 ARMOR / 2 JETPACK / 3 BOWSER)"
	if (Input.is_key_pressed(KEY_F) or touch_fire) and shot_cooldown <= 0.0:
		_fire_player_projectile()
		shot_cooldown = 0.32

func _setup_touch_controls() -> void:
	if not OS.has_feature("mobile") and not DisplayServer.is_touchscreen_available():
		return

	touch_controls = CanvasLayer.new()
	touch_controls.name = "TouchControls"
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch_controls.add_child(root)
	get_tree().current_scene.add_child(touch_controls)

	_add_touch_button(root, "◀", Vector2(0.02, 0.78), Vector2(76, 72),
		func(pressed: bool): touch_left = pressed, false)
	_add_touch_button(root, "▶", Vector2(0.12, 0.78), Vector2(76, 72),
		func(pressed: bool): touch_right = pressed, false)
	_add_touch_button(root, "JUMP", Vector2(0.82, 0.78), Vector2(104, 72),
		func(pressed: bool): touch_jump = pressed, false)
	_add_touch_button(root, "FIRE", Vector2(0.82, 0.60), Vector2(104, 64),
		func(pressed: bool): touch_fire = pressed, false)
	_add_touch_button(root, "ARM", Vector2(0.66, 0.60), Vector2(76, 56),
		func(_pressed: bool): selected_component = "armor", true)
	_add_touch_button(root, "JET", Vector2(0.66, 0.72), Vector2(76, 56),
		func(_pressed: bool): selected_component = "jetpack", true)
	_add_touch_button(root, "BOSS", Vector2(0.66, 0.84), Vector2(76, 56),
		func(_pressed: bool): selected_component = "health", true)

func _add_touch_button(root: Control, caption: String, anchor: Vector2, button_size: Vector2,
		callback: Callable, tap_only: bool) -> void:
	var button := Button.new()
	button.text = caption
	button.anchor_left = anchor.x
	button.anchor_top = anchor.y
	button.anchor_right = anchor.x
	button.anchor_bottom = anchor.y
	button.offset_left = 0.0
	button.offset_top = 0.0
	button.offset_right = button_size.x
	button.offset_bottom = button_size.y
	button.add_theme_font_size_override("font_size", 16)
	button.modulate = Color(1.0, 1.0, 1.0, 0.88)
	root.add_child(button)
	if tap_only:
		button.pressed.connect(func(): callback.call(false))
	else:
		button.button_down.connect(func(): callback.call(true))
		button.button_up.connect(func(): callback.call(false))

func _fire_player_projectile() -> void:
	var projectile := PLAYER_PROJECTILE_SCENE.instantiate() as Area2D
	var facing := 1.0
	if visual != null and visual.scale.x < 0.0:
		facing = -1.0
	var muzzle := global_position + Vector2(18.0 * facing, -2.0)
	projectile.global_position = muzzle
	projectile.set("direction", Vector2(facing, 0.0))
	projectile.set("component_target", selected_component)
	get_tree().current_scene.add_child(projectile)


func _animate_visual(delta: float, direction: float) -> void:
	if visual == null:
		return

	animation_time += delta
	if abs(direction) > 0.1:
		visual.scale.x = sign(direction) * abs(visual.scale.x)
	else:
		visual.scale.x = abs(visual.scale.x)

	var target_scale := Vector2.ONE
	var target_y := 0.0
	var target_rotation := 0.0

	if not is_on_floor():
		if velocity.y < 0.0:
			target_scale = Vector2(0.88, 1.16)
		else:
			target_scale = Vector2(1.12, 0.88)
	else:
		if abs(direction) > 0.1:
			var step := abs(sin(animation_time * ANIMATION_RATE))
			target_scale = Vector2(1.0 + step * 0.12, 1.0 - step * 0.10)
			target_y = -step * 2.0
			target_rotation = sin(animation_time * ANIMATION_RATE) * 0.06
		else:
			var breathe := sin(animation_time * 3.0)
			target_scale = Vector2(1.0 + breathe * 0.025, 1.0 - breathe * 0.025)
			target_y = -abs(breathe) * 1.5

	visual.scale = visual.scale.lerp(Vector2(target_scale.x * (sign(visual.scale.x) if abs(visual.scale.x) > 0.01 else 1.0), target_scale.y), min(delta * 12.0, 1.0))
	visual.position.y = lerp(visual.position.y, target_y, min(delta * 14.0, 1.0))
	visual.rotation = lerp_angle(visual.rotation, target_rotation, min(delta * 12.0, 1.0))

func _check_danger() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider is Node and collider.is_in_group("enemies"):
			if collision.get_normal().y < -0.6 and velocity.y > 0.0:
				if collider.has_method("can_be_stomped") and not collider.can_be_stomped():
					_respawn()
					return
				if collider.has_method("take_stomp"):
					collider.take_stomp()
				else:
					collider.queue_free()
				velocity.y = STOMP_BOUNCE
				continue
			_respawn()
			return
		if collider is StaticBody2D and int(collider.get_meta("block_id", 0)) == 3:
			_respawn()
			return

func _respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	if visual != null:
		visual.scale = Vector2.ONE
		visual.position = Vector2.ZERO
		visual.rotation = 0.0
