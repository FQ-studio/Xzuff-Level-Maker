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
	_draw_castle_arena()

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

func _draw_castle_arena() -> void:
	# Scrolling sky and distant hills behind the playable level.
	draw_rect(Rect2(0, 0, level_width * CELL, level_height * CELL), Color("#83c9ee"))
	for i in range(7):
		var x := float(i) * 260.0 + 70.0
		var cloud_y := 82.0 + float(i % 2) * 24.0
		draw_circle(Vector2(x, cloud_y), 25.0, Color("#d9eff8"))
		draw_circle(Vector2(x + 24.0, cloud_y), 19.0, Color("#d9eff8"))
		draw_circle(Vector2(x - 22.0, cloud_y + 9.0), 17.0, Color("#d9eff8"))
	for i in range(6):
		var hill_x := float(i) * 300.0 - 40.0
		draw_colored_polygon(PackedVector2Array([Vector2(hill_x, 320), Vector2(hill_x + 115, 205), Vector2(hill_x + 245, 320)]), Color("#78b987"))

	# Castle at the far end of the level: keep the central gate visible.
	var cx := float(level_width * CELL) - 250.0
	draw_rect(Rect2(cx, 174, 190, 210), Color("#7b8295"))
	draw_rect(Rect2(cx + 12, 188, 166, 196), Color("#aeb6c5"))
	draw_rect(Rect2(cx + 70, 276, 50, 108), Color("#343d59"))
	for tower_x in [cx - 18.0, cx + 142.0]:
		draw_rect(Rect2(tower_x, 125, 66, 259), Color("#737b91"))
		draw_rect(Rect2(tower_x - 8, 112, 82, 22), Color("#4e5871"))
		draw_colored_polygon(PackedVector2Array([Vector2(tower_x - 8, 112), Vector2(tower_x + 33, 65), Vector2(tower_x + 74, 112)]), Color("#a74743"))
		draw_rect(Rect2(tower_x + 25, 155, 16, 28), Color("#343d59"))
	draw_rect(Rect2(cx + 30, 215, 18, 25), Color("#f5d77a"))
	draw_rect(Rect2(cx + 142, 215, 18, 25), Color("#f5d77a"))
	draw_line(Vector2(cx + 95, 70), Vector2(cx + 95, 28), Color("#3e465e"), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(cx + 98, 30), Vector2(cx + 139, 43), Vector2(cx + 98, 56)]), Color("#d94b48"))

