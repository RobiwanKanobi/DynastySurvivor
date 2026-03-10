extends Node2D

var radius := 100.0
var color := Color.CYAN
var lifetime := 0.3
var timer := 0.0


func _process(delta: float) -> void:
	timer += delta
	if timer >= lifetime:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var t := timer / lifetime
	var c := Color(color.r, color.g, color.b, (1.0 - t) * 0.4)
	var r := radius * (0.5 + t * 0.5)
	draw_arc(Vector2.ZERO, r, 0, TAU, 64, c, 3.0)
	draw_circle(Vector2.ZERO, r, Color(c.r, c.g, c.b, c.a * 0.15))
