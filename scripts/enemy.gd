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


func _ready() -> void:
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
		var dir := (player.global_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()

	if flash_timer > 0:
		flash_timer -= delta

	if player and global_position.distance_to(player.global_position) > 1500:
		queue_free()

	queue_redraw()


func _draw() -> void:
	var c := color
	if flash_timer > 0:
		c = Color.WHITE
	var half := size / 2.0
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
		died.emit(global_position, xp_value)
		queue_free()


func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null
