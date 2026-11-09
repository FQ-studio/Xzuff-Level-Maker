extends CharacterBody2D

const MOVE_SPEED := 230.0
const JUMP_VELOCITY := -430.0
const STOMP_BOUNCE := -260.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var spawn_position := Vector2.ZERO

func _ready() -> void:
	spawn_position = global_position

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * MOVE_SPEED
	move_and_slide()
	_check_danger()

func _check_danger() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider is Node and collider.is_in_group("enemies"):
			if collision.get_normal().y < -0.6 and velocity.y > 0.0:
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
