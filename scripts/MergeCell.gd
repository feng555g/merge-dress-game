# scripts/MergeCell.gd
# 棋盘格子节点
extends Node2D

var grid_pos: Vector2i = Vector2i.ZERO
var occupied_item: Node2D = null  # 当前格子上的物品

@onready var bg: ColorRect = $ColorRect
@onready var highlight: ColorRect = $Highlight

const CELL_SIZE = 80

func setup(pos: Vector2i) -> void:
	grid_pos = pos
	if highlight:
		highlight.visible = false

func is_empty() -> bool:
	return occupied_item == null

func set_item(item: Node2D) -> void:
	occupied_item = item

func clear_item() -> void:
	occupied_item = null

func show_highlight(can_merge: bool) -> void:
	if highlight:
		highlight.visible = true
		highlight.color = Color(0, 1, 0, 0.3) if can_merge else Color(1, 0, 0, 0.2)

func hide_highlight() -> void:
	if highlight:
		highlight.visible = false
