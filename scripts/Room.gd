# scripts/Room.gd
extends Node2D

const ROOMS = ["living_room", "bedroom", "kitchen", "garden"]
const ROOM_NAMES = {"living_room": "客厅", "bedroom": "卧室", "kitchen": "厨房", "garden": "庭院"}

var _current_room: String = "living_room"
var _placed_items: Array = []  # 当前房间已放置的家具节点
var _dragging_furniture: Node2D = null
var _drag_offset: Vector2 = Vector2.ZERO

@onready var room_display: Node2D = $RoomDisplay
@onready var furniture_list: VBoxContainer = $UILayer/FurniturePanel/ScrollContainer/FurnitureList
@onready var place_button: Button = $UILayer/FurniturePanel/PlaceButton
@onready var back_button: Button = $UILayer/TopBar/BackButton
@onready var room_tabs: HBoxContainer = $UILayer/RoomTabs
@onready var room_bg: ColorRect = $RoomDisplay/RoomBackground

var _selected_furniture_id: String = ""
var _room_colors = {
	"living_room": Color(0.95, 0.90, 0.80),
	"bedroom": Color(0.85, 0.90, 0.95),
	"kitchen": Color(0.95, 0.95, 0.85),
	"garden": Color(0.85, 0.95, 0.85)
}

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	place_button.pressed.connect(_on_place_pressed)
	_build_room_tabs()
	_switch_room("living_room")

func _build_room_tabs() -> void:
	for room_id in ROOMS:
		var btn = Button.new()
		btn.text = ROOM_NAMES[room_id]
		btn.pressed.connect(_switch_room.bind(room_id))
		room_tabs.add_child(btn)

func _switch_room(room_id: String) -> void:
	_current_room = room_id
	_selected_furniture_id = ""
	place_button.disabled = true
	room_bg.color = _room_colors.get(room_id, Color.WHITE)
	_refresh_placed_furniture()
	_refresh_furniture_list()

func _refresh_placed_furniture() -> void:
	# 清除旧节点
	for node in _placed_items:
		node.queue_free()
	_placed_items.clear()
	# 重新放置
	var room_data = GameState.rooms.get(_current_room, [])
	for entry in room_data:
		_create_furniture_node(entry["furniture_id"], entry["pos"])

func _create_furniture_node(furniture_id: String, pos: Vector2) -> Node2D:
	var item_data = DataLoader.get_item(furniture_id)
	var node = Node2D.new()
	room_display.add_child(node)
	var rect = ColorRect.new()
	rect.size = Vector2(60, 60)
	rect.position = Vector2(-30, -30)
	rect.color = Color(item_data.get("color", "#888888"))
	node.add_child(rect)
	var lbl = Label.new()
	lbl.text = item_data.get("name", furniture_id)
	lbl.position = Vector2(-30, 35)
	lbl.add_theme_font_size_override("font_size", 10)
	node.add_child(lbl)
	node.position = pos
	node.set_meta("furniture_id", furniture_id)
	_placed_items.append(node)
	return node

func _refresh_furniture_list() -> void:
	for child in furniture_list.get_children():
		child.queue_free()
	var all_items = DataLoader.get_items()
	for item_id in GameState.inventory:
		var item = all_items.get(item_id, {})
		if item.get("type") == "furniture" and item.get("room") == _current_room:
			var btn = Button.new()
			btn.text = item.get("name", item_id)
			btn.pressed.connect(_on_furniture_selected.bind(item_id))
			furniture_list.add_child(btn)

func _on_furniture_selected(furniture_id: String) -> void:
	_selected_furniture_id = furniture_id
	place_button.disabled = false

func _on_place_pressed() -> void:
	if _selected_furniture_id.is_empty():
		return
	var pos = Vector2(100 + randf() * 200, 100 + randf() * 150)
	GameState.place_furniture(_current_room, _selected_furniture_id, pos)
	GameState.remove_item(_selected_furniture_id)
	# 检查章节目标
	_check_place_goals(_selected_furniture_id)
	SaveSystem.save()
	_refresh_placed_furniture()
	_refresh_furniture_list()
	_selected_furniture_id = ""
	place_button.disabled = true

func _check_place_goals(furniture_id: String) -> void:
	var chapters = DataLoader.get_chapters()
	for chapter in chapters:
		if chapter["id"] != GameState.current_chapter:
			continue
		for goal in chapter.get("goals", []):
			if goal["type"] == "place_furniture" and goal.get("item_id") == furniture_id:
				GameState.mark_goal_done(GameState.current_chapter, goal["id"])

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		var pressed = event.pressed
		var pos = event.position
		if pressed:
			_try_start_drag(pos)
		else:
			_end_drag()
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and _dragging_furniture:
		_dragging_furniture.global_position = event.position + _drag_offset
		_update_furniture_pos_in_state()

func _try_start_drag(pos: Vector2) -> void:
	for node in _placed_items:
		if node.global_position.distance_to(pos) < 40:
			_dragging_furniture = node
			_drag_offset = node.global_position - pos
			return

func _end_drag() -> void:
	if _dragging_furniture:
		_update_furniture_pos_in_state()
		SaveSystem.save()
		_dragging_furniture = null

func _update_furniture_pos_in_state() -> void:
	if not _dragging_furniture:
		return
	var furniture_id = _dragging_furniture.get_meta("furniture_id", "")
	var room_data = GameState.rooms.get(_current_room, [])
	for entry in room_data:
		if entry["furniture_id"] == furniture_id:
			entry["pos"] = _dragging_furniture.position
			break

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu/MainMenu.tscn")
