# scripts/DressUp.gd
extends Node2D

const SLOTS = ["top", "bottom", "shoes", "accessory", "hair"]
const SLOT_NAMES = {"top": "上衣", "bottom": "下装", "shoes": "鞋子", "accessory": "配饰", "hair": "发型"}

var _selected_slot: String = ""
var _outfit_items: Dictionary = {}  # slot -> [item_id, ...]

@onready var character_display: ColorRect = $UILayer/CharacterPanel/CharacterDisplay
@onready var slot_buttons: Dictionary = {}
@onready var wardrobe_list: VBoxContainer = $UILayer/WardrobePanel/ScrollContainer/WardrobeList
@onready var equip_button: Button = $UILayer/WardrobePanel/EquipButton
@onready var unequip_button: Button = $UILayer/WardrobePanel/UnequipButton
@onready var back_button: Button = $UILayer/TopBar/BackButton
@onready var slot_container: HBoxContainer = $UILayer/SlotPanel/SlotContainer

var _selected_wardrobe_item: String = ""

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	equip_button.pressed.connect(_on_equip_pressed)
	unequip_button.pressed.connect(_on_unequip_pressed)
	_build_slot_buttons()
	_refresh_display()

func _build_slot_buttons() -> void:
	for slot in SLOTS:
		var btn = Button.new()
		btn.text = SLOT_NAMES[slot]
		btn.pressed.connect(_on_slot_selected.bind(slot))
		slot_container.add_child(btn)
		slot_buttons[slot] = btn

func _refresh_display() -> void:
	# 更新角色显示颜色（根据当前装扮）
	var top_id = GameState.outfit.get("top", "")
	if not top_id.is_empty():
		var item = DataLoader.get_item(top_id)
		character_display.color = Color(item.get("color", "#AAAAAA"))
	else:
		character_display.color = Color(0.6, 0.6, 0.6)
	# 更新槽位按钮文字
	for slot in SLOTS:
		var equipped = GameState.outfit.get(slot, "")
		if not equipped.is_empty():
			var item = DataLoader.get_item(equipped)
			slot_buttons[slot].text = SLOT_NAMES[slot] + "\n" + item.get("name", equipped)
		else:
			slot_buttons[slot].text = SLOT_NAMES[slot] + "\n(空)"

func _on_slot_selected(slot: String) -> void:
	_selected_slot = slot
	_selected_wardrobe_item = ""
	equip_button.disabled = true
	_refresh_wardrobe_list()

func _refresh_wardrobe_list() -> void:
	for child in wardrobe_list.get_children():
		child.queue_free()
	if _selected_slot.is_empty():
		return
	# 列出背包中该槽位的所有服装
	var all_items = DataLoader.get_items()
	for item_id in GameState.inventory:
		var item = all_items.get(item_id, {})
		if item.get("type") == "outfit" and item.get("slot") == _selected_slot:
			var btn = Button.new()
			var equipped = GameState.outfit.get(_selected_slot, "")
			btn.text = ("★ " if equipped == item_id else "  ") + item.get("name", item_id)
			btn.pressed.connect(_on_wardrobe_item_selected.bind(item_id))
			wardrobe_list.add_child(btn)

func _on_wardrobe_item_selected(item_id: String) -> void:
	_selected_wardrobe_item = item_id
	equip_button.disabled = false

func _on_equip_pressed() -> void:
	if _selected_slot.is_empty() or _selected_wardrobe_item.is_empty():
		return
	GameState.equip(_selected_slot, _selected_wardrobe_item)
	# 检查章节目标
	_check_equip_goals(_selected_wardrobe_item)
	SaveSystem.save()
	_refresh_display()
	_refresh_wardrobe_list()

func _check_equip_goals(item_id: String) -> void:
	var chapters = DataLoader.get_chapters()
	for chapter in chapters:
		if chapter["id"] != GameState.current_chapter:
			continue
		for goal in chapter.get("goals", []):
			if goal["type"] == "equip" and goal.get("item_id") == item_id:
				GameState.mark_goal_done(GameState.current_chapter, goal["id"])

func _on_unequip_pressed() -> void:
	if _selected_slot.is_empty():
		return
	GameState.equip(_selected_slot, "")
	SaveSystem.save()
	_refresh_display()
	_refresh_wardrobe_list()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu/MainMenu.tscn")
