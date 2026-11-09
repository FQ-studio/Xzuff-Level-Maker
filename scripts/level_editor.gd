extends Control

const GRID_W := 48
const GRID_H := 12
const CELL := 32
const SAVE_PATH := "user://level.json"

var cells: Array = []
var enemies: Array[Vector2i] = []
var boss_cell := Vector2i(-1, -1)
var selected_tool := 1
var grid_view: Control
var status_label: Label

func _ready() -> void:
	_reset_grid()
	_build_ui()

func _reset_grid() -> void:
	cells.clear()
	for y in range(GRID_H):
		var row: Array = []
		for x in range(GRID_W):
			row.append(0)
		cells.append(row)

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "XZUFF LEVEL EDITOR — 48 × 12"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var back := Button.new()
	back.text = "MAIN MENU"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	header.add_child(back)

	var tools := HFlowContainer.new()
	root.add_child(tools)
	_add_tool_button(tools, "Erase", 0)
	_add_tool_button(tools, "Ground", 1)
	_add_tool_button(tools, "Brick", 2)
	_add_tool_button(tools, "Hazard", 3)
	_add_tool_button(tools, "Castle", 4)
	_add_tool_button(tools, "Enemy", 5)
	_add_tool_button(tools, "Final Boss", 6)

	var save_button := Button.new()
	save_button.text = "SAVE"
	save_button.pressed.connect(_save_level)
	tools.add_child(save_button)
	var load_button := Button.new()
	load_button.text = "LOAD"
	load_button.pressed.connect(_load_level)
	tools.add_child(load_button)
	var test_button := Button.new()
	test_button.text = "PLAY / TEST"
	test_button.pressed.connect(_test_level)
	tools.add_child(test_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(scroll)

	grid_view = Control.new()
	grid_view.custom_minimum_size = Vector2(GRID_W * CELL, GRID_H * CELL)
	grid_view.draw.connect(_draw_grid)
	grid_view.gui_input.connect(_on_grid_input)
	scroll.add_child(grid_view)

	status_label = Label.new()
	status_label.text = "Swipe sideways to edit the full 48-column level."
	root.add_child(status_label)

func _add_tool_button(parent: Container, caption: String, tool_id: int) -> void:
	var button := Button.new()
	button.text = caption
	button.pressed.connect(func():
		selected_tool = tool_id
		status_label.text = "Selected: " + caption
	)
	parent.add_child(button)

func _draw_grid() -> void:
	for y in range(GRID_H):
		for x in range(GRID_W):
			var rect := Rect2(Vector2(x * CELL, y * CELL), Vector2(CELL - 1, CELL - 1))
			var color := Color("#263449")
			match int(cells[y][x]):
				1: color = Color("#54a86b")
				2: color = Color("#bd824c")
				3: color = Color("#d95757")
				4: color = Color("#68758b")
			grid_view.draw_rect(rect, color)
			if int(cells[y][x]) == 4:
				grid_view.draw_rect(Rect2(rect.position + Vector2(5, 5), Vector2(22, 22)), Color("#9aa8bd"), false, 2.0)
	for cell in enemies:
		var center := Vector2(cell.x * CELL + CELL / 2.0, cell.y * CELL + CELL / 2.0)
		grid_view.draw_circle(center, 10.0, Color("#ff9a45"))
		grid_view.draw_circle(center + Vector2(-3, -2), 2.0, Color.WHITE)
		grid_view.draw_circle(center + Vector2(3, -2), 2.0, Color.WHITE)
	if boss_cell.x >= 0:
		var center := Vector2(boss_cell.x * CELL + CELL / 2.0, boss_cell.y * CELL + CELL / 2.0)
		grid_view.draw_circle(center, 13.0, Color("#b66cff"))
		grid_view.draw_colored_polygon(PackedVector2Array([
			center + Vector2(-11, -8), center + Vector2(-8, -17), center + Vector2(-2, -10)
		]), Color("#f1d36b"))
		grid_view.draw_colored_polygon(PackedVector2Array([
			center + Vector2(11, -8), center + Vector2(8, -17), center + Vector2(2, -10)
		]), Color("#f1d36b"))

func _on_grid_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell_x := int(event.position.x / CELL)
		var cell_y := int(event.position.y / CELL)
		if cell_x < 0 or cell_x >= GRID_W or cell_y < 0 or cell_y >= GRID_H:
			return
		var cell := Vector2i(cell_x, cell_y)
		match selected_tool:
			5:
				if not enemies.has(cell):
					enemies.append(cell)
				status_label.text = "Enemy placed."
			6:
				boss_cell = cell
				status_label.text = "Final boss placed."
			_:
				cells[cell_y][cell_x] = selected_tool
				if selected_tool == 0:
					enemies.erase(cell)
					if boss_cell == cell:
						boss_cell = Vector2i(-1, -1)
				status_label.text = "Block updated."
		grid_view.queue_redraw()

func _save_level() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		status_label.text = "Could not save level."
		return
	var enemy_data: Array = []
	for cell in enemies:
		enemy_data.append({"x": cell.x, "y": cell.y})
	var boss_data = null
	if boss_cell.x >= 0:
		boss_data = {"x": boss_cell.x, "y": boss_cell.y}
	file.store_string(JSON.stringify({
		"width": GRID_W,
		"height": GRID_H,
		"cells": cells,
		"enemies": enemy_data,
		"boss": boss_data
	}))
	status_label.text = "48-column level saved on this device."

func _test_level() -> void:
	_save_level()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _load_level() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		status_label.text = "No saved level found on this device."
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		status_label.text = "Could not open saved level."
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not parsed.has("cells") or not parsed["cells"] is Array:
		status_label.text = "Saved level data is invalid."
		return

	var loaded_cells: Array = parsed["cells"]
	if loaded_cells.size() != GRID_H:
		status_label.text = "Saved level has an incompatible grid height."
		return
	var source_width := -1
	for row in loaded_cells:
		if not row is Array or (row.size() != 24 and row.size() != GRID_W):
			status_label.text = "Saved level has an incompatible grid width."
			return
		if source_width == -1:
			source_width = row.size()
		elif row.size() != source_width:
			status_label.text = "Saved level rows have different widths."
			return
		for block in row:
			if not block is int or int(block) < 0 or int(block) > 4:
				status_label.text = "Saved level contains an unknown block."
				return

	_reset_grid()
	for y in range(GRID_H):
		for x in range(source_width):
			cells[y][x] = loaded_cells[y][x]

	enemies.clear()
	if parsed.get("enemies", []) is Array:
		for data in parsed.get("enemies", []):
			if data is Dictionary and data.has("x") and data.has("y"):
				var cell := Vector2i(int(data["x"]), int(data["y"]))
				if cell.x >= 0 and cell.x < GRID_W and cell.y >= 0 and cell.y < GRID_H and not enemies.has(cell):
					enemies.append(cell)

	boss_cell = Vector2i(-1, -1)
	var boss_data = parsed.get("boss", null)
	if boss_data is Dictionary and boss_data.has("x") and boss_data.has("y"):
		var candidate := Vector2i(int(boss_data["x"]), int(boss_data["y"]))
		if candidate.x >= 0 and candidate.x < GRID_W and candidate.y >= 0 and candidate.y < GRID_H:
			boss_cell = candidate

	grid_view.queue_redraw()
	status_label.text = "Level loaded. Old 24-column saves are expanded automatically."
