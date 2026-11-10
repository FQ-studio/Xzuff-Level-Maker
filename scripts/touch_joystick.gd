extends Control

signal horizontal_changed(value: float)

var active_touch := -1
var axis := 0.0
var knob_offset := Vector2.ZERO
var radius := 48.0

func _ready() -> void:
	custom_minimum_size = Vector2(120, 120)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_touch == -1:
			active_touch = event.index
			_update_axis(event.position)
		elif not event.pressed and event.index == active_touch:
			active_touch = -1
			axis = 0.0
			knob_offset = Vector2.ZERO
			horizontal_changed.emit(0.0)
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == active_touch:
		_update_axis(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			active_touch = -2
			_update_axis(event.position)
		else:
			active_touch = -1
			axis = 0.0
			knob_offset = Vector2.ZERO
			horizontal_changed.emit(0.0)
			queue_redraw()
	elif event is InputEventMouseMotion and active_touch == -2:
		_update_axis(event.position)

func _update_axis(position: Vector2) -> void:
	var center := size * 0.5
	var offset := position - center
	if offset.length() > radius:
		offset = offset.normalized() * radius
	knob_offset = offset
	axis = clampf(offset.x / radius, -1.0, 1.0)
	horizontal_changed.emit(axis)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radius + 7.0, Color(0.04, 0.08, 0.14, 0.62))
	draw_circle(center, radius, Color(0.35, 0.48, 0.62, 0.42))
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.82, 0.9, 1.0, 0.85), 3.0)
	draw_circle(center + knob_offset, 23.0, Color(0.78, 0.88, 1.0, 0.92))
	draw_arc(center + knob_offset, 23.0, 0.0, TAU, 32, Color(1, 1, 1, 0.9), 2.0)
