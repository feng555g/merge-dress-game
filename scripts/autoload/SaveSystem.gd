# scripts/autoload/SaveSystem.gd
extends Node

const SAVE_PATH = "user://savegame.json"

func save() -> void:
	var data = {
		"current_chapter": GameState.current_chapter,
		"chapter_progress": GameState.chapter_progress,
		"inventory": GameState.inventory,
		"outfit": GameState.outfit,
		"rooms": _serialize_rooms(GameState.rooms)
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: cannot write save file")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text = file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if data == null:
		return false
	GameState.current_chapter = data.get("current_chapter", 1)
	GameState.chapter_progress = data.get("chapter_progress", {})
	GameState.inventory = data.get("inventory", {})
	GameState.outfit = data.get("outfit", GameState.outfit)
	GameState.rooms = _deserialize_rooms(data.get("rooms", {}))
	return true

func _serialize_rooms(rooms: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for room_id in rooms:
		result[room_id] = []
		for entry in rooms[room_id]:
			result[room_id].append({
				"furniture_id": entry["furniture_id"],
				"pos_x": entry["pos"].x,
				"pos_y": entry["pos"].y
			})
	return result

func _deserialize_rooms(data: Dictionary) -> Dictionary:
	var result: Dictionary = {
		"living_room": [],
		"bedroom": [],
		"kitchen": [],
		"garden": []
	}
	for room_id in data:
		result[room_id] = []
		for entry in data[room_id]:
			result[room_id].append({
				"furniture_id": entry["furniture_id"],
				"pos": Vector2(entry["pos_x"], entry["pos_y"])
			})
	return result
