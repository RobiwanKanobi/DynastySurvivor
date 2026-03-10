extends Control

signal spawn_interval_changed(value: float)
signal enemy_hp_mult_changed(value: float)
signal panel_toggled(opened: bool)

var panel: PanelContainer
var is_open := false
var spawn_label: Label
var spawn_slider: HSlider
var hp_label: Label
var hp_slider: HSlider


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_toggle()
	_build_panel()


func _build_toggle() -> void:
	var btn := Button.new()
	btn.text = "TEST"
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.offset_left = -80
	btn.offset_right = -10
	btn.offset_top = 10
	btn.offset_bottom = 38
	btn.add_theme_font_size_override("font_size", 13)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.3, 0.45, 0.85)
	style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.4, 0.4, 0.55, 0.9)
	btn.add_theme_stylebox_override("hover", hover)
	btn.pressed.connect(_toggle)
	add_child(btn)


func _build_panel() -> void:
	panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -270
	panel.offset_right = -10
	panel.offset_top = 44
	panel.offset_bottom = 230
	panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.18, 0.92)
	style.set_corner_radius_all(6)
	style.border_color = Color(0.3, 0.3, 0.5)
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "TEST ENVIRONMENT"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
	vbox.add_child(title)

	var paused_hint := Label.new()
	paused_hint.text = "(game paused)"
	paused_hint.add_theme_font_size_override("font_size", 11)
	paused_hint.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	vbox.add_child(paused_hint)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	spawn_label = Label.new()
	spawn_label.text = "Spawn Interval: 1.50s"
	spawn_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(spawn_label)

	spawn_slider = HSlider.new()
	spawn_slider.min_value = 0.1
	spawn_slider.max_value = 5.0
	spawn_slider.step = 0.05
	spawn_slider.value = 1.5
	spawn_slider.custom_minimum_size = Vector2(230, 20)
	spawn_slider.value_changed.connect(_on_spawn_changed)
	vbox.add_child(spawn_slider)

	hp_label = Label.new()
	hp_label.text = "Enemy HP: x1.00"
	hp_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(hp_label)

	hp_slider = HSlider.new()
	hp_slider.min_value = 0.1
	hp_slider.max_value = 10.0
	hp_slider.step = 0.1
	hp_slider.value = 1.0
	hp_slider.custom_minimum_size = Vector2(230, 20)
	hp_slider.value_changed.connect(_on_hp_changed)
	vbox.add_child(hp_slider)


func _toggle() -> void:
	is_open = !is_open
	panel.visible = is_open
	panel_toggled.emit(is_open)


func _on_spawn_changed(value: float) -> void:
	spawn_label.text = "Spawn Interval: %.2fs" % value
	spawn_interval_changed.emit(value)


func _on_hp_changed(value: float) -> void:
	hp_label.text = "Enemy HP: x%.2f" % value
	enemy_hp_mult_changed.emit(value)


func set_spawn_interval(value: float) -> void:
	if spawn_slider:
		spawn_slider.value = value
		spawn_label.text = "Spawn Interval: %.2fs" % value
