extends Node2D

const CELL := 32
var level_cells: Array = []

func _ready() -> void:
	_load_level()
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

func _draw() -> void:
	for y in range(level_cells.size()):
		for x in range(level_cells[y].size()):
			var block_id := int(level_cells[y][x])
			if block_id == 0:
				continue
			var color := Color("#54a86b") if block_id == 1 else Color("#bd824c") if block_id == 2 else Color("#d95757")
			draw_rect(Rect2(Vector2(x * CELL, y * CELL), Vector2(CELL - 1, CELL - 1)), color)
