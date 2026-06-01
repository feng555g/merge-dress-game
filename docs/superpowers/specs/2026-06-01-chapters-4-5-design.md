# 第4、5章设计文档

**日期：** 2026-06-01  
**目标：** 在现有三章基础上补充第4章「母亲的秘密」和第5章「重新开始」，完成完整的5章游戏。

---

## 一、故事线

### 第4章「母亲的秘密」

母亲带女主回到老宅，逐渐讲述女主失忆前的经历。女主通过整理母亲的旧房间，拼凑出过去的自己。

| 触发点 | 说话人 | 台词 |
|--------|--------|------|
| chapter_start | 母亲 | 这里就是你出生的地方，孩子。 |
| chapter_start | 女主 | 一切都这么陌生…… |
| chapter_start | 旁白 | 老宅的每一个角落，都藏着她遗忘的故事。 |
| chapter_complete | 女主 | 我记起来了，这件衣服……是你为我做的。 |
| chapter_complete | 母亲 | 你终于记得了。 |
| chapter_complete | 旁白 | 记忆的碎片，正在一片片拼回来。 |

### 第5章「重新开始」

女主和母亲决定共同修缮老宅，打造属于两人的新家。最终母女站在门口看着夕阳，温馨收尾。

| 触发点 | 说话人 | 台词 |
|--------|--------|------|
| chapter_start | 女主 | 妈，我们把这里改造成真正的家吧。 |
| chapter_start | 母亲 | 好，我们一起。 |
| chapter_start | 旁白 | 她们开始了新的生活，用双手重建失去的时光。 |
| chapter_complete | 旁白 | 那天的夕阳很美，像是所有失去的时光都回来了。 |
| chapter_complete | 女主 | 妈，谢谢你等我。 |
| chapter_complete | 母亲 | 只要你回来，等多久都值得。 |

---

## 二、新增素材

### 高级中间素材（2个）

| ID | 名称 | 类型 | 合成配方 | 用途 |
|----|------|------|----------|------|
| `embroidered_cloth` | 刺绣布料 | material / cloth | fabric_3 × 2 | 第4/5章服装配方原料 |
| `precious_wood` | 贵重木材 | material / wood | polished_wood × 2 | 第4/5章家具配方原料 |

### 第4章目标物品

| ID | 名称 | 类型 | 配方 |
|----|------|------|------|
| `blouse_memory` | 记忆上衣 | outfit (slot: top) | fabric_3 × 2 + embroidered_cloth × 1 |
| `wardrobe` | 衣橱 | furniture (room: bedroom) | precious_wood × 3 + polished_wood × 1 |
| `mirror_stand` | 立式镜 | furniture (room: bedroom) | precious_wood × 2 + cut_gem × 2 |

### 第5章目标物品

| ID | 名称 | 类型 | 配方 |
|----|------|------|------|
| `dress_heritage` | 传承礼服 | outfit (slot: top) | embroidered_cloth × 3 + cut_gem × 2 |
| `sofa_elegant` | 雅致沙发 | furniture (room: living_room) | precious_wood × 2 + embroidered_cloth × 2 |
| `chandelier` | 水晶吊灯 | furniture (room: living_room) | cut_gem × 3 + gem_chip × 2 |

---

## 三、关卡设计

### 第4章 — 3关

**4_1「旧宅探索」**
- grid_size: 5×5
- initial_items: gem_1×4, wood_1×4, gem_2×2
- goals: gem_chip×2, plank×2
- spawn_pool: gem_1, gem_1, wood_1, wood_1, gem_1
- rewards: gem_chip×3, plank×3
- max_moves: 35
- star_thresholds: 1星≥1步, 2星≤28步, 3星≤20步

**4_2「整理房间」**
- grid_size: 5×5
- initial_items: flower_1×4, gem_1×4, wood_2×2
- goals: fabric_3×1, gem_chip×2
- spawn_pool: flower_1, gem_1, flower_1, wood_1, gem_1
- rewards: fabric_3×2, gem_chip×3
- max_moves: 38
- star_thresholds: 1星≥1步, 2星≤30步, 3星≤22步

**4_3「记忆碎片」**
- grid_size: 5×5
- initial_items: gem_1×4, gem_2×2, wood_1×4, wood_2×2
- goals: cut_gem×2, polished_wood×2
- spawn_pool: gem_1, gem_1, wood_1, gem_2, wood_1
- rewards: cut_gem×3, polished_wood×3
- max_moves: 40
- star_thresholds: 1星≥1步, 2星≤32步, 3星≤24步

### 第5章 — 2关

**5_1「共同修缮」**
- grid_size: 5×5
- initial_items: flower_1×4, gem_1×4, wood_1×4, flower_2×2
- goals: fabric_3×2, gem_chip×2
- spawn_pool: flower_1, gem_1, wood_1, flower_1, gem_1
- rewards: fabric_3×3, gem_chip×3, polished_wood×2
- max_moves: 42
- star_thresholds: 1星≥1步, 2星≤34步, 3星≤26步

**5_2「焕然一新」**
- grid_size: 5×5
- initial_items: gem_1×4, gem_2×2, wood_1×4, wood_2×2, flower_2×2
- goals: cut_gem×3, polished_wood×2, fabric_3×1
- spawn_pool: gem_1, gem_2, wood_1, flower_1, gem_1
- rewards: cut_gem×4, polished_wood×3, fabric_3×2
- max_moves: 45
- star_thresholds: 1星≥1步, 2星≤36步, 3星≤28步

---

## 四、章节目标（chapters.json 新增条目）

**第4章**
- equip blouse_memory（合成并穿上记忆上衣）
- place wardrobe（放置衣橱）
- place mirror_stand（放置立式镜）

**第5章**
- equip dress_heritage（合成并穿上传承礼服）
- place sofa_elegant（放置雅致沙发）
- place chandelier（放置水晶吊灯）

---

## 五、实现范围

本次只修改数据文件，不改动任何脚本：

1. `data/items/items.json` — 新增 8 个 item 定义
2. `data/recipes/recipes.json` — 新增 8 个配方
3. `data/chapters/chapters.json` — 新增第4、5章条目
4. `data/levels/chapter4/level_4_1.json` — 新建
5. `data/levels/chapter4/level_4_2.json` — 新建
6. `data/levels/chapter4/level_4_3.json` — 新建
7. `data/levels/chapter5/level_5_1.json` — 新建
8. `data/levels/chapter5/level_5_2.json` — 新建
9. `data/story/chapter4_story.json` — 新建
10. `data/story/chapter5_story.json` — 新建
