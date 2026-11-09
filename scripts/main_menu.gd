extends Control

const EDITOR_SCENE := "res://scenes/editor.tscn"

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#101827")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 360)
	center.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	panel.add_child(layout)

	var title := Label.new()
	title.text = "X Z U F F\nLEVEL MAKER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "BUILD IT. PLAY IT. SHARE IT."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(subtitle)

	var editor_button := Button.new()
	editor_button.text = "CREATE A LEVEL"
	editor_button.custom_minimum_size.y = 54
	editor_button.pressed.connect(_open_editor)
	layout.add_child(editor_button)

	var play_button := Button.new()
	play_button.text = "PLAY DEMO"
	play_button.custom_minimum_size.y = 48
	play_button.pressed.connect(_play_demo)
	layout.add_child(play_button)

	var footer := Label.new()
	footer.text = "Prototype 0.1 • Original Xzuff characters and worlds"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(footer)

func _open_editor() -> void:
	get_tree().change_scene_to_file(EDITOR_SCENE)

func _play_demo() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
