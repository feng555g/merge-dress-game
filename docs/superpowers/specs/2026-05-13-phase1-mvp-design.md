# 合成养成游戏 HTML5 版本 - 第一阶段 MVP 设计文档

**日期：** 2026-05-13  
**状态：** 已确认  
**阶段：** Phase 1 - 最小可玩原型  
**目标：** 实现核心棋盘合成玩法，验证游戏机制是否有趣  

---

## 1. 项目概述

将合成养成游戏重构为纯 HTML5 + JavaScript 实现，第一阶段聚焦于核心玩法验证。

**第一阶段包含：**
- 基础框架（状态管理、数据加载、存档、资源加载）
- 主菜单（章节和关卡选择）
- 棋盘合成系统（完整的拖拽合成玩法）
- 关卡目标检测和胜利判定

**第一阶段不包含：**
- 配方合成系统
- 装扮系统
- 装修系统
- 剧情对话系统

---

## 2. 技术架构

### 2.1 文件结构

```
merge-dress-game/
├── index.html              # 单个 HTML 文件（包含所有 JS/CSS）
├── data/                   # JSON 数据文件（已存在）
│   ├── items/items.json
│   ├── recipes/recipes.json
│   ├── chapters/chapters.json
│   ├── levels/chapter*/level_*.json
│   └── story/chapter*_story.json
└── assets/                 # 图片资源（已存在，31 张）
    ├── items/              # 23 张物品图标
    ├── furniture/          # 6 张家具
    ├── characters/         # 1 张角色立绘
    └── ui/                 # 1 张主菜单背景
```

### 2.2 代码组织

**单文件结构：** 所有代码写在 `index.html` 的 `<script>` 标签内

**核心类（5 个）：**
1. **GameState** — 全局状态管理
2. **DataLoader** — JSON 数据加载与缓存
3. **SaveSystem** — localStorage 存档读写
4. **AssetLoader** — 图片资源预加载
5. **SceneManager** — 场景切换控制器

**场景类（2 个）：**
1. **MainMenu** — 主菜单 + 章节关卡选择
2. **MergeBoard** — 棋盘合成场景

**主入口：**
- **Game** 类 — 初始化和启动游戏循环

### 2.3 渲染方案

**Canvas 配置：**
- 单个 Canvas 元素（800×600px 逻辑分辨率）
- CSS `transform: scale()` 自适应屏幕尺寸
- 60 FPS 游戏循环（`requestAnimationFrame`）

**坐标系统：**
- 逻辑分辨率固定为 800×600
- 所有绘制使用逻辑坐标
- 自动缩放到实际屏幕尺寸

### 2.4 交互方案

**输入处理：**
- PC：鼠标点击 + 拖拽
- 移动端：触摸事件（touchstart/touchmove/touchend）
- 统一的事件处理接口

**拖拽流程：**
1. 鼠标按下/触摸开始 → 记录选中的物品和格子
2. 鼠标移动/触摸移动 → 物品跟随指针（半透明）
3. 鼠标松开/触摸结束 → 检查目标格子并执行操作

---

## 3. 核心类详细设计

### 3.1 GameState（全局状态管理）

**职责：**
- 管理游戏进度（当前章节、关卡）
- 管理背包（物品和数量）
- 管理已完成的关卡列表

**数据结构：**
```javascript
class GameState {
  constructor() {
    this.currentChapter = 1;
    this.currentLevel = 1;
    this.inventory = {};  // item_id -> count
    this.completedLevels = [];  // ["1-1", "1-2", ...]
  }
  
  // 背包操作
  addItem(itemId, count = 1) { ... }
  removeItem(itemId, count = 1) { ... }
  hasItem(itemId, count = 1) { ... }
  
  // 进度操作
  completeLevel(chapter, level) { ... }
  isLevelCompleted(chapter, level) { ... }
  isChapterUnlocked(chapter) { ... }
}
```

**解锁逻辑：**
- 第 1 章默认解锁
- 完成上一章的所有关卡后解锁下一章

### 3.2 DataLoader（JSON 数据加载）

**职责：**
- 启动时加载所有 JSON 数据
- 缓存到内存，提供查询方法

**加载的数据：**
- `data/items/items.json` — 所有物品定义
- `data/recipes/recipes.json` — 所有配方定义
- `data/chapters/chapters.json` — 章节配置
- `data/levels/chapter*/level_*.json` — 所有关卡配置

**查询方法：**
```javascript
class DataLoader {
  async loadAll() { ... }
  getItem(itemId) { ... }
  getLevel(chapter, level) { ... }
  getChapter(chapterId) { ... }
}
```

### 3.3 SaveSystem（localStorage 存档）

**职责：**
- 自动保存游戏状态到 localStorage
- 启动时自动读取存档

**保存内容：**
```javascript
{
  "currentChapter": 1,
  "currentLevel": 1,
  "inventory": {"cloth_1": 5, "gem_piece": 2},
  "completedLevels": ["1-1", "1-2"]
}
```

**保存时机：**
- 关卡完成时
- 获得材料时
- 每次状态变化后自动保存

### 3.4 AssetLoader（图片预加载）

**职责：**
- 启动时加载所有 31 张图片
- 显示加载进度条
- 加载完成后才进入游戏

**加载流程：**
1. 扫描 assets/ 目录下的所有图片路径
2. 创建 Image 对象并加载
3. 更新进度条（已加载 / 总数）
4. 全部加载完成 → 触发回调

**图片映射：**
```javascript
{
  "leaf_1": Image对象,
  "flower_1": Image对象,
  "gem_1": Image对象,
  ...
}
```

### 3.5 SceneManager（场景切换）

**职责：**
- 管理当前活动场景
- 处理场景切换
- 分发输入事件和渲染调用

**场景接口：**
```javascript
class Scene {
  onEnter() { ... }  // 进入场景时调用
  onExit() { ... }   // 离开场景时调用
  update(deltaTime) { ... }  // 每帧更新
  render(ctx) { ... }  // 每帧渲染
  onMouseDown(x, y) { ... }  // 输入事件
  onMouseMove(x, y) { ... }
  onMouseUp(x, y) { ... }
}
```

---

## 4. 主菜单场景（MainMenu）

### 4.1 功能

- 显示游戏标题
- 章节选择列表（第 1-3 章）
- 每个章节显示：章节名称、关卡按钮列表
- 已完成的关卡显示星星标记 ✓
- 未解锁的关卡显示锁图标 🔒
- 点击关卡按钮 → 进入棋盘场景

### 4.2 UI 布局

```
┌────────────────────────┐
│    合成养成游戏标题     │
│                        │
│  ┌──────────────────┐  │
│  │ 第1章：新的开始   │  │
│  │ [1-1✓] [1-2✓] [1-3]│  │
│  └──────────────────┘  │
│                        │
│  ┌──────────────────┐  │
│  │ 第2章：神秘来信   │  │
│  │ [2-1] [2-2] 🔒    │  │
│  └──────────────────┘  │
│                        │
│  ┌──────────────────┐  │
│  │ 第3章：隐藏的秘密 │  │
│  │ 🔒 🔒 🔒          │  │
│  └──────────────────┘  │
└────────────────────────┘
```

### 4.3 交互逻辑

**关卡按钮状态：**
- 已完成：显示 ✓，可重玩
- 未完成但已解锁：正常显示，可点击
- 未解锁：显示 🔒，不可点击

**点击事件：**
- 点击可用关卡按钮 → 切换到 MergeBoard 场景
- 传递关卡数据（chapter, level）

---

## 5. 棋盘合成场景（MergeBoard）

### 5.1 核心功能

- 6×6 格子棋盘（每格 80×80px）
- 拖拽合成：相同物品合并 → 升级为下一级
- 关卡目标：收集指定数量的指定物品
- 目标完成 → 显示胜利界面 → 获得材料奖励 → 返回主菜单

### 5.2 数据结构

```javascript
class MergeBoard {
  constructor(levelData) {
    this.grid = Array(36).fill(null);  // 6×6 = 36 格
    this.goals = levelData.goals;  // [{item:"gem_3", count:3}]
    this.collected = {};  // 已收集的目标物品计数
    this.draggedItem = null;  // 当前拖拽的物品
    this.draggedFrom = -1;  // 拖拽起始格子索引
  }
}
```

**格子索引：**
```
0  1  2  3  4  5
6  7  8  9  10 11
12 13 14 15 16 17
18 19 20 21 22 23
24 25 26 27 28 29
30 31 32 33 34 35
```

### 5.3 合成逻辑

**合成规则：**
1. 检查两个物品的 `id` 是否相同
2. 查询 items.json 中该物品的 `merge_into` 字段
3. 如果 `merge_into` 不为 null：
   - 删除两个物品
   - 在目标格子生成新物品
   - 播放合成动画
4. 如果是 tier 3 物品（最高级）：
   - 合成后检查 `drops` 字段
   - 将掉落的材料添加到背包
   - 更新目标计数

**合成示例：**
```javascript
// items.json 中的定义
{"id": "leaf_1", "merge_into": "leaf_2", ...}
{"id": "leaf_2", "merge_into": "leaf_3", ...}
{"id": "leaf_3", "merge_into": null, "drops": ["cloth_1"], ...}

// 合成流程
leaf_1 + leaf_1 → leaf_2
leaf_2 + leaf_2 → leaf_3
leaf_3 + leaf_3 → 掉落 cloth_1（添加到背包）
```

### 5.4 拖拽流程

**1. 鼠标按下（onMouseDown）：**
- 检查点击位置是否在棋盘格子内
- 如果格子有物品：记录 `draggedItem` 和 `draggedFrom`
- 从格子中移除物品（视觉上跟随鼠标）

**2. 鼠标移动（onMouseMove）：**
- 更新 `draggedItem` 的位置为鼠标坐标
- 重绘 Canvas（物品半透明跟随鼠标）

**3. 鼠标松开（onMouseUp）：**
- 检查松开位置是否在棋盘格子内
- 如果在格子内：
  - 目标格子为空：移动物品到目标格子
  - 目标格子有相同物品：尝试合成
  - 目标格子有不同物品：回弹到原位置
- 如果不在格子内：回弹到原位置

### 5.5 关卡初始化

**初始物品放置：**
- 从关卡配置的 `initial_items` 字段读取
- 示例：`["leaf_1", "leaf_1", "flower_1"]`
- 在随机空格子放置这些物品

**物品生成机制：**
- 每次合成后，有 30% 概率生成新物品
- 生成的物品类型：从关卡的 `spawn_pool` 中随机选择
- 生成位置：随机空格子
- 如果棋盘满了，不生成新物品

### 5.6 目标检测

**检测时机：**
- 每次合成 tier 3 物品后检查

**检测逻辑：**
```javascript
// 当 tier 3 物品合成时
if (item.tier === 3 && item.drops) {
  for (let drop of item.drops) {
    // 检查是否是目标物品
    for (let goal of this.goals) {
      if (goal.item === drop) {
        this.collected[drop] = (this.collected[drop] || 0) + 1;
      }
    }
  }
}

// 检查是否所有目标都达成
let allComplete = this.goals.every(goal => 
  this.collected[goal.item] >= goal.count
);

if (allComplete) {
  this.showVictory();
}
```

### 5.7 胜利界面

**显示内容：**
```
┌────────────────────────┐
│      关卡完成！         │
│                        │
│   获得奖励：            │
│   粗布 × 2             │
│   细布 × 1             │
│                        │
│   [返回主菜单]          │
└────────────────────────┘
```

**奖励计算：**
- 从关卡配置的 `rewards` 字段读取
- 将奖励材料添加到背包
- 标记关卡为已完成
- 保存游戏状态

### 5.8 UI 元素

**顶部：**
- 关卡标题（"第 1 章 - 关卡 1"）
- 目标显示（"收集宝晶：2/3"）

**中间：**
- 6×6 棋盘（480×480px）
- 居中显示

**底部：**
- 返回按钮（返回主菜单）

---

## 6. 视觉呈现

### 6.1 视觉风格

**配色方案：**
- 背景：浅色渐变（#F5F5F5 到 #E0E0E0）
- 棋盘格子：白色圆角矩形（border-radius: 8px），浅灰边框（#CCCCCC）
- 物品：绘制 PNG 图片（从 assets/items/ 加载）
- 按钮：圆角矩形，主色调 #4CAF50，悬停时变亮 10%
- 文字：深棕色（#3E2723）

**字体：**
- 中文：微软雅黑 / 苹方
- 英文：Arial
- 大小：标题 32px，正文 20px，小字 16px

### 6.2 动画效果

**合成动画（300ms）：**
1. 两个物品向中心移动（150ms）
2. 缩放到 0 并消失（50ms）
3. 新物品从 0 放大到 1（100ms）

**物品生成动画（200ms）：**
- 从缩放 0 弹出到缩放 1
- 使用 easeOutBack 缓动函数

**拖拽效果：**
- 物品半透明（opacity: 0.7）
- 添加阴影（shadow: 0 4px 8px rgba(0,0,0,0.3)）

**按钮点击动画（100ms）：**
- 缩放到 0.95
- 松开后恢复到 1.0

### 6.3 渲染优化

**绘制顺序：**
1. 背景（纯色或渐变）
2. 棋盘格子（6×6 个矩形）
3. 格子内的物品（PNG 图片）
4. 拖拽中的物品（半透明 + 阴影）
5. UI 元素（文字、按钮）

**性能优化：**
- 图片预加载：启动时一次性加载所有 31 张图片
- 事件节流：拖拽事件每 16ms 处理一次（60 FPS）
- 只在状态变化时重绘 Canvas（不是每帧都重绘）

---

## 7. 兼容性

**目标浏览器：**
- Chrome 最新版（必须支持）
- Safari / Firefox / Edge（次要支持）

**移动端：**
- iOS Safari
- Android Chrome
- 支持触摸事件（touchstart/touchmove/touchend）

**响应式设计：**
- 逻辑分辨率：800×600
- 自动缩放适配不同屏幕尺寸
- 移动端竖屏优先

---

## 8. 开发验收标准

第一阶段完成的标准：

- ✅ 双击 index.html 在 Chrome 中打开即可运行
- ✅ 显示加载进度条，加载完成后进入主菜单
- ✅ 主菜单显示 3 个章节，第 1 章的关卡可点击
- ✅ 点击关卡进入棋盘场景
- ✅ 棋盘显示 6×6 格子和初始物品
- ✅ 可以拖拽物品移动和合成
- ✅ 合成有动画效果（流畅，不卡顿）
- ✅ 完成关卡目标后显示胜利界面
- ✅ 获得材料奖励并添加到背包
- ✅ 返回主菜单后，已完成的关卡显示 ✓
- ✅ 刷新页面后，进度保留（localStorage 存档）
- ✅ 移动端触摸操作正常

---

## 9. 后续阶段规划

**第二阶段：配方合成 + 装扮系统**
- 工坊界面（配方合成）
- 装扮界面（换装预览）
- 完整的"打关卡→合成→换装"循环

**第三阶段：装修 + 剧情系统**
- 房间装修界面
- 剧情对话场景
- 章节解锁条件（养成目标）

**第四阶段：优化和完善**
- 音效和背景音乐
- 更多动画效果
- 性能优化
- 移动端适配优化

---

## 10. 技术风险和应对

**风险 1：Canvas 性能问题**
- 应对：使用离屏 Canvas 预渲染静态背景
- 应对：只在状态变化时重绘，不是每帧都重绘

**风险 2：移动端触摸事件兼容性**
- 应对：统一的事件处理接口，同时支持鼠标和触摸
- 应对：测试 iOS Safari 和 Android Chrome

**风险 3：图片加载失败**
- 应对：显示加载进度和错误提示
- 应对：提供占位图（纯色方块）作为后备

**风险 4：localStorage 存档丢失**
- 应对：每次保存前先读取，确保不覆盖其他数据
- 应对：提供"重置进度"功能

---

## 11. 开发时间估算

**总计：** 约 6-8 小时

- 基础框架（GameState、DataLoader、SaveSystem、AssetLoader、SceneManager）：2 小时
- 主菜单场景：1 小时
- 棋盘合成场景（核心逻辑）：2 小时
- 拖拽交互和动画：1.5 小时
- 测试和调试：1.5 小时

---

## 12. 总结

第一阶段聚焦于核心玩法验证，实现最小可玩原型。完成后可以实际玩几局，感受拖拽合成的手感和关卡目标的平衡性。如果核心玩法有趣，再继续开发后续系统；如果不够好玩，可以及时调整合成规则和关卡设计，避免浪费其他系统的开发时间。
