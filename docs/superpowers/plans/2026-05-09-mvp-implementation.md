# 合成养成游戏 MVP 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用 Godot 4 + GDScript 构建一款合成养成手机游戏的完整 MVP，包含前 3 章内容和六大核心系统。

**Architecture:** 数据驱动设计——关卡、配方、故事全部外置为 JSON 文件，代码只处理逻辑；六大系统（棋盘、配方、装扮、装修、故事、存档）各自独立场景+脚本，通过 Autoload 单例共享状态；主场景负责场景切换。

**Tech Stack:** Godot 4.x, GDScript, JSON 数据文件, Godot FileAccess 存档

---

## 文件结构总览

```
res://
├── project.godot
├── scenes/
│   ├── Main.tscn                  # 根场景，场景切换控制器
│   ├── MainMenu/
│   │   └── MainMenu.tscn          # 主菜单 + 章节选择
│   ├── MergeBoard/
│   │   ├── MergeBoard.tscn        # 棋盘关卡场景
│   │   ├── MergeCell.tscn         # 单个格子组件
│   │   └── MergeItem.tscn         # 棋盘物品组件
│   ├── Workshop/
│   │   └── Workshop.tscn          # 配方合成界面
│   ├── DressUp/
│   │   └── DressUp.tscn           # 装扮界面
│   ├── Room/
│   │   └── Room.tscn              # 房间装修界面
│   └── Story/
│       └── Story.tscn             # 剧情对话场景
├── scripts/
│   ├── autoload/
│   │   ├── GameState.gd           # 全局状态单例（章节进度、背包、装扮、房间）
│   │   ├── DataLoader.gd          # JSON 数据加载单例
│   │   └── SaveSystem.gd          # 存档读写单例
│   ├── MergeBoard.gd
│   ├── MergeCell.gd
│   ├── MergeItem.gd
│   ├── Workshop.gd
│   ├── DressUp.gd
│   ├── Room.gd
│   ├── Story.gd
│   └── MainMenu.gd
├── data/
│   ├── items/
│   │   └── items.json             # 所有棋盘物品定义
│   ├── levels/
│   │   ├── chapter1/
│   │   │   ├── level_1_1.json
│   │   │   ├── level_1_2.json
│   │   │   └── level_1_3.json
│   │   ├── chapter2/
│   │   │   ├── level_2_1.json
│   │   │   └── level_2_2.json
│   │   └── chapter3/
│   │       └── level_3_1.json
│   ├── recipes/
│   │   └── recipes.json           # 所有配方定义
│   ├── chapters/
│   │   └── chapters.json          # 章节解锁条件定义
│   └── story/
│       ├── chapter1_story.json
│       ├── chapter2_story.json
│       └── chapter3_story.json
└── assets/
    ├── items/                     # 棋盘物品图标（占位色块）
    ├── characters/                # 女主立绘（占位色块）
    ├── furniture/                 # 家具贴图（占位色块）
    └── ui/                        # UI 元素
```

---

## Task 1: Godot 项目初始化

**Files:**
- Create: `project.godot`
- Create: `scripts/autoload/GameState.gd`
- Create: `scripts/autoload/DataLoader.gd`
- Create: `scripts/autoload/SaveSystem.gd`

- [ ] **Step 1: 创建 Godot 项目**

在终端运行（需要已安装 Godot 4）：
```bash
cd /Users/happyelements/Documents/merge-dress-game
godot4 --headless --quit 2>/dev/null || true
```

或手动用 Godot 编辑器创建项目，项目路径设为 `/Users/happyelements/Documents/merge-dress-game`，渲染器选 Mobile。

- [ ] **Step 2: 创建目录结构**

```bash
cd /Users/happyelements/Documents/merge-dress-game
mkdir -p scenes/MainMenu scenes/MergeBoard scenes/Workshop scenes/DressUp scenes/Room scenes/Story
mkdir -p scripts/autoload
mkdir -p data/items data/levels/chapter1 data/levels/chapter2 data/levels/chapter3
mkdir -p data/recipes data/chapters data/story
mkdir -p assets/items assets/characters assets/furniture assets/ui
```

- [ ] **Step 3: 创建 GameState.gd**

```gdscript
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
    var lvl_key = str(level)
    if lvl_key not in chapter_progress[key]["levels_completed"]:
        chapter_progress[key]["levels_completed"].append(lvl_key)

func mark_goal_done(chapter: int, goal_id: String) -> void:
    var key = str(chapter)
    if not chapter_progress.has(key):
        chapter_progress[key] = {"levels_completed": [], "goals_done": []}
    if goal_id not in chapter_progress[key]["goals_done"]:
        chapter_progress[key]["goals_done"].append(goal_id)
```

- [ ] **Step 4: 创建 DataLoader.gd**

```gdscript
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

func get_item(item_id: String) -> Dictionary:
    var data = load_json("res://data/items/items.json")
    if data == null:
        return {}
    for item in data:
        if item["id"] == item_id:
            return item
    return {}

func get_level(chapter: int, level: int) -> Dictionary:
    var path = "res://data/levels/chapter%d/level_%d_%d.json" % [chapter, chapter, level]
    var data = load_json(path)
    return data if data != null else {}

func get_recipes() -> Array:
    var data = load_json("res://data/recipes/recipes.json")
    return data if data != null else []

func get_chapter_config(chapter: int) -> Dictionary:
    var data = load_json("res://data/chapters/chapters.json")
    if data == null:
        return {}
    for ch in data:
        if ch["id"] == chapter:
            return ch
    return {}

func get_story(chapter: int) -> Array:
    var path = "res://data/story/chapter%d_story.json" % chapter
    var data = load_json(path)
    return data if data != null else []
```

- [ ] **Step 5: 创建 SaveSystem.gd**

```gdscript
# scripts/autoload/SaveSystem.gd
extends Node

const SAVE_PATH = "user://savegame.json"

func save() -> void:
    var gs = GameState
    var data = {
        "current_chapter": gs.current_chapter,
        "chapter_progress": gs.chapter_progress,
        "inventory": gs.inventory,
        "outfit": gs.outfit,
        "rooms": _serialize_rooms(gs.rooms)
    }
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("SaveSystem: cannot write save file")
        return
    file.store_string(JSON.stringify(data))
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
    var gs = GameState
    gs.current_chapter = data.get("current_chapter", 1)
    gs.chapter_progress = data.get("chapter_progress", {})
    gs.inventory = data.get("inventory", {})
    gs.outfit = data.get("outfit", gs.outfit)
    gs.rooms = _deserialize_rooms(data.get("rooms", {}))
    return true

func _serialize_rooms(rooms: Dictionary) -> Dictionary:
    var result = {}
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
    var result = {"living_room": [], "bedroom": [], "kitchen": [], "garden": []}
    for room_id in data:
        result[room_id] = []
        for entry in data[room_id]:
            result[room_id].append({
                "furniture_id": entry["furniture_id"],
                "pos": Vector2(entry["pos_x"], entry["pos_y"])
            })
    return result
```

- [ ] **Step 6: 在 project.godot 中注册 Autoload**

在 Godot 编辑器中：Project → Project Settings → Autoload，依次添加：
- `res://scripts/autoload/GameState.gd` → 名称 `GameState`
- `res://scripts/autoload/DataLoader.gd` → 名称 `DataLoader`
- `res://scripts/autoload/SaveSystem.gd` → 名称 `SaveSystem`

- [ ] **Step 7: Commit**

```bash
cd /Users/happyelements/Documents/merge-dress-game
git add -A
git commit -m "feat: init Godot project structure and autoload singletons"
```

---

## Task 2: JSON 数据文件

**Files:**
- Create: `data/items/items.json`
- Create: `data/recipes/recipes.json`
- Create: `data/chapters/chapters.json`
- Create: `data/levels/chapter1/level_1_1.json`
- Create: `data/levels/chapter1/level_1_2.json`
- Create: `data/levels/chapter1/level_1_3.json`
- Create: `data/levels/chapter2/level_2_1.json`
- Create: `data/levels/chapter2/level_2_2.json`
- Create: `data/levels/chapter3/level_3_1.json`
- Create: `data/story/chapter1_story.json`
- Create: `data/story/chapter2_story.json`
- Create: `data/story/chapter3_story.json`
