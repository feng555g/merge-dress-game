# scripts/MergeBoard.gd
extends Node2D

signal level_complete(stars: int, drops: Array)
signal level_failed

const COLS = 6
const ROWS = 8
const CELL_SIZE = 80

var level_data: Dictionary = {}
var cells: Array = []  # 2D array [col][row] of MergeCell
var goals: Dictionary = {}       # item_id -> required count
var collected: Dictionary = {}   # item_id -> collected count
var moves_left: int = 0

@onready var cells_container: Node2D = $CellsContainer
@onready var items_container: Node2D = $ItemsContainer
@onready var ui_layer: CanvasLayer = $UILayer
@onready var goal_label: Label = $UILayer/GoalPanel/GoalLabel
@onready var moves_label: Label = $UILayer/TopBar/MovesLabel
@onready var complete_panel: Panel = $UILayer/CompletePanel
@onready var stars_label: Label = $UILayer/CompletePanel/StarsLabel

var _MergeCell = preload("res://scenes/MergeBoard/MergeCell.tscn")
var _MergeItem = preload("res://scenes/MergeBoard/MergeItem.tscn")

func _ready() -> void:
	complete_panel.visible = false
	_build_grid()

func load_level(chapter: int, level: int) -> void:
	level_data = DataLoader.get_level(chapter, level)
	if level_data.is_empty():
		push_error("MergeBoard: level data not found %d_%d" % [chapter, level])
		return
	moves_left = level_data.get("moves", 30)
	goals = {}
	collected = {}
	for goal in level_data.get("goals", []):
		goals[goal["item_id"]] = goal["count"]
		collected[goal["item_id"]] = 0
	_populate_board()
	_update_ui()

func _build_grid() -> void:
	cells.resize(COLS)
	for c in range(COLS):
		cells[c] = []
		cells[c].resize(ROWS)
		for r in range(ROWS):
			var cell = _MergeCell.instantiate()
			cells_container.add_child(cell)
			cell.position = Vector2(c * CELL_SIZE, r * CELL_SIZE)
			cell.setup(Vector2i(c, r))
			cells[c][r] = cell

func _populate_board() -> void:
	# 清空现有物品
	for child in items_container.get_children():
		child.queue_free()
	for c in range(COLS):
		for r in range(ROWS):
			cells[c][r].clear_item()
	# 按关卡数据放置初始物品
	var initial_items = level_data.get("initial_items", [])
	for entry in initial_items:
		var col = entry.get("col", 0)
		var row = entry.get("row", 0)
		var item_id = entry.get("item_id", "")
		if col < COLS and row < ROWS and not item_id.is_empty():
			_spawn_item(item_id, Vector2i(col, row))

func _spawn_item(item_id: String, grid_pos: Vector2i) -> Node2D:
	var item_data = DataLoader.get_item(item_id)
	if item_data.is_empty():
		return null
	var item = _MergeItem.instantiate()
	items_container.add_child(item)
	item.position = _grid_to_world(grid_pos)
	item.setup(item_id, item_data, grid_pos)
	item.drag_started.connect(_on_item_drag_started)
	item.drag_ended.connect(_on_item_drag_ended)
	cells[grid_pos.x][grid_pos.y].set_item(item)
	return item

func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * CELL_SIZE + CELL_SIZE / 2, grid_pos.y * CELL_SIZE + CELL_SIZE / 2)

func _world_to_grid(world_pos: Vector2) -> Vector2i:
	var local = world_pos - cells_container.global_position
	return Vector2i(int(local.x / CELL_SIZE), int(local.y / CELL_SIZE))

func _is_valid_grid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < COLS and pos.y >= 0 and pos.y < ROWS

func _on_item_drag_started(_item: Node2D) -> void:
	pass

func _on_item_drag_ended(item: Node2D, world_pos: Vector2) -> void:
	var target_grid = _world_to_grid(world_pos)
	if not _is_valid_grid(target_grid):
		# 放回原位
		item.position = _grid_to_world(item.cell_pos)
		return
	var source_grid = item.cell_pos
	if target_grid == source_grid:
		item.position = _grid_to_world(source_grid)
		return
	var target_cell = cells[target_grid.x][target_grid.y]
	if target_cell.is_empty():
		# 移动到空格
		cells[source_grid.x][source_grid.y].clear_item()
		target_cell.set_item(item)
		item.cell_pos = target_grid
		item.position = _grid_to_world(target_grid)
		_use_move()
	else:
		var target_item = target_cell.occupied_item
		if target_item.item_id == item.item_id:
			# 合并
			_merge_items(item, target_item, target_grid, source_grid)
		else:
			# 交换
			cells[source_grid.x][source_grid.y].set_item(target_item)
			target_cell.set_item(item)
			target_item.cell_pos = source_grid
			target_item.position = _grid_to_world(source_grid)
			item.cell_pos = target_grid
			item.position = _grid_to_world(target_grid)
			_use_move()

func _merge_items(dragged: Node2D, target: Node2D, target_grid: Vector2i, source_grid: Vector2i) -> void:
	var item_data = DataLoader.get_item(dragged.item_id)
	var merge_into = item_data.get("merge_into", null)
	# 移除两个物品
	cells[source_grid.x][source_grid.y].clear_item()
	cells[target_grid.x][target_grid.y].clear_item()
	dragged.queue_free()
	target.queue_free()
	if merge_into != null:
		# 生成合并结果
		_spawn_item(merge_into, target_grid)
	else:
		# 最高级物品，产出材料
		var drops = item_data.get("drops", [])
		for drop_id in drops:
			GameState.add_item(drop_id)
			_collect_goal_item(drop_id)
	_use_move()

func _collect_goal_item(item_id: String) -> void:
	if item_id in collected:
		collected[item_id] += 1
		_update_ui()
		_check_win()

func _use_move() -> void:
	moves_left -= 1
	_update_ui()
	if moves_left <= 0:
		_check_win()
		if not _is_goals_complete():
			emit_signal("level_failed")

func _is_goals_complete() -> bool:
	for item_id in goals:
		if collected.get(item_id, 0) < goals[item_id]:
			return false
	return true

func _check_win() -> void:
	if _is_goals_complete():
		var stars = _calculate_stars()
		var drops = _calculate_drops(stars)
		for drop in drops:
			GameState.add_item(drop["item_id"], drop["count"])
		complete_panel.visible = true
		stars_label.text = "★" * stars + "☆" * (3 - stars)
		emit_signal("level_complete", stars, drops)

func _calculate_stars() -> int:
	var ratio = float(moves_left) / float(level_data.get("moves", 30))
	if ratio > 0.5:
		return 3
	elif ratio > 0.2:
		return 2
	else:
		return 1

func _calculate_drops(stars: int) -> Array:
	var all_drops = level_data.get("drops", [])
	var result = []
	for drop in all_drops:
		if drop.get("min_stars", 1) <= stars:
			result.append(drop)
	return result

func _update_ui() -> void:
	if moves_label:
		moves_label.text = "步数: %d" % moves_left
	if goal_label:
		var goal_text = "目标:\n"
		for item_id in goals:
			var item_data = DataLoader.get_item(item_id)
			var name = item_data.get("name", item_id)
			goal_text += "%s: %d/%d\n" % [name, collected.get(item_id, 0), goals[item_id]]
		goal_label.text = goal_text
