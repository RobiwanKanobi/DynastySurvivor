extends Node2D

var player: Node2D
var camera: Camera2D
var enemies_node: Node2D
var projectiles_node: Node2D
var gems_node: Node2D
var effects_node: Node2D
var allies_node: Node2D
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
var enemy_hp_mult := 1.0
var paused_by_test_panel := false

var camera_mode := 0
var spawn_mode := 0
var y_scale_val := 1.0

const Y_SCALES := [1.0, 0.6, 0.7, 0.5]

var enemy_defs := {
	"bat": {"hp": 15.0, "speed": 110.0, "damage": 5.0, "xp": 1,
		"size": 16.0, "color": Color(0.9, 0.25, 0.2)},
	"zombie": {"hp": 35.0, "speed": 55.0, "damage": 10.0, "xp": 3,
		"size": 24.0, "color": Color(0.3, 0.65, 0.2)},
	"golem": {"hp": 100.0, "speed": 30.0, "damage": 20.0, "xp": 10,
		"size": 40.0, "color": Color(0.55, 0.2, 0.75)},
}


func _ready() -> void:
	camera_mode = get_tree().get_meta("camera_mode", 0)
	spawn_mode = get_tree().get_meta("spawn_mode", 0)
	y_scale_val = Y_SCALES[camera_mode] if camera_mode < Y_SCALES.size() else 1.0

	_build_containers()
	_build_player()
	_build_camera()
	_apply_camera_mode()
	_build_ui()

	if spawn_mode == 2:
		_set_army_size(20)


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
	allies_node = Node2D.new()
	allies_node.name = "Allies"
	add_child(allies_node)


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


var ground_tex: Texture2D


func _apply_camera_mode() -> void:
	scale.y = y_scale_val
	get_tree().set_meta("y_scale", y_scale_val)
	_update_ysort_and_shadows()
	ground_tex = load("res://assets/ground_tile.png") as Texture2D


func _update_ysort_and_shadows() -> void:
	var use_ysort := y_scale_val < 0.98
	get_tree().set_meta("show_shadows", use_ysort)
	enemies_node.y_sort_enabled = use_ysort
	projectiles_node.y_sort_enabled = use_ysort
	gems_node.y_sort_enabled = use_ysort
	effects_node.y_sort_enabled = use_ysort
	allies_node.y_sort_enabled = use_ysort


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
	test_panel.enemy_hp_mult_changed.connect(_on_enemy_hp_mult_changed)
	test_panel.panel_toggled.connect(_on_test_panel_toggled)
	test_panel.army_size_changed.connect(_on_army_size_changed)
	test_panel.camera_angle_scrolled.connect(_on_camera_angle_scrolled)
	test_panel.art_toggled.connect(_on_art_toggled)
	test_panel.set_spawn_interval(base_spawn_interval)
	test_panel.set_army_size(allies_node.get_child_count())


func _process(delta: float) -> void:
	if is_game_over:
		return
	game_time += delta
	difficulty = 1.0 + game_time / 60.0

	var spawn_interval: float = maxf(0.3, base_spawn_interval - game_time * 0.008)
	spawn_timer += delta
	if spawn_timer >= spawn_interval and enemies_node.get_child_count() < 150:
		spawn_timer = 0.0
		if spawn_mode == 0:
			_spawn_enemy_classic()
		else:
			_spawn_enemy_battlefield()

	hud.update_time(game_time)
	hud.update_kills(kills)
	hud.update_level(player.level)
	queue_redraw()


func _get_narrow() -> float:
	return clampf(y_scale_val, 0.2, 1.0)


func _draw() -> void:
	if not player:
		return
	if y_scale_val >= 0.98:
		_draw_flat_grid()
	else:
		_draw_perspective_grid()


func _draw_flat_grid() -> void:
	var center := player.global_position
	var hw := 800.0
	var hh := 500.0
	var use_art: bool = get_tree().get_meta("use_art", false)
	if use_art and ground_tex:
		_draw_tiled_ground(center, hw * 1.2, hh * 1.2)
		return
	else:
		draw_rect(Rect2(center.x - hw, center.y - hh, hw * 2, hh * 2),
			Color(0.08, 0.08, 0.12))
		var gs := 64.0
		var gc := Color(0.12, 0.12, 0.18)
		var sx := snappedf(center.x - hw, gs) - gs
		var x := sx
		while x <= center.x + hw + gs:
			draw_line(Vector2(x, center.y - hh - gs), Vector2(x, center.y + hh + gs), gc, 1.0)
			x += gs
		var sy := snappedf(center.y - hh, gs) - gs
		var y := sy
		while y <= center.y + hh + gs:
			draw_line(Vector2(center.x - hw - gs, y), Vector2(center.x + hw + gs, y), gc, 1.0)
			y += gs


func _draw_tiled_ground(center: Vector2, hw: float, hh: float) -> void:
	var ts := 256.0
	var sx := snappedf(center.x - hw, ts) - ts
	var sy := snappedf(center.y - hh, ts) - ts
	var tx := sx
	while tx < center.x + hw + ts:
		var ty := sy
		while ty < center.y + hh + ts:
			draw_texture_rect(ground_tex, Rect2(tx, ty, ts, ts), false)
			ty += ts
		tx += ts


func _draw_perspective_grid() -> void:
	var center := player.global_position
	var hw := 800.0
	var hh: float = 600.0 / y_scale_val
	var narrow := _get_narrow()
	var use_art: bool = get_tree().get_meta("use_art", false)

	var top_y := center.y - hh
	var bot_y := center.y + hh
	var full_h := bot_y - top_y

	if use_art and ground_tex:
		_draw_tiled_ground(center, hw * 1.5, hh * 1.5)
		return

	draw_rect(Rect2(center.x - hw - 100, top_y - 100,
		(hw + 100) * 2, full_h + 200), Color(0.03, 0.03, 0.06))

	var strips := 20
	for i in range(strips):
		var t0 := float(i) / strips
		var t1 := float(i + 1) / strips
		var y0 := lerpf(bot_y, top_y, t0)
		var y1 := lerpf(bot_y, top_y, t1)
		var s0 := lerpf(1.0, narrow, t0)
		var s1 := lerpf(1.0, narrow, t1)
		var b0 := lerpf(0.13, 0.05, t0)
		var b1 := lerpf(0.13, 0.05, t1)
		draw_polygon(
			PackedVector2Array([
				Vector2(center.x - hw * s0, y0),
				Vector2(center.x + hw * s0, y0),
				Vector2(center.x + hw * s1, y1),
				Vector2(center.x - hw * s1, y1),
			]),
			PackedColorArray([
				Color(b0, b0, b0 + 0.04),
				Color(b0, b0, b0 + 0.04),
				Color(b1, b1, b1 + 0.03),
				Color(b1, b1, b1 + 0.03),
			])
		)

	var gs := 64.0
	var gc := Color(0.18, 0.18, 0.26)
	var sy := snappedf(top_y, gs) - gs
	var gy := sy
	while gy <= bot_y + gs:
		var t := clampf((bot_y - gy) / full_h, 0.0, 1.0)
		var s := lerpf(1.0, narrow, t)
		var alpha := lerpf(0.45, 0.1, t)
		draw_line(Vector2(center.x - hw * s, gy),
			Vector2(center.x + hw * s, gy),
			Color(gc.r, gc.g, gc.b, alpha), 1.0)
		gy += gs

	var sx := snappedf(center.x - hw, gs) - gs
	var gx := sx
	while gx <= center.x + hw + gs:
		var x_off := gx - center.x
		var x_top := center.x + x_off * narrow
		draw_line(Vector2(x_top, top_y), Vector2(gx, bot_y),
			Color(gc.r, gc.g, gc.b, 0.3), 1.0)
		gx += gs

	if y_scale_val < 0.55:
		for i in range(12):
			var t := float(i) / 12.0
			var fy := top_y + full_h * t * 0.15
			var fa := (1.0 - t) * 0.6
			var fs := narrow + t * 0.04
			draw_line(Vector2(center.x - hw * fs, fy),
				Vector2(center.x + hw * fs, fy),
				Color(0.05, 0.05, 0.09, fa), 6.0)


func _spawn_enemy_classic() -> void:
	var type_name := _pick_enemy_type()
	var angle := randf() * TAU
	var dist := 650.0 + randf() * 150.0
	var pos := player.position + Vector2(cos(angle), sin(angle)) * dist
	_create_enemy(type_name, pos)


func _spawn_enemy_battlefield() -> void:
	var type_name := _pick_enemy_type()
	var angle := randf_range(-1.2, 1.2)
	var dist := 600.0 + randf() * 250.0
	var pos := player.position + Vector2(cos(angle) * dist, sin(angle) * dist)
	_create_enemy(type_name, pos)


func _pick_enemy_type() -> String:
	var r := randf()
	if game_time > 90.0 and r < 0.2:
		return "golem"
	elif game_time > 60.0 and r < 0.15:
		return "golem"
	elif game_time > 30.0 and r < 0.35:
		return "zombie"
	return "bat"


func _create_enemy(type_name: String, pos: Vector2) -> void:
	var data: Dictionary = enemy_defs[type_name].duplicate()
	data["hp"] *= difficulty * enemy_hp_mult
	data["speed"] = minf(data["speed"] * (1.0 + (difficulty - 1.0) * 0.3), data["speed"] * 2.0)

	var enemy := CharacterBody2D.new()
	enemy.set_script(preload("res://scripts/enemy.gd"))
	enemy.position = pos
	enemy.hp = data["hp"]
	enemy.max_hp = data["hp"]
	enemy.speed = data["speed"]
	enemy.contact_damage = data["damage"]
	enemy.xp_value = data["xp"]
	enemy.size = data["size"]
	enemy.color = data["color"]
	enemy.texture_name = type_name
	enemies_node.add_child(enemy)
	enemy.died.connect(_on_enemy_died)


func _set_army_size(target: int) -> void:
	var current := allies_node.get_child_count()
	if target > current:
		for i in range(target - current):
			_spawn_single_ally()
	elif target < current:
		var to_remove := current - target
		for i in range(to_remove):
			if allies_node.get_child_count() > 0:
				allies_node.get_child(allies_node.get_child_count() - 1).queue_free()


func _spawn_single_ally() -> void:
	var idx := allies_node.get_child_count()
	var row: int = idx / 5
	var col: int = idx % 5
	var offset := Vector2(-(row + 1) * 45.0 - 30.0, (col - 2) * 40.0)
	var ally := CharacterBody2D.new()
	ally.set_script(preload("res://scripts/ally.gd"))
	ally.position = player.position + offset
	ally.formation_offset = offset
	allies_node.add_child(ally)


func spawn_projectile(pos: Vector2, dir: Vector2, spd: float, dmg: float,
		prc: int, sz: Vector2, clr: Color) -> void:
	var proj := Area2D.new()
	proj.set_script(preload("res://scripts/projectile.gd"))
	proj.position = pos
	proj.direction = dir
	proj.speed = spd
	proj.damage = dmg
	proj.pierce = prc
	proj.proj_size = sz
	proj.color = clr
	projectiles_node.add_child(proj)


func apply_aura_damage(pos: Vector2, radius: float, dmg: float) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if pos.distance_to(e.position) <= radius:
			e.take_damage(dmg)


func spawn_aura_effect(pos: Vector2, radius: float, clr: Color) -> void:
	var effect := Node2D.new()
	effect.set_script(preload("res://scripts/aura_effect.gd"))
	effect.position = pos
	effect.radius = radius
	effect.color = clr
	effects_node.add_child(effect)


func spawn_xp_gem(pos: Vector2, value: int) -> void:
	var gem := Area2D.new()
	gem.set_script(preload("res://scripts/xp_gem.gd"))
	gem.position = pos
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


func _on_enemy_hp_mult_changed(value: float) -> void:
	enemy_hp_mult = value


func _on_army_size_changed(value: int) -> void:
	_set_army_size(value)


func _on_art_toggled(enabled: bool) -> void:
	get_tree().set_meta("use_art", enabled)


func _on_camera_angle_scrolled(delta: float) -> void:
	y_scale_val = clampf(y_scale_val + delta, 0.3, 1.0)
	scale.y = y_scale_val
	get_tree().set_meta("y_scale", y_scale_val)
	_update_ysort_and_shadows()


func _on_test_panel_toggled(opened: bool) -> void:
	paused_by_test_panel = opened
	if opened:
		get_tree().paused = true
	elif not is_game_over and not level_up_ui.visible:
		get_tree().paused = false


func _on_player_died() -> void:
	is_game_over = true
	get_tree().paused = true
	game_over_ui.show_results(game_time, kills, player.level)
