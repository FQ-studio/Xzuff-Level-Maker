extends Control

const GRID_W := 24
const GRID_H := 12
const CELL := 32
const SAVE_PATH := "user://level.json"

var cells: Array = []
var enemies: Array[Vector2i] = []
var selected_tool := 1
var grid_view: Control
var status_label: Label

func _ready() -> void:
	cells.resize(GRID_H)
	for y in range(GRID_H):
		cells[y] = []
		for x in range(GRID_W):
			cells[y].append(0)
	_build_ui()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "XZUFF LEVEL EDITOR"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var back := Button.new()
	back.text = "MAIN MENU"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	header.add_child(back)

	var tools := HBoxContainer.new()
	root.add_child(tools)
	_add_tool_button(tools, "Erase", 0)
	_add_tool_button(tools, "Ground", 1)
	_add_tool_button(tools, "Brick", 2)
	_add_tool_button(tools, "Hazard", 3)
	_add_tool_button(tools, "Enemy", 4)
	var save_button := Button.new()
	save_button.text = "SAVE"
	save_button.pressed.connect(_save_level)
	tools.add_child(save_button)
	var test_button := Button.new()
	test_button.text = "PLAY / TEST"
	test_button.pressed.connect(_test_level)
	tools.add_child(test_button)

	grid_view = Control.new()
	grid_view.custom_minimum_size = Vector2(GRID_W * CELL, GRID_H * CELL)
	grid_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid_view.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid_view.draw.connect(_draw_grid)
	grid_view.gui_input.connect(_on_grid_input)
	root.add_child(grid_view)

	status_label = Label.new()
	status_label.text = "Choose a tool, then tap a grid cell."
	root.add_child(status_label)

func _add_tool_button(parent: HBoxContainer, caption: String, tool_id: int) -> void:
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
			grid_view.draw_rect(rect, color)
	for cell in enemies:
		var center := Vector2(cell.x * CELL + CELL / 2.0, cell.y * CELL + CELL / 2.0)
		grid_view.draw_circle(center, 10.0, Color("#ff9a45"))
		grid_view.draw_circle(center + Vector2(-3, -2), 2.0, Color.WHITE)
		grid_view.draw_circle(center + Vector2(3, -2), 2.0, Color.WHITE)

func _on_grid_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell_x := int(event.position.x / CELL)
		var cell_y := int(event.position.y / CELL)
		if cell_x < 0 or cell_x >= GRID_W or cell_y < 0 or cell_y >= GRID_H:
			return
		var cell := Vector2i(cell_x, cell_y)
		if selected_tool == 4:
			if not enemies.has(cell):
				enemies.append(cell)
				status_label.text = "Enemy placed."
		else:
			cells[cell_y][cell_x] = selected_tool
			if selected_tool == 0:
				enemies.erase(cell)
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
	file.store_string(JSON.stringify({
		"width": GRID_W,
		"height": GRID_H,
		"cells": cells,
		"enemies": enemy_data
	}))
	status_label.text = "Level saved on this device."

func _test_level() -> void:
	_save_level()
	get_tree().change_scene_to_file("res://scenes/game.tscn")
