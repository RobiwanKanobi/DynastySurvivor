extends Node2D

var player: Node2D
var camera: Camera2D
var enemies_node: Node2D
var projectiles_node: Node2D
var gems_node: Node2D
var effects_node: Node2D
var ui_layer: CanvasLayer
var hud: Control
var level_up_ui: Control
var game_over_ui: Control
var test_panel: Control

var game_time := 0.0
var spawn_timer := 0.0
var kills := 0
var is_game_over := false

var difficulty := 1.0
var base_spawn_interval := 1.5

var enemy_defs := {
	"bat": {"hp": 15.0, "speed": 110.0, "damage": 5.0, "xp": 1,
		"size": 16.0, "color": Color(0.9, 0.25, 0.2)},
	"zombie": {"hp": 35.0, "speed": 55.0, "damage": 10.0, "xp": 3,
		"size": 24.0, "color": Color(0.3, 0.65, 0.2)},
	"golem": {"hp": 100.0, "speed": 30.0, "damage": 20.0, "xp": 10,
		"size": 40.0, "color": Color(0.55, 0.2, 0.75)},
}


func _ready() -> void:
	_build_containers()
	_build_player()
	_build_camera()
	_build_ui()


func _build_containers() -> void:
	enemies_node = Node2D.new()
	enemies_node.name = "Enemies"
	add_child(enemies_node)
	projectiles_node = Node2D.new()
	projectiles_node.name = "Projectiles"
	add_child(projectiles_node)
	gems_node = Node2D.new()
	gems_node.name = "Gems"
	add_child(gems_node)
	effects_node = Node2D.new()
	effects_node.name = "Effects"
	add_child(effects_node)


func _build_player() -> void:
	player = CharacterBody2D.new()
	player.set_script(preload("res://scripts/player.gd"))
	player.game_node = self
	player.health_changed.connect(_on_health_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.leveled_up.connect(_on_player_leveled_up)
	player.player_died.connect(_on_player_died)
	add_child(player)


func _build_camera() -> void:
	camera = Camera2D.new()
	camera.make_current()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)


func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)

	hud = Control.new()
	hud.set_script(preload("res://scripts/hud.gd"))
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(hud)

	level_up_ui = Control.new()
	level_up_ui.set_script(preload("res://scripts/level_up_ui.gd"))
	level_up_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	level_up_ui.visible = false
	level_up_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(level_up_ui)
	level_up_ui.upgrade_chosen.connect(_on_upgrade_chosen)

	game_over_ui = Control.new()
	game_over_ui.set_script(preload("res://scripts/game_over_ui.gd"))
	game_over_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_ui.visible = false
	game_over_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(game_over_ui)

	test_panel = Control.new()
	test_panel.set_script(preload("res://scripts/test_panel.gd"))
	test_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	test_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(test_panel)
	test_panel.spawn_interval_changed.connect(_on_spawn_interval_changed)
	test_panel.set_spawn_interval(base_spawn_interval)


func _process(delta: float) -> void:
	if is_game_over:
		return
	game_time += delta
	difficulty = 1.0 + game_time / 60.0

	var spawn_interval: float = maxf(0.3, base_spawn_interval - game_time * 0.008)
	spawn_timer += delta
	if spawn_timer >= spawn_interval and enemies_node.get_child_count() < 150:
		spawn_timer = 0.0
		_spawn_enemy()

	hud.update_time(game_time)
	hud.update_kills(kills)
	hud.update_level(player.level)
	queue_redraw()


func _draw() -> void:
	if not player:
		return
	var center := player.global_position
	var hw := 800.0
	var hh := 500.0
	draw_rect(Rect2(center.x - hw, center.y - hh, hw * 2, hh * 2),
		Color(0.08, 0.08, 0.12))
	var gs := 64.0
	var sx := snappedf(center.x - hw, gs) - gs
	var sy := snappedf(center.y - hh, gs) - gs
	var gc := Color(0.12, 0.12, 0.18)
	var x := sx
	while x <= center.x + hw + gs:
		draw_line(Vector2(x, center.y - hh - gs), Vector2(x, center.y + hh + gs), gc, 1.0)
		x += gs
	var y := sy
	while y <= center.y + hh + gs:
		draw_line(Vector2(center.x - hw - gs, y), Vector2(center.x + hw + gs, y), gc, 1.0)
		y += gs


func _spawn_enemy() -> void:
	var type_name := "bat"
	var r := randf()
	if game_time > 90.0 and r < 0.2:
		type_name = "golem"
	elif game_time > 60.0 and r < 0.15:
		type_name = "golem"
	elif game_time > 30.0 and r < 0.35:
		type_name = "zombie"

	var angle := randf() * TAU
	var dist := 650.0 + randf() * 150.0
	var pos := player.global_position + Vector2(cos(angle), sin(angle)) * dist

	var data: Dictionary = enemy_defs[type_name].duplicate()
	data["hp"] *= difficulty
	data["speed"] = min(data["speed"] * (1.0 + (difficulty - 1.0) * 0.3), data["speed"] * 2.0)

	var enemy := CharacterBody2D.new()
	enemy.set_script(preload("res://scripts/enemy.gd"))
	enemy.global_position = pos
	enemy.hp = data["hp"]
	enemy.max_hp = data["hp"]
	enemy.speed = data["speed"]
	enemy.contact_damage = data["damage"]
	enemy.xp_value = data["xp"]
	enemy.size = data["size"]
	enemy.color = data["color"]
	enemies_node.add_child(enemy)
	enemy.died.connect(_on_enemy_died)


func spawn_projectile(pos: Vector2, dir: Vector2, spd: float, dmg: float,
		prc: int, sz: Vector2, clr: Color) -> void:
	var proj := Area2D.new()
	proj.set_script(preload("res://scripts/projectile.gd"))
	proj.global_position = pos
	proj.direction = dir
	proj.speed = spd
	proj.damage = dmg
	proj.pierce = prc
	proj.proj_size = sz
	proj.color = clr
	projectiles_node.add_child(proj)


func apply_aura_damage(pos: Vector2, radius: float, dmg: float) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if pos.distance_to(e.global_position) <= radius:
			e.take_damage(dmg)


func spawn_aura_effect(pos: Vector2, radius: float, clr: Color) -> void:
	var effect := Node2D.new()
	effect.set_script(preload("res://scripts/aura_effect.gd"))
	effect.global_position = pos
	effect.radius = radius
	effect.color = clr
	effects_node.add_child(effect)


func spawn_xp_gem(pos: Vector2, value: int) -> void:
	var gem := Area2D.new()
	gem.set_script(preload("res://scripts/xp_gem.gd"))
	gem.global_position = pos
	gem.xp_value = value
	gems_node.add_child(gem)


func _on_enemy_died(pos: Vector2, xp_val: int) -> void:
	kills += 1
	spawn_xp_gem(pos, xp_val)


func _on_health_changed(current: float, maximum: float) -> void:
	hud.update_health(current, maximum)


func _on_xp_changed(current: int, needed: int) -> void:
	hud.update_xp(current, needed)


func _on_player_leveled_up(_level: int) -> void:
	get_tree().paused = true
	player.pending_levels -= 1
	level_up_ui.show_choices(player)


func _on_upgrade_chosen() -> void:
	level_up_ui.visible = false
	if player.pending_levels > 0:
		player.pending_levels -= 1
		level_up_ui.show_choices(player)
	else:
		get_tree().paused = false


func _on_spawn_interval_changed(value: float) -> void:
	base_spawn_interval = value


func _on_player_died() -> void:
	is_game_over = true
	get_tree().paused = true
	game_over_ui.show_results(game_time, kills, player.level)
