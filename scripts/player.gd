extends CharacterBody2D

const MOVE_SPEED := 230.0
const JUMP_VELOCITY := -430.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * MOVE_SPEED
	move_and_slide()
	for index in range(get_slide_collision_count()):
		var hit := get_slide_collision(index)
		if hit.get_collider() is StaticBody2D:
			var normal := hit.get_normal()
			if normal.y < -0.7:
				continue
