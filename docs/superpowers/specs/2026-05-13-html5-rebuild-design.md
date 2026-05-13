# 合成养成游戏 HTML5 重构设计文档

## 项目目标

将原 Godot 4 设计重构为纯 HTML5 + JavaScript 实现，输出单个可在 Chrome 直接运行的 HTML 文件。

## 技术栈

- **核心：** 纯 HTML5 + Vanilla JavaScript（无框架依赖）
- **渲染：** Canvas 2D API
- **数据：** JSON 文件（通过 fetch 加载）
- **资源：** PNG 图片（31 张，已就位）
- **存档：** localStorage
- **目标：** 单个 HTML 文件 + data/ + assets/ 文件夹

## 架构设计

### 文件结构

```
merge-dress-game/
├── index.html              # 主游戏文件（包含所有 JS/CSS）
├── data/                   # JSON 数据文件（已存在）
│   ├── items/items.json
│   ├── recipes/recipes.json
│   ├── chapters/chapters.json
│   ├── levels/chapter*/level_*.json
│   └── story/chapter*_story.json
└── assets/                 # 图片资源（已就位，31 张）
    ├── items/              # 23 张物品图标
    ├── furniture/          # 6 张家具
    ├── characters/         # 1 张角色立绘
    └── ui/                 # 1 张主菜单背景
```

### 代码架构

**单文件结构：** 所有代码写在 `index.html` 的 `<script>` 标签内

**模块划分（通过 class 组织）：**

1. **GameState** — 全局状态管理（章节进度、背包、装扮、房间）
2. **DataLoader** — JSON 数据加载与缓存
3. **SaveSystem** — localStorage 存档读写
4. **AssetLoader** — 图片资源预加载
5. **SceneManager** — 场景切换控制器
6. **MainMenu** — 主菜单 + 章节选择
7. **MergeBoard** — 棋盘关卡场景
8. **Workshop** — 配方合成界面
9. **DressUp** — 装扮界面
10. **Room** — 房间装修界面
11. **Story** — 剧情对话场景

### 渲染方案

**Canvas 分层：**
- 主 Canvas（800×600px）— 游戏内容渲染
- UI Canvas（800×600px）— 按钮、文本覆盖层

**坐标系统：**
- 逻辑分辨率：800×600（固定）
- 自适应缩放：CSS `transform: scale()` 适配屏幕

**棋盘布局：**
- 6×6 格子，每格 80×80px
- 居中显示，周围留白放 UI 按钮

### 交互方案

**输入处理：**
- PC：鼠标点击 + 拖拽
- 移动端：触摸事件（touch events）

**拖拽合成：**
1. 点击棋盘物品 → 高亮选中
2. 拖动到另一物品 → 检查合成规则
3. 合成成功 → 播放动画 + 生成新物品
4. 合成失败 → 物品回弹

### 数据流

```
启动 → AssetLoader 预加载图片 → DataLoader 加载 JSON
     → SaveSystem 读取存档 → 恢复 GameState
     → SceneManager 切换到 MainMenu

用户操作 → 场景内部处理 → 更新 GameState
        → SaveSystem 自动保存 → localStorage

关卡完成 → 检查章节目标 → 解锁新内容
        → 触发剧情 → Story 场景
```

## 六大系统详细设计

### 1. 棋盘合成系统（MergeBoard）

**核心机制：**
- 6×6 格子，每格可放 1 个物品
- 相同物品拖拽合并 → 升级为下一级
- 关卡目标：收集指定物品（如"3 个宝晶"）

**数据结构：**
```javascript
{
  grid: Array(36),  // [null, {id:"leaf_1", pos:1}, ...]
  level: {
    chapter: 1,
    level: 1,
    goals: [{item:"gem_3", count:3}],
    initial_items: ["leaf_1", "leaf_1", "flower_1"]
  }
}
```

**渲染：**
- 绘制 6×6 网格线
- 每格绘制物品图标（从 assets/items/ 加载）
- 拖拽时绘制半透明跟随鼠标的物品

**合成逻辑：**
```javascript
function tryMerge(item1, item2) {
  if (item1.id !== item2.id) return false;
  const recipe = recipes.find(r => 
    r.inputs.length === 2 && 
    r.inputs.every(i => i.id === item1.id)
  );
  if (!recipe) return false;
  // 移除两个物品，生成新物品
  return recipe.output;
}
```

### 2. 配方合成系统（Workshop）

**界面布局：**
- 左侧：背包物品列表（滚动）
- 中间：配方卡片展示（3 列网格）
- 右侧：选中配方的详情 + 合成按钮

**配方卡片：**
```
┌─────────────┐
│  [输出图标]  │
│   物品名称   │
│ 材料1 材料2  │  ← 小图标 + 数量
│  [合成按钮]  │  ← 材料不足时灰色
└─────────────┘
```

**合成流程：**
1. 点击配方卡片 → 显示详情
2. 检查背包材料是否足够
3. 点击合成 → 扣除材料 → 添加产物到背包
4. 播放合成动画（闪光效果）

### 3. 装扮系统（DressUp）

**界面布局：**
- 左侧：女主角色立绘（300×600px）
- 右侧：5 个装备槽位按钮
  - 上衣、下装、鞋子、配饰、发型
- 底部：背包服装列表（横向滚动）

**装备流程：**
1. 点击槽位 → 弹出该槽位可用服装列表
2. 点击服装 → 装备到槽位
3. 角色立绘实时更新（叠加渲染多层图片）

**渲染方案：**
```javascript
// 分层绘制
ctx.drawImage(character_base, x, y);  // 基础立绘
if (outfit.top) ctx.drawImage(items[outfit.top], x, y);
if (outfit.bottom) ctx.drawImage(items[outfit.bottom], x, y);
// ...
```

### 4. 装修系统（Room）

**界面布局：**
- 主区域：房间背景（600×400px）
- 底部：家具列表（横向滚动）
- 右上角：房间切换按钮（客厅/卧室/厨房/花园）

**放置流程：**
1. 点击家具 → 进入放置模式
2. 拖动到房间内 → 显示半透明预览
3. 松开鼠标 → 固定位置
4. 已放置家具可拖动调整位置

**数据结构：**
```javascript
rooms: {
  "living_room": [
    {furniture_id: "table_old", x: 100, y: 200},
    {furniture_id: "chair_fabric", x: 150, y: 220}
  ]
}
```

### 5. 剧情系统（Story）

**界面布局：**
- 上半部分：角色立绘（居中）
- 下半部分：对话框
  - 角色名
  - 对话文本（打字机效果）
  - 下一句按钮

**数据格式：**
```json
[
  {
    "speaker": "艾拉",
    "text": "欢迎来到这个神奇的世界...",
    "character": "character.png"
  }
]
```

**播放流程：**
1. 加载章节剧情 JSON
2. 逐句显示对话
3. 点击屏幕 → 下一句
4. 剧情结束 → 返回主菜单

### 6. 存档系统（SaveSystem）

**存档内容：**
```javascript
{
  current_chapter: 1,
  chapter_progress: {
    "1": {
      levels_completed: ["1", "2"],
      goals_done: ["goal_dress_1"]
    }
  },
  inventory: {"leaf_1": 5, "gem_3": 2},
  outfit: {top: "dress_casual", bottom: "", ...},
  rooms: {...}
}
```

**保存时机：**
- 关卡完成时
- 合成物品后
- 装扮/装修改变后
- 每 30 秒自动保存

**读取时机：**
- 游戏启动时
- 主菜单显示"继续游戏"按钮（如果有存档）

## 场景切换流程

```
MainMenu
  ├─ 开始游戏 → 选择章节 → MergeBoard（关卡）
  │                         ├─ 完成 → 检查章节目标
  │                         │         ├─ 未完成 → 返回章节选择
  │                         │         └─ 完成 → Story → 解锁下一章
  │                         └─ 暂停菜单 → Workshop / DressUp / Room
  ├─ 继续游戏 → 恢复上次场景
  └─ 设置 → 音量/语言（暂不实现）
```

## UI 设计规范

**颜色方案：**
- 主色：暖棕色（#8B6F47）— 按钮背景
- 辅色：米白色（#F5E6D3）— 面板背景
- 强调色：金色（#FFD700）— 高亮/选中状态
- 文字：深棕色（#3E2723）

**按钮样式：**
- 圆角矩形（border-radius: 8px）
- 悬停时：亮度 +10%
- 点击时：缩放 0.95

**字体：**
- 中文：微软雅黑 / 苹方
- 英文：Arial
- 大小：标题 24px，正文 16px，小字 12px

## 性能优化

1. **图片预加载：** 启动时一次性加载所有 31 张图片
2. **Canvas 离屏渲染：** 静态背景预渲染到离屏 Canvas
3. **事件节流：** 拖拽事件每 16ms 处理一次
4. **局部重绘：** 只重绘变化区域（如拖拽物品）

## 兼容性

- **目标浏览器：** Chrome 最新版（必须）
- **次要支持：** Safari / Firefox / Edge
- **移动端：** 触摸事件支持（iOS Safari / Android Chrome）

## 开发计划

分 5 个任务实现：

1. **基础框架** — index.html 骨架 + 5 个核心类（GameState/DataLoader/SaveSystem/AssetLoader/SceneManager）
2. **主菜单 + 棋盘** — MainMenu + MergeBoard（含拖拽合成）
3. **配方 + 装扮** — Workshop + DressUp
4. **装修 + 剧情** — Room + Story
5. **集成测试** — 完整流程测试 + bug 修复

## 验收标准

- ✅ 双击 index.html 在 Chrome 中打开即可运行
- ✅ 完成第 1 章第 1 关（收集 3 个宝晶）
- ✅ 合成一件服装并装备
- ✅ 放置一件家具
- ✅ 观看一段剧情
- ✅ 存档后刷新页面，进度保留
