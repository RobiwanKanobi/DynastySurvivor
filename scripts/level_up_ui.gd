extends Control

signal upgrade_chosen

var choices_container: VBoxContainer
var player_ref: Node2D

const UPGRADES := [
	{"id": "holy_aura", "name": "Holy Aura", "desc": "Damages nearby enemies", "type": "weapon"},
	{"id": "magic_orb", "name": "Magic Orb", "desc": "Slow piercing orb", "type": "weapon"},
	{"id": "damage", "name": "+20% Damage", "desc": "All weapons deal more damage", "type": "stat"},
	{"id": "speed", "name": "+15% Speed", "desc": "Move faster", "type": "stat"},
	{"id": "area", "name": "+25% Area", "desc": "Larger weapon area", "type": "stat"},
	{"id": "cooldown", "name": "-15% Cooldown", "desc": "Weapons fire faster", "type": "stat"},
	{"id": "projectile", "name": "+1 Projectile", "desc": "Extra projectile per attack", "type": "stat"},
	{"id": "heal", "name": "Heal 30 HP", "desc": "Restore health", "type": "stat"},
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.6)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -200
	panel.offset_top = -200
	panel.offset_right = 200
	panel.offset_bottom = 200
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.22, 0.95)
	style.set_corner_radius_all(8)
	style.border_color = Color(0.4, 0.4, 0.7)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "LEVEL UP!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	vbox.add_child(title)

	choices_container = VBoxContainer.new()
	choices_container.add_theme_constant_override("separation", 8)
	vbox.add_child(choices_container)


func show_choices(player: Node2D) -> void:
	player_ref = player
	visible = true
	for c in choices_container.get_children():
		c.queue_free()

	var available: Array = []
	for u in UPGRADES:
		if u["type"] == "weapon" and player.has_weapon(u["id"]):
			continue
		available.append(u)
	available.shuffle()
	var count := mini(3, available.size())
	for i in range(count):
		_add_choice_button(available[i])


func _add_choice_button(upgrade: Dictionary) -> void:
	var btn := Button.new()
	btn.text = "%s\n%s" % [upgrade["name"], upgrade["desc"]]
	btn.custom_minimum_size = Vector2(340, 65)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.32)
	style.set_corner_radius_all(4)
	style.border_color = Color(0.35, 0.35, 0.6)
	style.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.25, 0.25, 0.45)
	hover_style.border_color = Color(0.5, 0.5, 0.9)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.3, 0.3, 0.5)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.add_theme_font_size_override("font_size", 15)
	btn.pressed.connect(_on_choice_pressed.bind(upgrade))
	choices_container.add_child(btn)


func _on_choice_pressed(upgrade: Dictionary) -> void:
	if not player_ref:
		return
	match upgrade["id"]:
		"holy_aura":
			player_ref.add_weapon("holy_aura")
		"magic_orb":
			player_ref.add_weapon("magic_orb")
		"damage":
			player_ref.damage_mult += 0.2
		"speed":
			player_ref.speed_mult += 0.15
		"area":
			player_ref.area_mult += 0.25
		"cooldown":
			player_ref.cooldown_mult *= 0.85
		"projectile":
			player_ref.extra_projectiles += 1
		"heal":
			player_ref.heal(30.0)
	upgrade_chosen.emit()
