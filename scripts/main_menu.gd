extends Control


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.08, 0.14)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -200
	vbox.offset_top = -160
	vbox.offset_right = 200
	vbox.offset_bottom = 160
	vbox.add_theme_constant_override("separation", 16)
	add_child(vbox)

	var title := Label.new()
	title.text = "DYNASTY\nSURVIVORS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "A Vampire Survivors-like"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var btn := Button.new()
	btn.text = "PLAY"
	btn.custom_minimum_size = Vector2(200, 60)
	btn.add_theme_font_size_override("font_size", 26)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.4, 0.8)
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.3, 0.5, 0.9)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.15, 0.3, 0.7)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.pressed.connect(_on_play)
	vbox.add_child(btn)

	var hint := Label.new()
	hint.text = "WASD / Arrow Keys to move\nWeapons fire automatically"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	vbox.add_child(hint)


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
