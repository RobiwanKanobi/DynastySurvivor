extends CharacterBody2D

signal health_changed(current_hp: float, max_hp: float)
signal xp_changed(current_xp: int, needed_xp: int)
signal leveled_up(new_level: int)
signal player_died

const BASE_SPEED := 200.0
const INVINCIBILITY_DURATION := 0.8
const BASE_PICKUP_RANGE := 80.0

var max_hp := 100.0
var hp := 100.0
var xp := 0
var level := 1
var xp_to_next := 5
var pickup_range := BASE_PICKUP_RANGE
var pending_levels := 0

var damage_mult := 1.0
var speed_mult := 1.0
var area_mult := 1.0
var cooldown_mult := 1.0
var extra_projectiles := 0

var weapons: Array[Dictionary] = []
var weapon_timers: Array[float] = []

var invincible := false
var inv_timer := 0.0

var touch_active := false
var touch_position := Vector2.ZERO

var game_node: Node = null


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 0
	_create_collision_shape()
	_create_pickup_area()
	add_weapon("knife")


func _create_collision_shape() -> void:
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24, 24)
	cs.shape = shape
	add_child(cs)


func _create_pickup_area() -> void:
	var area := Area2D.new()
	area.name = "PickupArea"
	area.collision_layer = 0
	area.collision_mask = 8
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = pickup_range
	cs.shape = shape
	area.add_child(cs)
	area.area_entered.connect(_on_pickup_area_entered)
	add_child(area)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			touch_active = event.pressed
			if event.pressed:
				touch_position = get_global_mouse_position()
	elif event is InputEventMouseMotion and touch_active:
		touch_position = get_global_mouse_position()
	elif event is InputEventScreenTouch:
		touch_active = event.pressed
		if event.pressed:
			touch_position = get_canvas_transform().affine_inverse() * event.position
	elif event is InputEventScreenDrag and touch_active:
		touch_position = get_canvas_transform().affine_inverse() * event.position


func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1

	if dir == Vector2.ZERO and touch_active:
		var to_target := touch_position - global_position
		if to_target.length() > 8.0:
			dir = to_target.normalized()

	velocity = dir.normalized() * BASE_SPEED * speed_mult
	move_and_slide()

	if invincible:
		inv_timer -= delta
		if inv_timer <= 0.0:
			invincible = false

	_check_enemy_contact()
	_process_weapons(delta)
	queue_redraw()


func _draw() -> void:
	if get_tree().get_meta("show_shadows", false):
		_draw_shadow()
	var alpha := 1.0
	if invincible and fmod(inv_timer, 0.15) < 0.075:
		alpha = 0.3
	draw_rect(Rect2(-12, -12, 24, 24), Color(1, 1, 1, alpha))
	draw_rect(Rect2(-7, -6, 4, 4), Color(0.2, 0.6, 1.0, alpha))
	draw_rect(Rect2(3, -6, 4, 4), Color(0.2, 0.6, 1.0, alpha))
	draw_rect(Rect2(-4, 4, 8, 2), Color(0.8, 0.8, 0.8, alpha))


func _draw_shadow() -> void:
	var pts := PackedVector2Array()
	for i in range(16):
		var a := TAU * i / 16.0
		pts.append(Vector2(cos(a) * 12.0, sin(a) * 4.0 + 12.0))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.2))


func _check_enemy_contact() -> void:
	if invincible:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist := global_position.distance_to(enemy.global_position)
		var threshold: float = 12.0 + enemy.get_half_size()
		if dist < threshold:
			take_damage(enemy.contact_damage)
			break


func take_damage(amount: float) -> void:
	if invincible:
		return
	hp = max(hp - amount, 0.0)
	invincible = true
	inv_timer = INVINCIBILITY_DURATION
	health_changed.emit(hp, max_hp)
	if hp <= 0.0:
		player_died.emit()


func heal(amount: float) -> void:
	hp = min(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)


func add_xp(amount: int) -> void:
	xp += amount
	var leveled := false
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = 5 + level * 5
		pending_levels += 1
		leveled = true
	xp_changed.emit(xp, xp_to_next)
	if leveled:
		leveled_up.emit(level)


func add_weapon(wname: String) -> void:
	var w: Dictionary
	match wname:
		"knife":
			w = {"id": "knife", "name": "Knife", "type": "projectile",
				"damage": 10.0, "cooldown": 1.0, "speed": 400.0, "pierce": 1,
				"count": 1, "size": Vector2(10, 5), "color": Color(1, 0.9, 0.2)}
		"holy_aura":
			w = {"id": "holy_aura", "name": "Holy Aura", "type": "aura",
				"damage": 8.0, "cooldown": 1.2, "radius": 100.0,
				"color": Color(0.4, 0.8, 1.0, 0.3)}
		"magic_orb":
			w = {"id": "magic_orb", "name": "Magic Orb", "type": "projectile",
				"damage": 20.0, "cooldown": 2.5, "speed": 150.0, "pierce": 99,
				"count": 1, "size": Vector2(18, 18), "color": Color(0.7, 0.3, 1.0)}
	weapons.append(w)
	weapon_timers.append(0.0)


func has_weapon(weapon_id: String) -> bool:
	for w in weapons:
		if w["id"] == weapon_id:
			return true
	return false


func _process_weapons(delta: float) -> void:
	for i in range(weapons.size()):
		weapon_timers[i] += delta
		var w := weapons[i]
		var cd: float = w["cooldown"] * cooldown_mult
		if weapon_timers[i] < cd:
			continue
		weapon_timers[i] = 0.0
		match w["type"]:
			"projectile":
				_fire_projectile(w)
			"aura":
				_fire_aura(w)


func _fire_projectile(w: Dictionary) -> void:
	if not game_node:
		return
	var target := _find_nearest_enemy()
	if not target:
		return
	var dir := (target.global_position - global_position).normalized()
	var count: int = w["count"] + extra_projectiles
	var spread := 0.15
	for idx in range(count):
		var offset := 0.0
		if count > 1:
			offset = (idx - (count - 1) / 2.0) * spread
		var d := dir.rotated(offset)
		game_node.spawn_projectile(global_position, d, w["speed"],
			w["damage"] * damage_mult, w["pierce"], w["size"], w["color"])


func _fire_aura(w: Dictionary) -> void:
	if not game_node:
		return
	var radius: float = w["radius"] * area_mult
	game_node.apply_aura_damage(global_position, radius, w["damage"] * damage_mult)
	game_node.spawn_aura_effect(global_position, radius, w["color"])


func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var best_dist := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		var d := global_position.distance_to(e.global_position)
		if d < best_dist:
			best_dist = d
			nearest = e
	return nearest


func _on_pickup_area_entered(area: Area2D) -> void:
	if area.is_in_group("gems") and area.has_method("collect"):
		area.collect(self)
