extends Control

var hp_bar: ColorRect
var hp_bar_bg: ColorRect
var xp_bar: ColorRect
var xp_bar_bg: ColorRect
var time_label: Label
var kills_label: Label
var level_label: Label

const BAR_WIDTH := 250.0
const BAR_HEIGHT := 18.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar_bg = _make_rect(Vector2(20, 16), Vector2(BAR_WIDTH, BAR_HEIGHT),
		Color(0.3, 0.0, 0.0, 0.8))
	hp_bar = _make_rect(Vector2(20, 16), Vector2(BAR_WIDTH, BAR_HEIGHT),
		Color(0.8, 0.15, 0.15))
	xp_bar_bg = _make_rect(Vector2(20, 40), Vector2(BAR_WIDTH, 10),
		Color(0.0, 0.0, 0.3, 0.8))
	xp_bar = _make_rect(Vector2(20, 40), Vector2(0, 10),
		Color(0.2, 0.5, 1.0))

	var hp_label := _make_label(Vector2(24, 16), "HP")
	hp_label.add_theme_font_size_override("font_size", 13)

	time_label = _make_label(Vector2(0, 12), "0:00")
	time_label.add_theme_font_size_override("font_size", 22)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.anchor_left = 0.5
	time_label.anchor_right = 0.5
	time_label.offset_left = -50
	time_label.offset_right = 50

	kills_label = _make_label(Vector2(20, 58), "Kills: 0")
	kills_label.add_theme_font_size_override("font_size", 14)
	level_label = _make_label(Vector2(20, 76), "Level: 1")
	level_label.add_theme_font_size_override("font_size", 14)


func _make_rect(pos: Vector2, sz: Vector2, clr: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = sz
	r.color = clr
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _make_label(pos: Vector2, txt: String) -> Label:
	var l := Label.new()
	l.position = pos
	l.text = txt
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func update_health(current: float, maximum: float) -> void:
	hp_bar.size.x = BAR_WIDTH * clampf(current / maximum, 0.0, 1.0)


func update_xp(current: int, needed: int) -> void:
	if needed > 0:
		xp_bar.size.x = BAR_WIDTH * clampf(float(current) / float(needed), 0.0, 1.0)
	else:
		xp_bar.size.x = 0.0


func update_time(t: float) -> void:
	var mins := int(t) / 60
	var secs := int(t) % 60
	time_label.text = "%d:%02d" % [mins, secs]


func update_kills(k: int) -> void:
	kills_label.text = "Kills: %d" % k


func update_level(l: int) -> void:
	level_label.text = "Level: %d" % l
