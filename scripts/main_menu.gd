extends Control

var camera_mode := 0
var spawn_mode := 0
var camera_group: ButtonGroup
var spawn_group: ButtonGroup


func _ready() -> void:
	camera_mode = get_tree().get_meta("camera_mode", 0)
	spawn_mode = get_tree().get_meta("spawn_mode", 0)
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
	vbox.offset_left = -290
	vbox.offset_top = -260
	vbox.offset_right = 290
	vbox.offset_bottom = 260
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	var title := Label.new()
	title.text = "DYNASTY\nSURVIVORS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Vampire Survivors x Dynasty Warriors"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(sub)

	_add_spacer(vbox, 6)
	_add_section_label(vbox, "CAMERA")

	camera_group = ButtonGroup.new()
	var cam_row := HBoxContainer.new()
	cam_row.add_theme_constant_override("separation", 6)
	cam_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(cam_row)
	_add_toggle(cam_row, "Top-Down", 0, camera_group, camera_mode)
	_add_toggle(cam_row, "2D Skew", 1, camera_group, camera_mode)
	_add_toggle(cam_row, "3/4 View", 2, camera_group, camera_mode)
	_add_toggle(cam_row, "3D Sim", 3, camera_group, camera_mode)

	_add_spacer(vbox, 4)
	_add_section_label(vbox, "BATTLE")

	spawn_group = ButtonGroup.new()
	var spawn_row := HBoxContainer.new()
	spawn_row.add_theme_constant_override("separation", 6)
	spawn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(spawn_row)
	_add_toggle(spawn_row, "Classic", 0, spawn_group, spawn_mode)
	_add_toggle(spawn_row, "Battlefield", 1, spawn_group, spawn_mode)
	_add_toggle(spawn_row, "Army", 2, spawn_group, spawn_mode)

	_add_spacer(vbox, 8)

	var play_btn := Button.new()
	play_btn.text = "PLAY"
	play_btn.custom_minimum_size = Vector2(220, 55)
	play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_btn.add_theme_font_size_override("font_size", 24)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.2, 0.4, 0.8)
	ps.set_corner_radius_all(6)
	play_btn.add_theme_stylebox_override("normal", ps)
	var ph := ps.duplicate() as StyleBoxFlat
	ph.bg_color = Color(0.3, 0.5, 0.9)
	play_btn.add_theme_stylebox_override("hover", ph)
	var pp := ps.duplicate() as StyleBoxFlat
	pp.bg_color = Color(0.15, 0.3, 0.7)
	play_btn.add_theme_stylebox_override("pressed", pp)
	play_btn.pressed.connect(_on_play)
	vbox.add_child(play_btn)

	var hint := Label.new()
	hint.text = "WASD / Arrow Keys / Touch to move\nWeapons fire automatically"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	vbox.add_child(hint)


func _add_spacer(parent: VBoxContainer, height: float) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, height)
	parent.add_child(s)


func _add_section_label(parent: VBoxContainer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	parent.add_child(l)


func _add_toggle(parent: HBoxContainer, text: String, mode_idx: int,
		group: ButtonGroup, current: int) -> void:
	var btn := Button.new()
	btn.text = text
	btn.toggle_mode = true
	btn.button_group = group
	btn.custom_minimum_size = Vector2(125, 36)
	btn.button_pressed = (mode_idx == current)
	btn.set_meta("mode", mode_idx)
	btn.add_theme_font_size_override("font_size", 13)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.14, 0.14, 0.24)
	normal.set_corner_radius_all(4)
	normal.border_color = Color(0.25, 0.25, 0.4)
	normal.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", normal)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.2, 0.35, 0.7)
	pressed.set_corner_radius_all(4)
	pressed.border_color = Color(0.4, 0.5, 0.9)
	pressed.set_border_width_all(1)
	btn.add_theme_stylebox_override("pressed", pressed)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.18, 0.18, 0.32)
	hover.set_corner_radius_all(4)
	hover.border_color = Color(0.3, 0.3, 0.5)
	hover.set_border_width_all(1)
	btn.add_theme_stylebox_override("hover", hover)

	parent.add_child(btn)


func _on_play() -> void:
	var cam_btn := camera_group.get_pressed_button()
	var sp_btn := spawn_group.get_pressed_button()
	camera_mode = cam_btn.get_meta("mode") if cam_btn else 0
	spawn_mode = sp_btn.get_meta("mode") if sp_btn else 0
	get_tree().set_meta("camera_mode", camera_mode)
	get_tree().set_meta("spawn_mode", spawn_mode)
	if camera_mode == 3:
		get_tree().change_scene_to_file("res://scenes/game_3d.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/game.tscn")
