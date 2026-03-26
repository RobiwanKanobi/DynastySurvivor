extends Node3D

signal health_changed(current_hp: float, max_hp: float)
signal xp_changed(current_xp: int, needed_xp: int)
signal leveled_up(new_level: int)
signal player_died

const BASE_SPEED := 20.0
const INV_DURATION := 0.8

var max_hp := 100.0
var hp := 100.0
var xp := 0
var level := 1
var xp_to_next := 5
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

var game_node: Node = null


func _ready() -> void:
	add_to_group("player")
	add_weapon("knife")


func add_weapon(wname: String) -> void:
	var w: Dictionary
	match wname:
		"knife":
			w = {"id": "knife", "name": "Knife", "type": "projectile",
				"damage": 10.0, "cooldown": 1.0, "speed": 40.0, "pierce": 1,
				"count": 1, "size": 1.0, "color": Color(1, 0.9, 0.2)}
		"holy_aura":
			w = {"id": "holy_aura", "name": "Holy Aura", "type": "aura",
				"damage": 8.0, "cooldown": 1.2, "radius": 10.0,
				"color": Color(0.4, 0.8, 1.0, 0.3)}
		"magic_orb":
			w = {"id": "magic_orb", "name": "Magic Orb", "type": "projectile",
				"damage": 20.0, "cooldown": 2.5, "speed": 15.0, "pierce": 99,
				"count": 1, "size": 1.8, "color": Color(0.7, 0.3, 1.0)}
	weapons.append(w)
	weapon_timers.append(0.0)


func has_weapon(weapon_id: String) -> bool:
	for w in weapons:
		if w["id"] == weapon_id:
			return true
	return false


func take_damage(amount: float) -> void:
	if invincible:
		return
	hp = max(hp - amount, 0.0)
	invincible = true
	inv_timer = INV_DURATION
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
