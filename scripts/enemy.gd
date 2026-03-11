extends CharacterBody2D

signal died(pos: Vector2, xp_val: int)

var hp := 30.0
var max_hp := 30.0
var speed := 60.0
var contact_damage := 10.0
var xp_value := 3
var size := 24.0
var color := Color(0.3, 0.65, 0.2)

var flash_timer := 0.0
var texture_name := ""
var _tex: Texture2D

static var _bat_tex: Texture2D
static var _golem_tex: Texture2D


func _ready() -> void:
	if not _bat_tex:
		_bat_tex = load("res://assets/bat.png") as Texture2D
	if not _golem_tex:
		_golem_tex = load("res://assets/golem.png") as Texture2D
	match texture_name:
		"bat": _tex = _bat_tex
		"golem": _tex = _golem_tex
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(size, size)
	cs.shape = shape
	add_child(cs)


func get_half_size() -> float:
	return size / 2.0


func _physics_process(delta: float) -> void:
	var player := _get_player()
	if player:
		var dir := (player.position - position).normalized()
		velocity = dir * speed
		move_and_slide()

	if flash_timer > 0:
		flash_timer -= delta

	if player and position.distance_to(player.position) > 1500:
		queue_free()

	queue_redraw()


func _draw() -> void:
	if get_tree().get_meta("show_shadows", false):
		_draw_shadow()
	var use_art: bool = get_tree().get_meta("use_art", false)
	var c := color
	if flash_timer > 0:
		c = Color.WHITE
	var half := size / 2.0
	if use_art and _tex:
		var ys: float = get_tree().get_meta("y_scale", 1.0)
		var y_comp: float = 1.0 / ys if ys < 0.98 else 1.0
		var sprite_w: float = size * 2.5
		var sprite_h: float = sprite_w * y_comp
		var tint := Color(1, 1, 1) if flash_timer <= 0 else Color(3, 3, 3)
		draw_texture_rect(_tex, Rect2(-sprite_w / 2, -sprite_h, sprite_w, sprite_h),
			false, tint)
	else:
		draw_rect(Rect2(-half, -half, size, size), c)
	if hp < max_hp:
		var bar_w := size
		var bar_h := 3.0
		var bar_y := -half - 6
		draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.3, 0.0, 0.0))
		draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * (hp / max_hp), bar_h), Color(0.9, 0.1, 0.1))


func take_damage(amount: float) -> void:
	hp -= amount
	flash_timer = 0.1
	if hp <= 0:
		died.emit(position, xp_value)
		queue_free()


func _draw_shadow() -> void:
	var half := size / 2.0
	var pts := PackedVector2Array()
	for i in range(16):
		var a := TAU * i / 16.0
		pts.append(Vector2(cos(a) * half * 0.9, sin(a) * half * 0.3 + half))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.2))


func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null
