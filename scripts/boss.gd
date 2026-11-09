extends CharacterBody2D

@export var max_health := 3
@export var patrol_distance := 88.0
@export var speed := 72.0

var health := 3
var start_x := 0.0
var direction := -1.0
var health_label: Label
var damage_flash := 0.0

func _ready() -> void:
	health = max_health
	start_x = global_position.x
	add_to_group("enemies")
	health_label = Label.new()
	health_label.text = "BOWSER 3/3"
	health_label.position = Vector2(-42, -57)
	health_label.add_theme_font_size_override("font_size", 12)
	health_label.add_theme_color_override("font_color", Color("#ffe58a"))
	add_child(health_label)
	queue_redraw()

func _physics_process(delta: float) -> void:
	velocity.x = direction * speed
	velocity.y += float(ProjectSettings.get_setting("physics/2d/default_gravity")) * delta
	move_and_slide()
	if is_on_wall() or abs(global_position.x - start_x) >= patrol_distance:
		direction *= -1.0
	if damage_flash > 0.0:
		damage_flash = maxf(0.0, damage_flash - delta)
		queue_redraw()

func _draw() -> void:
	var skin := Color("#72b83b")
	var belly := Color("#f4d47b")
	var shell := Color("#d94b32") if damage_flash <= 0.0 else Color("#fff0a8")
	var dark := Color("#273326")
	var horn := Color("#f4ead0")

	# Tail, legs and boots
	draw_colored_polygon(PackedVector2Array([Vector2(-13, 12), Vector2(-29, 19), Vector2(-35, 15), Vector2(-22, 8), Vector2(-12, 5)]), skin)
	draw_rect(Rect2(-17, 17, 12, 9), skin)
	draw_rect(Rect2(7, 17, 12, 9), skin)
	draw_rect(Rect2(-19, 23, 17, 5), dark)
	draw_rect(Rect2(5, 23, 17, 5), dark)

	# Spiked red shell
	draw_circle(Vector2(0, -1), 25, dark)
	draw_circle(Vector2(0, -2), 22, shell)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var base := Vector2(cos(angle), sin(angle)) * 19.0 + Vector2(0, -2)
		var tip := Vector2(cos(angle), sin(angle)) * 31.0 + Vector2(0, -2)
		var side := Vector2(-sin(angle), cos(angle)) * 5.0
		draw_colored_polygon(PackedVector2Array([base - side, tip, base + side]), horn)
	draw_circle(Vector2(0, -2), 14, Color("#f4a34c"))
	draw_arc(Vector2(0, -2), 15, 0.0, TAU, 32, Color("#713c2d"), 2.0)

	# Green body and segmented belly
	draw_colored_polygon(PackedVector2Array([Vector2(-17, -17), Vector2(15, -17), Vector2(20, 8), Vector2(12, 22), Vector2(-13, 22), Vector2(-21, 7)]), skin)
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -5), Vector2(10, -5), Vector2(13, 16), Vector2(-12, 16)]), belly)
	for y in range(3):
		draw_line(Vector2(-9, 1 + y * 5), Vector2(9, 1 + y * 5), Color("#c79c51"), 1.5)

	# Head, horns, eyes and muzzle
	draw_circle(Vector2(0, -22), 15, skin)
	draw_circle(Vector2(0, -14), 11, Color("#8bc84a"))
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -27), Vector2(-18, -39), Vector2(-7, -34), Vector2(-3, -29)]), horn)
	draw_colored_polygon(PackedVector2Array([Vector2(12, -27), Vector2(18, -39), Vector2(7, -34), Vector2(3, -29)]), horn)
	draw_rect(Rect2(-10, -25, 7, 6), Color.WHITE)
	draw_rect(Rect2(3, -25, 7, 6), Color.WHITE)
	draw_circle(Vector2(-6, -22), 2.0, dark)
	draw_circle(Vector2(6, -22), 2.0, dark)
	draw_line(Vector2(-11, -29), Vector2(-3, -27), dark, 3.0)
	draw_line(Vector2(3, -27), Vector2(11, -29), dark, 3.0)
	draw_arc(Vector2(0, -12), 7, 0.15, PI - 0.15, 20, dark, 2.0)

	# Gold wrist bands and spikes
	draw_rect(Rect2(-23, 3, 7, 7), Color("#f2c84b"))
	draw_rect(Rect2(16, 3, 7, 7), Color("#f2c84b"))
	draw_colored_polygon(PackedVector2Array([Vector2(-21, 4), Vector2(-24, -3), Vector2(-17, 2)]), horn)
	draw_colored_polygon(PackedVector2Array([Vector2(21, 4), Vector2(24, -3), Vector2(17, 2)]), horn)

func take_stomp() -> void:
	health -= 1
	damage_flash = 0.18
	if health_label != null:
		health_label.text = "BOWSER " + str(max(health, 0)) + "/" + str(max_health)
	queue_redraw()
	if health <= 0:
		queue_free()
