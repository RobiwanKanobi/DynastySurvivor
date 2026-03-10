extends Area2D

var direction := Vector2.RIGHT
var speed := 400.0
var damage := 10.0
var pierce := 1
var proj_size := Vector2(10, 5)
var color := Color.YELLOW

var lifetime := 5.0
var hits := 0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	rotation = direction.angle()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = proj_size
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(-proj_size.x / 2, -proj_size.y / 2, proj_size.x, proj_size.y), color)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		hits += 1
		if hits >= pierce:
			queue_free()
