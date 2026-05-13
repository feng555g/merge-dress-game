# scripts/autoload/DataLoader.gd
extends Node

var _cache: Dictionary = {}

func load_json(path: String) -> Variant:
	if _cache.has(path):
		return _cache[path]
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DataLoader: cannot open " + path)
		return null
	var text = file.get_as_text()
	file.close()
	var result = JSON.parse_string(text)
	if result == null:
		push_error("DataLoader: invalid JSON at " + path)
		return null
	_cache[path] = result
	return result

func get_items() -> Dictionary:
	var data = load_json("res://data/items/items.json")
	if data == null:
		return {}
	var result: Dictionary = {}
	for item in data:
		result[item["id"]] = item
	return result

func get_item(item_id: String) -> Dictionary:
	var items = get_items()
	return items.get(item_id, {})

func get_recipes() -> Array:
	var data = load_json("res://data/recipes/recipes.json")
	return data if data != null else []

func get_level(chapter: int, level: int) -> Dictionary:
	var path = "res://data/levels/chapter%d/level_%d_%d.json" % [chapter, chapter, level]
	var data = load_json(path)
	return data if data != null else {}

func get_chapters() -> Array:
	var data = load_json("res://data/chapters/chapters.json")
	return data if data != null else []

func get_story(chapter: int) -> Array:
	var path = "res://data/story/chapter%d_story.json" % chapter
	var data = load_json(path)
	return data if data != null else []
