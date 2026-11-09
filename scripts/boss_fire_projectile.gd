extends Area2D

@export var speed := 285.0
var direction := Vector2.LEFT
var lifetime := 4.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta
	rotation = direction.angle()
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color("#e94b2d"))
	draw_circle(Vector2(1.0, 0.0), 4.5, Color("#ffb52e"))
	draw_circle(Vector2(2.0, 0.0), 2.0, Color("#fff2a6"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -4), Vector2(-13, 0), Vector2(-5, 4)
	]), Color("#ff7b32"))

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("_respawn"):
			body._respawn()
		queue_free()
	elif body is StaticBody2D:
		queue_free()
