extends Node2D

const CELL := 32
const GRID_W := 24
const GRID_H := 12
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")

var level_cells: Array = []
var enemy_cells: Array = []

func _ready() -> void:
	_load_level()
	_build_world()
	_spawn_enemies()
	_setup_camera()
	queue_redraw()

func _setup_camera() -> void:
	var player := get_node_or_null("Player") as CharacterBody2D
	if player == null:
		return

	var camera := Camera2D.new()
	camera.name = "FollowCamera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = level_cells[0].size() * CELL if not level_cells.is_empty() else GRID_W * CELL
	camera.limit_bottom = level_cells.size() * CELL if not level_cells.is_empty() else GRID_H * CELL
	player.add_child(camera)

func _load_level() -> void:
	if not FileAccess.file_exists("user://level.json"):
		_create_default_level()
		return

	var file := FileAccess.open("user://level.json", FileAccess.READ)
	if file == null:
		_create_default_level()
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not parsed.has("cells") or not parsed["cells"] is Array:
		_create_default_level()
		return

	var candidate: Array = parsed["cells"]
	if candidate.size() != GRID_H:
		_create_default_level()
		return

	for row in candidate:
		if not row is Array or row.size() != GRID_W:
			_create_default_level()
			return
		for block in row:
			if not block is int or int(block) < 0 or int(block) > 3:
				_create_default_level()
				return

	level_cells = candidate.duplicate(true)
	enemy_cells = parsed.get("enemies", []) if parsed.get("enemies", []) is Array else []

func _create_default_level() -> void:
	level_cells.clear()
	enemy_cells.clear()
	for y in range(GRID_H):
		var row: Array = []
		for x in range(GRID_W):
			row.append(1 if y == 10 else 0)
		level_cells.append(row)

func _build_world() -> void:
	# Merge adjacent blocks of the same type into one collision shape.
	for y in range(GRID_H):
		var x := 0
		while x < GRID_W:
			var block_id := int(level_cells[y][x])
			if block_id == 0:
				x += 1
				continue

			var run_start := x
			while x < GRID_W and int(level_cells[y][x]) == block_id:
				x += 1
			var run_length := x - run_start

			var body := StaticBody2D.new()
			body.position = Vector2(
				(run_start + run_length / 2.0) * CELL,
				y * CELL + CELL / 2.0
			)
			body.set_meta("block_id", block_id)

			var collision := CollisionShape2D.new()
			var shape := RectangleShape2D.new()
			shape.size = Vector2(run_length * CELL, CELL)
			collision.shape = shape
			body.add_child(collision)
			add_child(body)

func _spawn_enemies() -> void:
	for data in enemy_cells:
		if not data is Dictionary or not data.has("x") or not data.has("y"):
			continue
		var cell_x := int(data["x"])
		var cell_y := int(data["y"])
		if cell_x < 0 or cell_x >= GRID_W or cell_y < 0 or cell_y >= GRID_H:
			continue
		var enemy := ENEMY_SCENE.instantiate()
		enemy.position = Vector2(cell_x * CELL + CELL / 2.0, cell_y * CELL + CELL / 2.0)
		add_child(enemy)

func _draw() -> void:
	for y in range(level_cells.size()):
		for x in range(level_cells[y].size()):
			var block_id := int(level_cells[y][x])
			if block_id == 0:
				continue

			var rect := Rect2(Vector2(x * CELL, y * CELL), Vector2(CELL, CELL))
			match block_id:
				1:
					draw_rect(rect, Color("#438c59"))
					draw_rect(Rect2(rect.position, Vector2(CELL, 5)), Color("#75cf83"))
					draw_line(rect.position + Vector2(0, CELL - 1), rect.position + Vector2(CELL, CELL - 1), Color("#2d6842"), 2.0)
				2:
					draw_rect(rect, Color("#a96d3f"))
					draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2(CELL - 2, CELL - 2)), Color("#c98a54"), false, 2.0)
					draw_line(rect.position + Vector2(0, CELL / 2.0), rect.position + Vector2(CELL, CELL / 2.0), Color("#80502f"), 2.0)
				3:
					draw_rect(rect, Color("#b83245"))
					draw_colored_polygon(PackedVector2Array([
						rect.position + Vector2(2, CELL - 2),
						rect.position + Vector2(CELL / 2.0, 5),
						rect.position + Vector2(CELL - 2, CELL - 2)
					]), Color("#ff7a78"))
			draw_rect(rect, Color("#182536"), false, 1.0)
