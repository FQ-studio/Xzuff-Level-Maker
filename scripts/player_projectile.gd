extends Area2D

@export var speed := 460.0
var direction := Vector2.RIGHT
var component_target := "armor"
var lifetime := 2.2

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color("#d8f5ff"))
	draw_circle(Vector2.ZERO, 3.0, Color("#38bdf8"))
	draw_line(Vector2(-8, 0), Vector2(-3, 0), Color("#a5f3fc"), 2.0)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_component_hit"):
		body.take_component_hit(component_target)
		queue_free()
	elif body is StaticBody2D:
		queue_free()
