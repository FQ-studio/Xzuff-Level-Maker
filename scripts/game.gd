extends Node2D

const CELL := 32
const GRID_W := 48
const GRID_H := 12
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/boss.tscn")

var level_cells: Array = []
var level_width := GRID_W
var level_height := GRID_H
var enemy_cells: Array = []
var boss_data = null

func _ready() -> void:
	_load_level()
	_build_world()
	_spawn_enemies()
	_spawn_boss()
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
	camera.limit_right = level_width * CELL
	camera.limit_bottom = level_height * CELL
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
	var source_width := -1
	for row in candidate:
		if not row is Array or (row.size() != 24 and row.size() != GRID_W):
			_create_default_level()
			return
		if source_width == -1:
			source_width = row.size()
		elif row.size() != source_width:
			_create_default_level()
			return
		for block in row:
			if not block is int or int(block) < 0 or int(block) > 4:
				_create_default_level()
				return

	level_width = GRID_W
	level_height = GRID_H
	level_cells.clear()
	for y in range(GRID_H):
		var expanded_row: Array = candidate[y].duplicate()
		while expanded_row.size() < GRID_W:
			expanded_row.append(0)
		level_cells.append(expanded_row)
	enemy_cells = parsed.get("enemies", []) if parsed.get("enemies", []) is Array else []
	boss_data = parsed.get("boss", null)

func _create_default_level() -> void:
	level_width = GRID_W
	level_height = GRID_H
	level_cells.clear()
	enemy_cells.clear()
	boss_data = null
	for y in range(GRID_H):
		var row: Array = []
		for x in range(GRID_W):
			row.append(1 if y == 10 else 0)
		level_cells.append(row)

func _build_world() -> void:
	# Merge adjacent blocks of the same type into one collision shape.
	for y in range(level_height):
		var x := 0
		while x < level_width:
			var block_id := int(level_cells[y][x])
			if block_id == 0:
				x += 1
				continue
			var run_start := x
			while x < level_width and int(level_cells[y][x]) == block_id:
				x += 1
			var run_length := x - run_start

			var body := StaticBody2D.new()
			body.position = Vector2((run_start + run_length / 2.0) * CELL, y * CELL + CELL / 2.0)
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
		if cell_x < 0 or cell_x >= level_width or cell_y < 0 or cell_y >= level_height:
			continue
		var enemy := ENEMY_SCENE.instantiate()
		enemy.position = Vector2(cell_x * CELL + CELL / 2.0, cell_y * CELL + CELL / 2.0)
		add_child(enemy)

func _spawn_boss() -> void:
	if not boss_data is Dictionary or not boss_data.has("x") or not boss_data.has("y"):
		return
	var cell_x := int(boss_data["x"])
	var cell_y := int(boss_data["y"])
	if cell_x < 0 or cell_x >= level_width or cell_y < 0 or cell_y >= level_height:
		return
	var boss := BOSS_SCENE.instantiate()
	boss.position = Vector2(cell_x * CELL + CELL / 2.0, cell_y * CELL + CELL / 2.0)
	add_child(boss)

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
				4:
					draw_rect(rect, Color("#566174"))
					draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(CELL - 4, CELL - 4)), Color("#78869d"), false, 2.0)
					draw_line(rect.position + Vector2(0, CELL / 2.0), rect.position + Vector2(CELL, CELL / 2.0), Color("#3b4659"), 2.0)
			draw_rect(rect, Color("#182536"), false, 1.0)
