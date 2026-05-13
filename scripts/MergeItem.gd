# scripts/MergeItem.gd
# 棋盘上的单个物品节点
extends Node2D

signal drag_started(item)
signal drag_ended(item, target_pos)

var item_id: String = ""
var item_data: Dictionary = {}
var cell_pos: Vector2i = Vector2i.ZERO  # 当前所在格子坐标
var is_dragging: bool = false

var _drag_offset: Vector2 = Vector2.ZERO
var _original_pos: Vector2 = Vector2.ZERO

@onready var sprite: ColorRect = $ColorRect
@onready var label: Label = $Label

func setup(id: String, data: Dictionary, grid_pos: Vector2i) -> void:
	item_id = id
	item_data = data
	cell_pos = grid_pos
	if sprite:
		var color = Color(data.get("color", "#FFFFFF"))
		sprite.color = color
	if label:
		label.text = data.get("name", id)

func _input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed = event.pressed if event is InputEventMouseButton else event.pressed
		if pressed:
			_start_drag(event.position)
		else:
			_end_drag(event.position)
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if is_dragging:
			global_position = event.position + _drag_offset

func _start_drag(pos: Vector2) -> void:
	is_dragging = true
	_original_pos = global_position
	_drag_offset = global_position - pos
	z_index = 10
	emit_signal("drag_started", self)

func _end_drag(pos: Vector2) -> void:
	is_dragging = false
	z_index = 0
	emit_signal("drag_ended", self, pos)
