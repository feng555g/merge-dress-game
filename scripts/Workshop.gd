# scripts/Workshop.gd
extends Node2D

signal item_crafted(item_id: String)

var _all_recipes: Array = []
var _current_chapter: int = 1

@onready var recipe_list: VBoxContainer = $UILayer/ScrollContainer/RecipeList
@onready var craft_button: Button = $UILayer/CraftPanel/CraftButton
@onready var selected_label: Label = $UILayer/CraftPanel/SelectedLabel
@onready var result_label: Label = $UILayer/CraftPanel/ResultLabel
@onready var back_button: Button = $UILayer/TopBar/BackButton

var _selected_recipe: Dictionary = {}

func _ready() -> void:
	craft_button.pressed.connect(_on_craft_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_load_recipes()

func _load_recipes() -> void:
	_current_chapter = GameState.current_chapter
	_all_recipes = DataLoader.get_recipes()
	_refresh_list()

func _refresh_list() -> void:
	for child in recipe_list.get_children():
		child.queue_free()
	_selected_recipe = {}
	craft_button.disabled = true
	selected_label.text = "选择一个配方"
	result_label.text = ""

	for recipe in _all_recipes:
		if recipe.get("chapter", 1) > _current_chapter:
			continue
		var btn = Button.new()
		var can_craft = _can_craft(recipe)
		var result_item = DataLoader.get_item(recipe.get("result", ""))
		var name_text = recipe.get("name", recipe.get("id", ""))
		btn.text = ("[✓] " if can_craft else "[✗] ") + name_text
		btn.modulate = Color.WHITE if can_craft else Color(0.6, 0.6, 0.6)
		btn.pressed.connect(_on_recipe_selected.bind(recipe))
		recipe_list.add_child(btn)

func _can_craft(recipe: Dictionary) -> bool:
	for ing in recipe.get("ingredients", []):
		if not GameState.has_item(ing["item_id"], ing["count"]):
			return false
	return true

func _on_recipe_selected(recipe: Dictionary) -> void:
	_selected_recipe = recipe
	var result_item = DataLoader.get_item(recipe.get("result", ""))
	selected_label.text = recipe.get("name", "")
	var ing_text = "需要材料：\n"
	for ing in recipe.get("ingredients", []):
		var item = DataLoader.get_item(ing["item_id"])
		var have = GameState.inventory.get(ing["item_id"], 0)
		ing_text += "  %s x%d (拥有:%d)\n" % [item.get("name", ing["item_id"]), ing["count"], have]
	result_label.text = ing_text + "\n产出：" + result_item.get("name", recipe.get("result", ""))
	craft_button.disabled = not _can_craft(recipe)

func _on_craft_pressed() -> void:
	if _selected_recipe.is_empty():
		return
	if not _can_craft(_selected_recipe):
		return
	# 消耗材料
	for ing in _selected_recipe.get("ingredients", []):
		GameState.remove_item(ing["item_id"], ing["count"])
	# 产出物品
	var result_id = _selected_recipe.get("result", "")
	GameState.add_item(result_id)
	SaveSystem.save()
	emit_signal("item_crafted", result_id)
	# 检查章节目标
	_check_chapter_goals(result_id)
	_refresh_list()

func _check_chapter_goals(item_id: String) -> void:
	var chapters = DataLoader.get_chapters()
	for chapter in chapters:
		if chapter["id"] != GameState.current_chapter:
			continue
		for goal in chapter.get("goals", []):
			if goal["type"] == "craft" and goal.get("item_id") == item_id:
				GameState.mark_goal_done(GameState.current_chapter, goal["id"])

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu/MainMenu.tscn")
