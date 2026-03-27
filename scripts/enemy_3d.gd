extends Node3D


func take_damage_3d(amount: float) -> void:
	var current_hp: float = get_meta("hp", 0.0) - amount
	set_meta("hp", current_hp)
	set_meta("flash", 0.1)
	if current_hp <= 0:
		var game := get_parent().get_parent()
		if game.has_method("_on_enemy_died_3d"):
			game._on_enemy_died_3d(position, get_meta("xp_value", 1))
		queue_free()
