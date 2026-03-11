extends Area2D

var xp_value := 1
var gem_size := 8.0
var attract_speed := 0.0
var attracted := false
var target: Node2D = null
var collected := false
var lifetime := 30.0


func _ready() -> void:
	add_to_group("gems")
	collision_layer = 8
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = gem_size
	cs.shape = shape
	add_child(cs)


func _physics_process(delta: float) -> void:
	if collected:
		return
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	if attracted and is_instance_valid(target):
		attract_speed += 600.0 * delta
		var dir := (target.position - position).normalized()
		position += dir * attract_speed * delta
		if position.distance_to(target.position) < 16:
			_do_collect()
	queue_redraw()


func _draw() -> void:
	var points := PackedVector2Array([
		Vector2(0, -gem_size),
		Vector2(gem_size * 0.6, 0),
		Vector2(0, gem_size),
		Vector2(-gem_size * 0.6, 0),
	])
	draw_colored_polygon(points, Color(0.2, 0.9, 0.3))


func collect(player: Node2D) -> void:
	if attracted or collected:
		return
	attracted = true
	target = player
	attract_speed = 100.0


func _do_collect() -> void:
	if collected:
		return
	collected = true
	if is_instance_valid(target) and target.has_method("add_xp"):
		target.add_xp(xp_value)
	queue_free()
