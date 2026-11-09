extends Node2D

const CELL := 32
var level_cells: Array = []

func _ready() -> void:
	_load_level()
	_build_world()
	queue_redraw()

func _load_level() -> void:
	if not FileAccess.file_exists("user://level.json"):
		return
	var file := FileAccess.open("user://level.json", FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and parsed.has("cells"):
		level_cells = parsed["cells"]

func _build_world() -> void:
	if level_cells.is_empty():
		level_cells = []
		for y in range(12):
			var row: Array = []
			for x in range(24):
				row.append(1 if y == 10 else 0)
			level_cells.append(row)

	for y in range(level_cells.size()):
		for x in range(level_cells[y].size()):
			var block_id := int(level_cells[y][x])
			if block_id == 0:
				continue
			var body := StaticBody2D.new()
			body.position = Vector2(x * CELL + CELL / 2.0, y * CELL + CELL / 2.0)
			var collision := CollisionShape2D.new()
			var shape := RectangleShape2D.new()
			shape.size = Vector2(CELL, CELL)
			collision.shape = shape
			body.add_child(collision)
			add_child(body)

func _draw() -> void:
	for y in range(level_cells.size()):
		for x in range(level_cells[y].size()):
			var block_id := int(level_cells[y][x])
			if block_id == 0:
				continue
			var color := Color("#54a86b") if block_id == 1 else Color("#bd824c") if block_id == 2 else Color("#d95757")
			draw_rect(Rect2(Vector2(x * CELL, y * CELL), Vector2(CELL - 1, CELL - 1)), color)
