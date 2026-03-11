extends CharacterBody2D

var speed := 180.0
var attack_damage := 8.0
var attack_cooldown := 0.8
var attack_timer := 0.0
var attack_range := 35.0
var formation_offset := Vector2.ZERO
var color := Color(0.3, 0.55, 1.0)
var size := 18.0


func _ready() -> void:
	add_to_group("allies")
	collision_layer = 0
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
	if not player:
		return

	var target_pos := player.position + formation_offset
	var nearest := _find_nearest_enemy()

	if nearest and position.distance_to(nearest.position) < 120.0:
		velocity = (nearest.position - position).normalized() * speed
	else:
		var to_target := target_pos - position
		if to_target.length() > 25.0:
			velocity = to_target.normalized() * speed * 0.8
		else:
			velocity = Vector2.ZERO

	move_and_slide()

	attack_timer += delta
	if attack_timer >= attack_cooldown and nearest:
		if position.distance_to(nearest.position) < attack_range:
			nearest.take_damage(attack_damage)
			attack_timer = 0.0

	queue_redraw()


func _draw() -> void:
	if get_tree().get_meta("show_shadows", false):
		_draw_shadow()
	var half := size / 2.0
	draw_rect(Rect2(-half, -half, size, size), color)
	draw_rect(Rect2(-5, -4, 3, 3), Color(0.1, 0.2, 0.5))
	draw_rect(Rect2(2, -4, 3, 3), Color(0.1, 0.2, 0.5))


func _draw_shadow() -> void:
	var half := size / 2.0
	var pts := PackedVector2Array()
	for i in range(16):
		var a := TAU * i / 16.0
		pts.append(Vector2(cos(a) * half * 0.9, sin(a) * half * 0.3 + half))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.2))


func _get_player() -> Node2D:
	var p := get_tree().get_nodes_in_group("player")
	return p[0] if p.size() > 0 else null


func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var best := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		var d := position.distance_to(e.position)
		if d < best:
			best = d
			nearest = e
	return nearest
