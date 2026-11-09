extends CharacterBody2D

@export var patrol_distance := 72.0
@export var speed := 55.0
var start_x := 0.0
var direction := 1.0

func _ready() -> void:
	start_x = global_position.x
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	velocity.x = direction * speed
	velocity.y += float(ProjectSettings.get_setting("physics/2d/default_gravity")) * delta
	move_and_slide()
	if abs(global_position.x - start_x) >= patrol_distance:
		direction *= -1.0
