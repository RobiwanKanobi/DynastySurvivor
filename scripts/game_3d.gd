extends Node3D

var player: Node3D
var cam_pivot: Node3D
var camera: Camera3D
var ground: MeshInstance3D
var enemies_node: Node3D
var projectiles_node: Node3D
var gems_node: Node3D
var allies_node: Node3D
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
var spawn_mode := 0

var cam_angle := 55.0

var player_tex: Texture2D
var bat_tex: Texture2D
var golem_tex: Texture2D
var ground_tex: Texture2D

var enemy_defs := {
	"bat": {"hp": 15.0, "speed": 11.0, "damage": 5.0, "xp": 1,
		"size": 1.6, "color": Color(0.9, 0.25, 0.2), "sprite_scale": 3.0},
	"zombie": {"hp": 35.0, "speed": 5.5, "damage": 10.0, "xp": 3,
		"size": 2.4, "color": Color(0.3, 0.65, 0.2), "sprite_scale": 4.0},
	"golem": {"hp": 100.0, "speed": 3.0, "damage": 20.0, "xp": 10,
		"size": 4.0, "color": Color(0.55, 0.2, 0.75), "sprite_scale": 6.0},
}


func _ready() -> void:
	spawn_mode = get_tree().get_meta("spawn_mode", 0)
	get_tree().set_meta("show_shadows", false)
	get_tree().set_meta("y_scale", 1.0)

	player_tex = load("res://assets/player.png") as Texture2D
	bat_tex = load("res://assets/bat.png") as Texture2D
	golem_tex = load("res://assets/golem.png") as Texture2D
	ground_tex = load("res://assets/ground_tile.png") as Texture2D

	_build_environment()
	_build_containers()
	_build_player()
	_build_camera()
	_build_ui()

	if spawn_mode == 2:
		_set_army_size(20)


func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.45, 0.35, 0.25)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.WHITE
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = false
	add_child(sun)

	ground = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	plane.subdivide_width = 0
	plane.subdivide_depth = 0
	ground.mesh = plane

	var mat := StandardMaterial3D.new()
	if ground_tex:
		mat.albedo_texture = ground_tex
		mat.uv1_scale = Vector3(25, 25, 1)
	else:
		mat.albedo_color = Color(0.4, 0.32, 0.22)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground.material_override = mat
	ground.position.y = 0.0
	add_child(ground)


func _build_containers() -> void:
	enemies_node = Node3D.new()
	enemies_node.name = "Enemies"
	add_child(enemies_node)
	projectiles_node = Node3D.new()
	projectiles_node.name = "Projectiles"
	add_child(projectiles_node)
	gems_node = Node3D.new()
	gems_node.name = "Gems"
	add_child(gems_node)
	allies_node = Node3D.new()
	allies_node.name = "Allies"
	add_child(allies_node)


func _build_player() -> void:
	player = Node3D.new()
	player.set_script(preload("res://scripts/player_3d.gd"))
	player.game_node = self
	player.health_changed.connect(_on_health_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.leveled_up.connect(_on_player_leveled_up)
	player.player_died.connect(_on_player_died)
	add_child(player)

	var sprite := Sprite3D.new()
	sprite.name = "Sprite"
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = 0.05
	sprite.position.y = 3.2
	sprite.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	if player_tex:
		sprite.texture = player_tex
	player.add_child(sprite)


func _build_camera() -> void:
	cam_pivot = Node3D.new()
	cam_pivot.name = "CamPivot"
	player.add_child(cam_pivot)

	camera = Camera3D.new()
	camera.name = "Camera"
	camera.fov = 50.0
	camera.position = Vector3(0, 0, 0)
	cam_pivot.add_child(camera)

	_update_camera_angle()


func _update_camera_angle() -> void:
	cam_pivot.rotation_degrees.x = -cam_angle
	var dist := 40.0
	camera.position = Vector3(0, 0, dist)


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

	_handle_input(delta)
	_check_enemy_contact()

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

	_process_weapons(delta)
	_process_projectiles(delta)
	_process_gems(delta)
	_process_allies(delta)

	if player.invincible:
		player.inv_timer -= delta
		if player.inv_timer <= 0.0:
			player.invincible = false
		var sprite := player.get_node("Sprite") as Sprite3D
		if sprite:
			sprite.modulate.a = 0.3 if fmod(player.inv_timer, 0.15) < 0.075 else 1.0
	else:
		var sprite := player.get_node("Sprite") as Sprite3D
		if sprite:
			sprite.modulate.a = 1.0

	hud.update_time(game_time)
	hud.update_kills(kills)
	hud.update_level(player.level)

	_move_ground()


func _handle_input(_delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.z -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.z += 1
	if dir.length() > 0:
		dir = dir.normalized()
	player.position += dir * player.BASE_SPEED * player.speed_mult * _delta


func _check_enemy_contact() -> void:
	if player.invincible:
		return
	for enemy in get_tree().get_nodes_in_group("enemies_3d"):
		var dist := _xz_dist(player.position, enemy.position)
		var threshold: float = 1.2 + enemy.get_meta("half_size", 1.0)
		if dist < threshold:
			player.take_damage(enemy.get_meta("contact_damage", 5.0))
			break


func _xz_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _move_ground() -> void:
	ground.position.x = player.position.x
	ground.position.z = player.position.z


func _process_weapons(delta: float) -> void:
	for i in range(player.weapons.size()):
		player.weapon_timers[i] += delta
		var w: Dictionary = player.weapons[i]
		var cd: float = w["cooldown"] * player.cooldown_mult
		if player.weapon_timers[i] < cd:
			continue
		player.weapon_timers[i] = 0.0
		match w["type"]:
			"projectile":
				_fire_projectile(w)
			"aura":
				_fire_aura(w)


func _fire_projectile(w: Dictionary) -> void:
	var target := _find_nearest_enemy()
	if not target:
		return
	var to_target: Vector3 = target.position - player.position
	var dir: Vector3 = Vector3(to_target.x, 0, to_target.z).normalized()
	var count: int = w["count"] + player.extra_projectiles
	for idx in range(count):
		var angle_off := 0.0
		if count > 1:
			angle_off = (idx - (count - 1) / 2.0) * 0.15
		var d := dir.rotated(Vector3.UP, angle_off)
		_spawn_projectile(player.position, d, w["speed"],
			w["damage"] * player.damage_mult, w["pierce"], w["size"], w["color"])


func _fire_aura(w: Dictionary) -> void:
	var radius: float = w["radius"] * player.area_mult
	for e in get_tree().get_nodes_in_group("enemies_3d"):
		if _xz_dist(player.position, e.position) <= radius:
			if e.has_method("take_damage_3d"):
				e.take_damage_3d(w["damage"] * player.damage_mult)


func _spawn_projectile(pos: Vector3, dir: Vector3, spd: float, dmg: float,
		prc: int, sz: float, clr: Color) -> void:
	var proj := Node3D.new()
	proj.position = Vector3(pos.x, 1.5, pos.z)
	proj.set_meta("direction", dir)
	proj.set_meta("speed", spd)
	proj.set_meta("damage", dmg)
	proj.set_meta("pierce", prc)
	proj.set_meta("hits", 0)
	proj.set_meta("lifetime", 5.0)
	proj.set_meta("size", sz)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(sz * 0.5, sz * 0.25, sz * 0.25)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = clr
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	proj.add_child(mesh)

	projectiles_node.add_child(proj)


func _process_projectiles(delta: float) -> void:
	for proj in projectiles_node.get_children():
		var dir: Vector3 = proj.get_meta("direction")
		var spd: float = proj.get_meta("speed")
		var lt: float = proj.get_meta("lifetime") - delta
		proj.set_meta("lifetime", lt)
		proj.position += dir * spd * delta
		if lt <= 0:
			proj.queue_free()
			continue
		var dmg: float = proj.get_meta("damage")
		var prc: int = proj.get_meta("pierce")
		var hits: int = proj.get_meta("hits")
		var sz: float = proj.get_meta("size")
		for enemy in get_tree().get_nodes_in_group("enemies_3d"):
			if _xz_dist(proj.position, enemy.position) < sz + enemy.get_meta("half_size", 1.0):
				if enemy.has_method("take_damage_3d"):
					enemy.take_damage_3d(dmg)
					hits += 1
					proj.set_meta("hits", hits)
					if hits >= prc:
						proj.queue_free()
						break


func _process_gems(delta: float) -> void:
	for gem in gems_node.get_children():
		var lt: float = gem.get_meta("lifetime", 30.0) - delta
		gem.set_meta("lifetime", lt)
		if lt <= 0:
			gem.queue_free()
			continue
		if gem.get_meta("attracted", false):
			var spd: float = gem.get_meta("attract_speed", 100.0) + 60.0 * delta
			gem.set_meta("attract_speed", spd)
			var dir: Vector3 = (player.position - gem.position).normalized()
			gem.position += dir * spd * delta
			if _xz_dist(gem.position, player.position) < 1.6:
				var xp_val: int = gem.get_meta("xp_value", 1)
				player.add_xp(xp_val)
				gem.queue_free()
		else:
			if _xz_dist(gem.position, player.position) < 8.0:
				gem.set_meta("attracted", true)
				gem.set_meta("attract_speed", 10.0)


func _process_allies(delta: float) -> void:
	for ally in allies_node.get_children():
		var offset: Vector3 = ally.get_meta("formation_offset", Vector3.ZERO)
		var target_pos := player.position + offset
		var nearest := _find_nearest_enemy_from(ally.position)
		var vel := Vector3.ZERO

		if nearest and _xz_dist(ally.position, nearest.position) < 12.0:
			vel = (nearest.position - ally.position).normalized() * 18.0
			var atk_timer: float = ally.get_meta("atk_timer", 0.0) + delta
			ally.set_meta("atk_timer", atk_timer)
			if atk_timer >= 0.8 and _xz_dist(ally.position, nearest.position) < 3.5:
				if nearest.has_method("take_damage_3d"):
					nearest.take_damage_3d(8.0)
				ally.set_meta("atk_timer", 0.0)
		else:
			var to_target: Vector3 = target_pos - ally.position
			if Vector2(to_target.x, to_target.z).length() > 2.5:
				vel = to_target.normalized() * 15.0

		ally.position += vel * delta


func _find_nearest_enemy() -> Node3D:
	var nearest: Node3D = null
	var best := INF
	for e in get_tree().get_nodes_in_group("enemies_3d"):
		var d := _xz_dist(player.position, e.position)
		if d < best:
			best = d
			nearest = e
	return nearest


func _find_nearest_enemy_from(pos: Vector3) -> Node3D:
	var nearest: Node3D = null
	var best := INF
	for e in get_tree().get_nodes_in_group("enemies_3d"):
		var d := _xz_dist(pos, e.position)
		if d < best:
			best = d
			nearest = e
	return nearest


func _spawn_enemy_classic() -> void:
	var type_name := _pick_enemy_type()
	var angle := randf() * TAU
	var dist := 65.0 + randf() * 15.0
	var pos := player.position + Vector3(cos(angle), 0, sin(angle)) * dist
	_create_enemy(type_name, pos)


func _spawn_enemy_battlefield() -> void:
	var type_name := _pick_enemy_type()
	var angle := randf_range(-1.2, 1.2)
	var dist := 60.0 + randf() * 25.0
	var pos := player.position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
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


func _create_enemy(type_name: String, pos: Vector3) -> void:
	var data: Dictionary = enemy_defs[type_name].duplicate()
	data["hp"] *= difficulty * enemy_hp_mult

	var enemy := Node3D.new()
	enemy.position = pos
	enemy.set_meta("hp", data["hp"])
	enemy.set_meta("max_hp", data["hp"])
	enemy.set_meta("speed", data["speed"])
	enemy.set_meta("contact_damage", data["damage"])
	enemy.set_meta("xp_value", data["xp"])
	enemy.set_meta("half_size", data["size"] / 2.0)
	enemy.set_meta("color", data["color"])
	enemy.set_meta("type_name", type_name)
	enemy.set_meta("flash", 0.0)
	enemy.add_to_group("enemies_3d")

	var use_art: bool = get_tree().get_meta("use_art", false)
	var sprite := Sprite3D.new()
	sprite.name = "Sprite"
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.pixel_size = 0.04
	sprite.position.y = data["sprite_scale"] * 0.5

	var tex: Texture2D = null
	match type_name:
		"bat": tex = bat_tex
		"golem": tex = golem_tex
	if use_art and tex:
		sprite.texture = tex
	else:
		sprite.texture = _make_color_tex(data["color"])
	enemy.add_child(sprite)

	var script_ref := GDScript.new()
	script_ref.source_code = '
extends Node3D

func take_damage_3d(amount: float) -> void:
	var hp: float = get_meta("hp") - amount
	set_meta("hp", hp)
	set_meta("flash", 0.1)
	if hp <= 0:
		get_parent().get_parent().call("_on_enemy_died_3d", position, get_meta("xp_value", 1))
		queue_free()
'
	script_ref.reload()
	enemy.set_script(script_ref)
	enemy.set_meta("hp", data["hp"])
	enemy.set_meta("max_hp", data["hp"])
	enemy.set_meta("speed", data["speed"])
	enemy.set_meta("contact_damage", data["damage"])
	enemy.set_meta("xp_value", data["xp"])
	enemy.set_meta("half_size", data["size"] / 2.0)
	enemy.set_meta("color", data["color"])
	enemy.set_meta("type_name", type_name)
	enemy.set_meta("flash", 0.0)
	enemy.add_to_group("enemies_3d")

	enemies_node.add_child(enemy)


func _make_color_tex(c: Color) -> ImageTexture:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)


func _on_enemy_died_3d(pos: Vector3, xp_val: int) -> void:
	kills += 1
	_spawn_xp_gem(pos, xp_val)


func _spawn_xp_gem(pos: Vector3, value: int) -> void:
	var gem := Node3D.new()
	gem.position = Vector3(pos.x, 0.5, pos.z)
	gem.set_meta("xp_value", value)
	gem.set_meta("lifetime", 30.0)
	gem.set_meta("attracted", false)
	gem.set_meta("attract_speed", 0.0)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.9, 0.3)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	mesh.rotation_degrees.y = 45
	gem.add_child(mesh)

	gems_node.add_child(gem)


func _set_army_size(target: int) -> void:
	var current := allies_node.get_child_count()
	if target > current:
		for i in range(target - current):
			_spawn_single_ally()
	elif target < current:
		for i in range(current - target):
			if allies_node.get_child_count() > 0:
				allies_node.get_child(allies_node.get_child_count() - 1).queue_free()


func _spawn_single_ally() -> void:
	var idx := allies_node.get_child_count()
	var row: int = idx / 5
	var col: int = idx % 5
	var offset := Vector3(-(row + 1) * 4.5 - 3.0, 0, (col - 2) * 4.0)

	var ally := Node3D.new()
	ally.position = player.position + offset
	ally.set_meta("formation_offset", offset)
	ally.set_meta("atk_timer", 0.0)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.5, 2.5, 1.5)
	mesh.mesh = box
	mesh.position.y = 1.25
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.55, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	ally.add_child(mesh)

	allies_node.add_child(ally)


# === Enemy movement (called each frame from _process) ===
func _move_enemies(delta: float) -> void:
	for enemy in enemies_node.get_children():
		var spd: float = enemy.get_meta("speed", 5.0)
		var dir: Vector3 = (player.position - enemy.position)
		dir.y = 0
		if dir.length() > 0.1:
			dir = dir.normalized()
		enemy.position += dir * spd * delta

		var flash: float = enemy.get_meta("flash", 0.0)
		if flash > 0:
			enemy.set_meta("flash", flash - delta)

		if _xz_dist(enemy.position, player.position) > 150:
			enemy.queue_free()


func _physics_process(delta: float) -> void:
	_move_enemies(delta)


# === Signal handlers ===

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

func _on_camera_angle_scrolled(delta_val: float) -> void:
	cam_angle = clampf(cam_angle + delta_val * 50.0, 15.0, 85.0)
	_update_camera_angle()

func _on_art_toggled(enabled: bool) -> void:
	get_tree().set_meta("use_art", enabled)

func _on_test_panel_toggled(opened: bool) -> void:
	if opened:
		get_tree().paused = true
	elif not is_game_over and not level_up_ui.visible:
		get_tree().paused = false

func _on_player_died() -> void:
	is_game_over = true
	get_tree().paused = true
	game_over_ui.show_results(game_time, kills, player.level)
