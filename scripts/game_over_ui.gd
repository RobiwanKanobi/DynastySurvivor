extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func show_results(time: float, kills_count: int, level: int) -> void:
	visible = true
	for c in get_children():
		c.queue_free()
	_build_ui(time, kills_count, level)


func _build_ui(time: float, kills_count: int, level: int) -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -170
	panel.offset_top = -160
	panel.offset_right = 170
	panel.offset_bottom = 160
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.05, 0.05, 0.95)
	style.set_corner_radius_all(8)
	style.border_color = Color(0.7, 0.2, 0.2)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	vbox.add_child(title)

	var mins := int(time) / 60
	var secs := int(time) % 60
	_add_stat(vbox, "Time: %d:%02d" % [mins, secs])
	_add_stat(vbox, "Kills: %d" % kills_count)
	_add_stat(vbox, "Level: %d" % level)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	var restart_btn := Button.new()
	restart_btn.text = "Restart"
	restart_btn.custom_minimum_size = Vector2(0, 40)
	restart_btn.add_theme_font_size_override("font_size", 18)
	restart_btn.pressed.connect(_on_restart)
	vbox.add_child(restart_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Main Menu"
	menu_btn.custom_minimum_size = Vector2(0, 40)
	menu_btn.add_theme_font_size_override("font_size", 18)
	menu_btn.pressed.connect(_on_menu)
	vbox.add_child(menu_btn)


func _add_stat(parent: VBoxContainer, txt: String) -> void:
	var l := Label.new()
	l.text = txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 18)
	parent.add_child(l)


func _on_restart() -> void:
	get_tree().paused = false
	var cam: int = get_tree().get_meta("camera_mode", 0)
	if cam == 3:
		get_tree().change_scene_to_file("res://scenes/game_3d.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
