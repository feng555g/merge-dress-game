# scripts/MainMenu.gd
extends Node2D

@onready var chapter_list: VBoxContainer = $UILayer/ScrollContainer/ChapterList
@onready var workshop_button: Button = $UILayer/BottomBar/WorkshopButton
@onready var dressup_button: Button = $UILayer/BottomBar/DressUpButton
@onready var room_button: Button = $UILayer/BottomBar/RoomButton
@onready var title_label: Label = $UILayer/TitleLabel
@onready var inventory_label: Label = $UILayer/InventoryLabel

func _ready() -> void:
	workshop_button.pressed.connect(_on_workshop_pressed)
	dressup_button.pressed.connect(_on_dressup_pressed)
	room_button.pressed.connect(_on_room_pressed)
	_refresh()

func _refresh() -> void:
	title_label.text = "第 %d 章进行中" % GameState.current_chapter
	# 显示背包物品数量
	var total = 0
	for count in GameState.inventory.values():
		total += count
	inventory_label.text = "背包：%d 件物品" % total
	_build_chapter_list()

func _build_chapter_list() -> void:
	for child in chapter_list.get_children():
		child.queue_free()
	var chapters = DataLoader.get_chapters()
	for chapter in chapters:
		var chapter_id = chapter["id"]
		var unlocked = GameState.is_chapter_unlocked(chapter_id)
		var section = VBoxContainer.new()
		chapter_list.add_child(section)
		# 章节标题
		var title = Label.new()
		title.text = ("✓ " if GameState.chapter_progress.get(str(chapter_id), {}).get("chapter_complete", false) else "") + \
			"第%d章：%s" % [chapter_id, chapter.get("name", "")]
		title.modulate = Color.WHITE if unlocked else Color(0.5, 0.5, 0.5)
		section.add_child(title)
		if not unlocked:
			var lock_label = Label.new()
			lock_label.text = "  🔒 完成上一章解锁"
			lock_label.add_theme_font_size_override("font_size", 12)
			section.add_child(lock_label)
			continue
		# 关卡按钮
		var levels = chapter.get("levels", [])
		var level_row = HBoxContainer.new()
		section.add_child(level_row)
		for level_key in levels:
			var parts = level_key.split("_")
			var level_num = int(parts[1]) if parts.size() > 1 else 1
			var btn = Button.new()
			var completed = level_key in GameState.chapter_progress.get(str(chapter_id), {}).get("levels_completed", [])
			btn.text = ("★" if completed else "○") + " 关卡%s" % level_key
			btn.pressed.connect(_on_level_pressed.bind(chapter_id, level_num))
			level_row.add_child(btn)
		# 章节目标进度
		var goals_done = GameState.chapter_progress.get(str(chapter_id), {}).get("goals_done", [])
		var goals = chapter.get("goals", [])
		var goal_label = Label.new()
		goal_label.text = "  养成目标：%d/%d 完成" % [goals_done.size(), goals.size()]
		goal_label.add_theme_font_size_override("font_size", 12)
		section.add_child(goal_label)
		# 如果所有目标完成且章节未完成，显示触发故事按钮
		if goals_done.size() >= goals.size() and \
			not GameState.chapter_progress.get(str(chapter_id), {}).get("chapter_complete", false):
			var story_btn = Button.new()
			story_btn.text = "▶ 观看故事"
			story_btn.pressed.connect(_on_story_pressed.bind(chapter_id))
			section.add_child(story_btn)
		# 分隔线
		var sep = HSeparator.new()
		chapter_list.add_child(sep)

func _on_level_pressed(chapter: int, level: int) -> void:
	# 加载棋盘关卡
	var scene = load("res://scenes/MergeBoard/MergeBoard.tscn").instantiate()
	get_tree().root.add_child(scene)
	scene.load_level(chapter, level)
	scene.level_complete.connect(_on_level_complete.bind(chapter, level, scene))
	scene.level_failed.connect(_on_level_failed.bind(scene))
	hide()

func _on_level_complete(stars: int, drops: Array, chapter: int, level: int, scene: Node) -> void:
	GameState.mark_level_complete(chapter, level)
	for drop in drops:
		GameState.add_item(drop["item_id"], drop.get("count", 1))
	SaveSystem.save()
	scene.queue_free()
	show()
	_refresh()

func _on_level_failed(scene: Node) -> void:
	scene.queue_free()
	show()

func _on_story_pressed(chapter: int) -> void:
	var scene = load("res://scenes/Story/Story.tscn").instantiate()
	get_tree().root.add_child(scene)
	scene.load_chapter_story(chapter)
	hide()

func _on_workshop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Workshop/Workshop.tscn")

func _on_dressup_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/DressUp/DressUp.tscn")

func _on_room_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Room/Room.tscn")
