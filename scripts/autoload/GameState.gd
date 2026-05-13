# scripts/autoload/GameState.gd
extends Node

# 章节进度
var current_chapter: int = 1
var chapter_progress: Dictionary = {}  # chapter_id -> { "levels_completed": [], "goals_done": [] }

# 背包：item_id -> count
var inventory: Dictionary = {}

# 装扮状态：slot -> item_id (""表示未装备)
var outfit: Dictionary = {
	"top": "",
	"bottom": "",
	"shoes": "",
	"accessory": "",
	"hair": ""
}

# 房间状态：room_id -> [ { "furniture_id": str, "pos": Vector2 } ]
var rooms: Dictionary = {
	"living_room": [],
	"bedroom": [],
	"kitchen": [],
	"garden": []
}

func add_item(item_id: String, count: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + count

func remove_item(item_id: String, count: int = 1) -> bool:
	var current = inventory.get(item_id, 0)
	if current < count:
		return false
	inventory[item_id] = current - count
	if inventory[item_id] == 0:
		inventory.erase(item_id)
	return true

func has_item(item_id: String, count: int = 1) -> bool:
	return inventory.get(item_id, 0) >= count

func equip(slot: String, item_id: String) -> void:
	if slot in outfit:
		outfit[slot] = item_id

func place_furniture(room_id: String, furniture_id: String, pos: Vector2) -> void:
	if room_id in rooms:
		rooms[room_id].append({"furniture_id": furniture_id, "pos": pos})

func mark_level_complete(chapter: int, level: int) -> void:
	var key = str(chapter)
	if not chapter_progress.has(key):
		chapter_progress[key] = {"levels_completed": [], "goals_done": []}
	var level_key = str(chapter) + "_" + str(level)
	if not level_key in chapter_progress[key]["levels_completed"]:
		chapter_progress[key]["levels_completed"].append(level_key)

func mark_goal_done(chapter: int, goal_id: String) -> void:
	var key = str(chapter)
	if not chapter_progress.has(key):
		chapter_progress[key] = {"levels_completed": [], "goals_done": []}
	if not goal_id in chapter_progress[key]["goals_done"]:
		chapter_progress[key]["goals_done"].append(goal_id)

func is_chapter_unlocked(chapter: int) -> bool:
	if chapter == 1:
		return true
	return chapter_progress.has(str(chapter - 1)) and \
		chapter_progress[str(chapter - 1)].get("chapter_complete", false)

func complete_chapter(chapter: int) -> void:
	var key = str(chapter)
	if not chapter_progress.has(key):
		chapter_progress[key] = {"levels_completed": [], "goals_done": []}
	chapter_progress[key]["chapter_complete"] = true
