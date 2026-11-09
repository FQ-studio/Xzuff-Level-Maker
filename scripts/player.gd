extends CharacterBody2D

const MOVE_SPEED := 230.0
const JUMP_VELOCITY := -430.0
const STOMP_BOUNCE := -260.0
const ANIMATION_RATE := 12.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var spawn_position := Vector2.ZERO
var animation_time := 0.0
var visual: Polygon2D

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	visual = get_node_or_null("Visual") as Polygon2D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * MOVE_SPEED
	move_and_slide()
	_check_danger()
	_animate_visual(delta, direction)

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
