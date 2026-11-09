extends CharacterBody2D

@export var max_health := 3
@export var patrol_distance := 88.0
@export var speed := 72.0

var health := 3
var start_x := 0.0
var direction := -1.0
var health_label: Label
var visual: Polygon2D

func _ready() -> void:
	health = max_health
	start_x = global_position.x
	add_to_group("enemies")
	visual = get_node_or_null("Visual") as Polygon2D
	health_label = Label.new()
	health_label.text = "BOSS 3/3"
	health_label.position = Vector2(-34, -39)
	health_label.add_theme_font_size_override("font_size", 12)
	health_label.add_theme_color_override("font_color", Color("#ffe58a"))
	add_child(health_label)

func _physics_process(delta: float) -> void:
	velocity.x = direction * speed
	velocity.y += float(ProjectSettings.get_setting("physics/2d/default_gravity")) * delta
	move_and_slide()

	if is_on_wall() or abs(global_position.x - start_x) >= patrol_distance:
		direction *= -1.0
		if visual != null:
			visual.scale.x = direction

func take_stomp() -> void:
	health -= 1
	if health_label != null:
		health_label.text = "BOSS " + str(max(health, 0)) + "/" + str(max_health)
	if visual != null:
		visual.color = Color("#ffdf75") if health > 0 else Color("#777777")
	if health <= 0:
		queue_free()
