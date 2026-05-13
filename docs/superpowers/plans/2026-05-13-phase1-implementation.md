# Phase 1 MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable HTML5 merge game prototype with core board mechanics, menu system, and level progression.

**Architecture:** Single-file HTML5 application with embedded JavaScript. Five core classes (GameState, DataLoader, SaveSystem, AssetLoader, SceneManager) manage state and resources. Two scene classes (MainMenu, MergeBoard) handle UI and gameplay. All code in one index.html file for easy deployment.

**Tech Stack:** Vanilla JavaScript, Canvas 2D API, localStorage, fetch API for JSON loading

---

## File Structure

**Create:**
- `index.html` — Complete game (HTML + CSS + JavaScript in one file)

**Use existing:**
- `data/items/items.json` — Item definitions
- `data/chapters/chapters.json` — Chapter configurations
- `data/levels/chapter*/level_*.json` — Level configurations
- `assets/items/*.png` — Item images (23 files)
- `assets/ui/*.jpg` — UI background (1 file)

---

## Task 1: HTML Structure and CSS

**Files:**
- Create: `index.html`

- [ ] **Step 1: Create basic HTML structure**

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <title>合成养成游戏</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: "Microsoft YaHei", "PingFang SC", Arial, sans-serif;
      background: linear-gradient(to bottom, #F5F5F5, #E0E0E0);
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      overflow: hidden;
    }
    
    #gameContainer {
      position: relative;
      width: 800px;
      height: 600px;
      background: white;
      box-shadow: 0 4px 20px rgba(0,0,0,0.2);
      border-radius: 8px;
      overflow: hidden;
    }
    
    #gameCanvas {
      display: block;
      width: 100%;
      height: 100%;
      transform-origin: top left;
    }
    
    #loadingScreen {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      color: white;
      z-index: 1000;
    }
    
    #loadingScreen h1 {
      font-size: 48px;
      margin-bottom: 40px;
      text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
    }
    
    #loadingBar {
      width: 400px;
      height: 20px;
      background: rgba(255,255,255,0.2);
      border-radius: 10px;
      overflow: hidden;
      margin-bottom: 20px;
    }
    
    #loadingProgress {
      width: 0%;
      height: 100%;
      background: white;
      transition: width 0.3s ease;
    }
    
    #loadingText {
      font-size: 18px;
      opacity: 0.9;
    }
    
    /* Responsive scaling */
    @media (max-width: 820px) {
      #gameContainer {
        width: 100vw;
        height: 75vw;
        max-height: 100vh;
        border-radius: 0;
      }
    }
  </style>
</head>
<body>
  <div id="gameContainer">
    <canvas id="gameCanvas" width="800" height="600"></canvas>
    <div id="loadingScreen">
      <h1>合成养成游戏</h1>
      <div id="loadingBar">
        <div id="loadingProgress"></div>
      </div>
      <div id="loadingText">加载中... 0%</div>
    </div>
  </div>
  
  <script>
    // Game code will go here
  </script>
</body>
</html>
```

- [ ] **Step 2: Test HTML structure**

Open `index.html` in Chrome browser.
Expected: See purple gradient loading screen with title "合成养成游戏" and progress bar at 0%.

- [ ] **Step 3: Commit**

```bash
git add index.html
git commit -m "feat: add HTML structure and CSS styling"
```

---

## Task 2: GameState Class

**Files:**
- Modify: `index.html` (add GameState class in script section)

- [ ] **Step 1: Write GameState class**

Add inside `<script>` tag:

```javascript
class GameState {
  constructor() {
    this.currentChapter = 1;
    this.currentLevel = 1;
    this.inventory = {};
    this.completedLevels = [];
  }
  
  addItem(itemId, count = 1) {
    this.inventory[itemId] = (this.inventory[itemId] || 0) + count;
  }
  
  removeItem(itemId, count = 1) {
    const current = this.inventory[itemId] || 0;
    if (current < count) return false;
    this.inventory[itemId] = current - count;
    if (this.inventory[itemId] === 0) {
      delete this.inventory[itemId];
    }
    return true;
  }
  
  hasItem(itemId, count = 1) {
    return (this.inventory[itemId] || 0) >= count;
  }
  
  completeLevel(chapter, level) {
    const levelKey = `${chapter}-${level}`;
    if (!this.completedLevels.includes(levelKey)) {
      this.completedLevels.push(levelKey);
    }
  }
  
  isLevelCompleted(chapter, level) {
    const levelKey = `${chapter}-${level}`;
    return this.completedLevels.includes(levelKey);
  }
  
  isChapterUnlocked(chapter) {
    if (chapter === 1) return true;
    const prevChapter = chapter - 1;
    const prevChapterLevels = [1, 2, 3];
    return prevChapterLevels.every(level => 
      this.isLevelCompleted(prevChapter, level)
    );
  }
  
  toJSON() {
    return {
      currentChapter: this.currentChapter,
      currentLevel: this.currentLevel,
      inventory: this.inventory,
      completedLevels: this.completedLevels
    };
  }
  
  fromJSON(data) {
    this.currentChapter = data.currentChapter || 1;
    this.currentLevel = data.currentLevel || 1;
    this.inventory = data.inventory || {};
    this.completedLevels = data.completedLevels || [];
  }
}
```

- [ ] **Step 2: Test GameState in browser console**

Open index.html in Chrome, open DevTools Console (F12), run:

```javascript
const state = new GameState();
state.addItem('cloth_1', 5);
console.log(state.inventory); // Should show {cloth_1: 5}
console.log(state.hasItem('cloth_1', 3)); // Should show true
state.completeLevel(1, 1);
console.log(state.isLevelCompleted(1, 1)); // Should show true
console.log(state.isChapterUnlocked(2)); // Should show false
```

Expected: All console outputs match comments.

- [ ] **Step 3: Commit**

```bash
git add index.html
git commit -m "feat: add GameState class for state management"
```

---

## Task 3: SaveSystem Class

**Files:**
- Modify: `index.html` (add SaveSystem class)

- [ ] **Step 1: Write SaveSystem class**

Add after GameState class:

```javascript
class SaveSystem {
  constructor(gameState) {
    this.gameState = gameState;
    this.saveKey = 'mergeDressGame_save';
  }
  
  save() {
    try {
      const data = this.gameState.toJSON();
      localStorage.setItem(this.saveKey, JSON.stringify(data));
      return true;
    } catch (e) {
      console.error('Save failed:', e);
      return false;
    }
  }
  
  load() {
    try {
      const data = localStorage.getItem(this.saveKey);
      if (data) {
        this.gameState.fromJSON(JSON.parse(data));
        return true;
      }
      return false;
    } catch (e) {
      console.error('Load failed:', e);
      return false;
    }
  }
  
  clear() {
    localStorage.removeItem(this.saveKey);
  }
}
```

- [ ] **Step 2: Test SaveSystem in browser console**

Open index.html, open Console, run:

```javascript
const state = new GameState();
const saveSystem = new SaveSystem(state);
state.addItem('gem_1', 10);
state.completeLevel(1, 1);
saveSystem.save();
console.log('Saved');

// Reload page, then run:
const state2 = new GameState();
const saveSystem2 = new SaveSystem(state2);
saveSystem2.load();
console.log(state2.inventory); // Should show {gem_1: 10}
console.log(state2.completedLevels); // Should show ['1-1']
```

Expected: After reload, state is restored correctly.

- [ ] **Step 3: Commit**

```bash
git add index.html
git commit -m "feat: add SaveSystem class for localStorage persistence"
```

---

## Task 4: DataLoader Class

**Files:**
- Modify: `index.html` (add DataLoader class)

- [ ] **Step 1: Write DataLoader class**

Add after SaveSystem class:

```javascript
class DataLoader {
  constructor() {
    this.items = [];
    this.chapters = [];
    this.levels = {};
  }
  
  async loadAll() {
    try {
      // Load items
      const itemsRes = await fetch('data/items/items.json');
      this.items = await itemsRes.json();
      
      // Load chapters
      const chaptersRes = await fetch('data/chapters/chapters.json');
      this.chapters = await chaptersRes.json();
      
      // Load all levels
      for (let chapter = 1; chapter <= 3; chapter++) {
        const chapterData = this.chapters.find(c => c.id === chapter);
        if (!chapterData) continue;
        
        for (const levelId of chapterData.levels) {
          const levelRes = await fetch(`data/levels/chapter${chapter}/level_${levelId}.json`);
          const levelData = await levelRes.json();
          this.levels[levelId] = levelData;
        }
      }
      
      return true;
    } catch (e) {
      console.error('Data loading failed:', e);
      return false;
    }
  }
  
  getItem(itemId) {
    return this.items.find(item => item.id === itemId);
  }
  
  getChapter(chapterId) {
    return this.chapters.find(chapter => chapter.id === chapterId);
  }
  
  getLevel(levelId) {
    return this.levels[levelId];
  }
  
  getItemsByType(type) {
    return this.items.filter(item => item.type === type);
  }
}
```

- [ ] **Step 2: Test DataLoader in browser console**

Open index.html, open Console, run:

```javascript
const loader = new DataLoader();
loader.loadAll().then(() => {
  console.log('Items loaded:', loader.items.length); // Should show 30
  console.log('Chapters loaded:', loader.chapters.length); // Should show 3
  const leaf1 = loader.getItem('leaf_1');
  console.log('Leaf 1:', leaf1); // Should show item object
  const level = loader.getLevel('1_1');
  console.log('Level 1-1:', level); // Should show level object
});
```

Expected: All data loads successfully, console shows correct counts and objects.

- [ ] **Step 3: Commit**

```bash
git add index.html
git commit -m "feat: add DataLoader class for JSON data loading"
```

---

## Task 5: AssetLoader Class

**Files:**
- Modify: `index.html` (add AssetLoader class)

- [ ] **Step 1: Write AssetLoader class**

Add after DataLoader class:

```javascript
class AssetLoader {
  constructor() {
    this.images = {};
    this.totalAssets = 0;
    this.loadedAssets = 0;
  }
  
  async loadAll(onProgress) {
    const assetPaths = [
      // Items (23 files)
      'assets/items/leaf_1.png',
      'assets/items/leaf_2.png',
      'assets/items/leaf_3.png',
      'assets/items/flower_1.png',
      'assets/items/flower_2.png',
      'assets/items/flower_3.png',
      'assets/items/gem_1.png',
      'assets/items/gem_2.png',
      'assets/items/gem_3.png',
      'assets/items/wood_1.png',
      'assets/items/wood_2.png',
      'assets/items/wood_3.png',
      'assets/items/fabric_1.png',
      'assets/items/fabric_2.png',
      'assets/items/silk.png',
      'assets/items/gem_shard.png',
      'assets/items/cut_gem.png',
      'assets/items/wood_plank.png',
      'assets/items/polished_wood.png',
      'assets/items/dress_casual.png',
      'assets/items/coat_travel.png',
      'assets/items/boots_leather.png',
      'assets/items/dress_evening.png',
      // UI (1 file)
      'assets/ui/menu_bg.jpg'
    ];
    
    this.totalAssets = assetPaths.length;
    this.loadedAssets = 0;
    
    const loadPromises = assetPaths.map(path => {
      return new Promise((resolve, reject) => {
        const img = new Image();
        img.onload = () => {
          const key = path.split('/').pop().replace(/\.(png|jpg)$/, '');
          this.images[key] = img;
          this.loadedAssets++;
          if (onProgress) {
            onProgress(this.loadedAssets, this.totalAssets);
          }
          resolve();
        };
        img.onerror = () => {
          console.warn(`Failed to load: ${path}`);
          this.loadedAssets++;
          if (onProgress) {
            onProgress(this.loadedAssets, this.totalAssets);
          }
          resolve(); // Don't reject, continue loading
        };
        img.src = path;
      });
    });
    
    await Promise.all(loadPromises);
    return true;
  }
  
  getImage(key) {
    return this.images[key] || null;
  }
}
```

- [ ] **Step 2: Test AssetLoader with progress callback**

Open index.html, open Console, run:

```javascript
const assetLoader = new AssetLoader();
assetLoader.loadAll((loaded, total) => {
  console.log(`Loading: ${loaded}/${total}`);
}).then(() => {
  console.log('All assets loaded');
  console.log('Leaf 1 image:', assetLoader.getImage('leaf_1'));
});
```

Expected: Console shows loading progress from 1/24 to 24/24, then "All assets loaded".

- [ ] **Step 3: Commit**

```bash
git add index.html
git commit -m "feat: add AssetLoader class for image preloading"
```

---

## Task 6: SceneManager and Scene Base Class

**Files:**
- Modify: `index.html` (add Scene base class and SceneManager)

- [ ] **Step 1: Write Scene base class**

Add after AssetLoader class:

```javascript
class Scene {
  constructor(game) {
    this.game = game;
  }
  
  onEnter() {}
  onExit() {}
  update(deltaTime) {}
  render(ctx) {}
  onMouseDown(x, y) {}
  onMouseMove(x, y) {}
  onMouseUp(x, y) {}
}
```

- [ ] **Step 2: Write SceneManager class**

Add after Scene class:

```javascript
class SceneManager {
  constructor(game) {
    this.game = game;
    this.currentScene = null;
  }
  
  switchTo(scene) {
    if (this.currentScene) {
      this.currentScene.onExit();
    }
    this.currentScene = scene;
    if (this.currentScene) {
      this.currentScene.onEnter();
    }
  }
  
  update(deltaTime) {
    if (this.currentScene) {
      this.currentScene.update(deltaTime);
    }
  }
  
  render(ctx) {
    if (this.currentScene) {
      this.currentScene.render(ctx);
    }
  }
  
  handleMouseDown(x, y) {
    if (this.currentScene) {
      this.currentScene.onMouseDown(x, y);
    }
  }
  
  handleMouseMove(x, y) {
    if (this.currentScene) {
      this.currentScene.onMouseMove(x, y);
    }
  }
  
  handleMouseUp(x, y) {
    if (this.currentScene) {
      this.currentScene.onMouseUp(x, y);
    }
  }
}
```

- [ ] **Step 3: Test SceneManager with dummy scene**

Open index.html, open Console, run:

```javascript
class TestScene extends Scene {
  onEnter() { console.log('TestScene entered'); }
  onExit() { console.log('TestScene exited'); }
  render(ctx) { console.log('TestScene rendering'); }
}

const game = { canvas: document.getElementById('gameCanvas') };
const manager = new SceneManager(game);
const scene = new TestScene(game);
manager.switchTo(scene); // Should log "TestScene entered"
manager.render(null); // Should log "TestScene rendering"
```

Expected: Console shows "TestScene entered" and "TestScene rendering".

- [ ] **Step 4: Commit**

```bash
git add index.html
git commit -m "feat: add Scene base class and SceneManager"
```

---

## Task 7: Game Main Class and Initialization

**Files:**
- Modify: `index.html` (add Game class and initialization code)

- [ ] **Step 1: Write Game class**

Add after SceneManager class:

```javascript
class Game {
  constructor() {
    this.canvas = document.getElementById('gameCanvas');
    this.ctx = this.canvas.getContext('2d');
    this.gameState = new GameState();
    this.saveSystem = new SaveSystem(this.gameState);
    this.dataLoader = new DataLoader();
    this.assetLoader = new AssetLoader();
    this.sceneManager = new SceneManager(this);
    
    this.lastTime = 0;
    this.isRunning = false;
    
    this.setupInputHandlers();
  }
  
  setupInputHandlers() {
    const getCanvasCoords = (clientX, clientY) => {
      const rect = this.canvas.getBoundingClientRect();
      const scaleX = this.canvas.width / rect.width;
      const scaleY = this.canvas.height / rect.height;
      return {
        x: (clientX - rect.left) * scaleX,
        y: (clientY - rect.top) * scaleY
      };
    };
    
    // Mouse events
    this.canvas.addEventListener('mousedown', (e) => {
      const coords = getCanvasCoords(e.clientX, e.clientY);
      this.sceneManager.handleMouseDown(coords.x, coords.y);
    });
    
    this.canvas.addEventListener('mousemove', (e) => {
      const coords = getCanvasCoords(e.clientX, e.clientY);
      this.sceneManager.handleMouseMove(coords.x, coords.y);
    });
    
    this.canvas.addEventListener('mouseup', (e) => {
      const coords = getCanvasCoords(e.clientX, e.clientY);
      this.sceneManager.handleMouseUp(coords.x, coords.y);
    });
    
    // Touch events
    this.canvas.addEventListener('touchstart', (e) => {
      e.preventDefault();
      const touch = e.touches[0];
      const coords = getCanvasCoords(touch.clientX, touch.clientY);
      this.sceneManager.handleMouseDown(coords.x, coords.y);
    });
    
    this.canvas.addEventListener('touchmove', (e) => {
      e.preventDefault();
      const touch = e.touches[0];
      const coords = getCanvasCoords(touch.clientX, touch.clientY);
      this.sceneManager.handleMouseMove(coords.x, coords.y);
    });
    
    this.canvas.addEventListener('touchend', (e) => {
      e.preventDefault();
      if (e.changedTouches.length > 0) {
        const touch = e.changedTouches[0];
        const coords = getCanvasCoords(touch.clientX, touch.clientY);
        this.sceneManager.handleMouseUp(coords.x, coords.y);
      }
    });
  }
  
  async init() {
    // Update loading screen
    const updateLoading = (loaded, total) => {
      const percent = Math.floor((loaded / total) * 100);
      document.getElementById('loadingProgress').style.width = percent + '%';
      document.getElementById('loadingText').textContent = `加载中... ${percent}%`;
    };
    
    // Load data
    updateLoading(0, 2);
    await this.dataLoader.loadAll();
    updateLoading(1, 2);
    
    // Load assets
    await this.assetLoader.loadAll((loaded, total) => {
      updateLoading(1 + (loaded / total), 2);
    });
    
    // Load save
    this.saveSystem.load();
    
    // Hide loading screen
    document.getElementById('loadingScreen').style.display = 'none';
    
    // Start game loop
    this.isRunning = true;
    this.lastTime = performance.now();
    this.gameLoop(this.lastTime);
  }
  
  gameLoop(currentTime) {
    if (!this.isRunning) return;
    
    const deltaTime = (currentTime - this.lastTime) / 1000;
    this.lastTime = currentTime;
    
    // Update
    this.sceneManager.update(deltaTime);
    
    // Render
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    this.sceneManager.render(this.ctx);
    
    requestAnimationFrame((time) => this.gameLoop(time));
  }
  
  start() {
    this.init();
  }
}
```

- [ ] **Step 2: Add game initialization code**

Add at the end of script section:

```javascript
// Start game when page loads
window.addEventListener('load', () => {
  const game = new Game();
  game.start();
});
```

- [ ] **Step 3: Test game initialization**

Open index.html in Chrome.
Expected: Loading screen shows, progress bar fills to 100%, then loading screen disappears and canvas shows blank white screen.

- [ ] **Step 4: Commit**

```bash
git add index.html
git commit -m "feat: add Game class and initialization with loading screen"
```

---

## Task 8: MainMenu Scene - Structure and Rendering

**Files:**
- Modify: `index.html` (add MainMenu class)

- [ ] **Step 1: Write MainMenu class structure**

Add after Game class:

```javascript
class MainMenu extends Scene {
  constructor(game) {
    super(game);
    this.buttons = [];
  }
  
  onEnter() {
    this.buildButtons();
  }
  
  buildButtons() {
    this.buttons = [];
    const chapters = this.game.dataLoader.chapters;
    
    let yOffset = 120;
    for (const chapter of chapters) {
      // Chapter unlocked?
      const unlocked = this.game.gameState.isChapterUnlocked(chapter.id);
      
      // Chapter button area
      const chapterY = yOffset;
      yOffset += 40;
      
      // Level buttons
      const levelButtons = [];
      for (let i = 0; i < chapter.levels.length; i++) {
        const levelId = chapter.levels[i];
        const [chapterNum, levelNum] = levelId.split('_').map(Number);
        const completed = this.game.gameState.isLevelCompleted(chapterNum, levelNum);
        
        levelButtons.push({
          x: 200 + i * 120,
          y: yOffset,
          width: 100,
          height: 60,
          chapter: chapterNum,
          level: levelNum,
          levelId: levelId,
          unlocked: unlocked,
          completed: completed,
          label: `${chapterNum}-${levelNum}`
        });
      }
      
      this.buttons.push({
        type: 'chapter',
        chapter: chapter,
        chapterY: chapterY,
        levelButtons: levelButtons
      });
      
      yOffset += 100;
    }
  }
  
  render(ctx) {
    // Background
    ctx.fillStyle = '#F5F5F5';
    ctx.fillRect(0, 0, 800, 600);
    
    // Title
    ctx.fillStyle = '#3E2723';
    ctx.font = 'bold 48px "Microsoft YaHei", Arial';
    ctx.textAlign = 'center';
    ctx.fillText('合成养成游戏', 400, 80);
    
    // Render chapters and levels
    for (const btn of this.buttons) {
      // Chapter title
      ctx.fillStyle = '#3E2723';
      ctx.font = 'bold 24px "Microsoft YaHei", Arial';
      ctx.textAlign = 'left';
      ctx.fillText(`第${btn.chapter.id}章：${btn.chapter.name}`, 100, btn.chapterY);
      
      // Level buttons
      for (const levelBtn of btn.levelButtons) {
        this.renderLevelButton(ctx, levelBtn);
      }
    }
  }
  
  renderLevelButton(ctx, btn) {
    // Button background
    if (btn.unlocked) {
      ctx.fillStyle = btn.completed ? '#4CAF50' : '#2196F3';
    } else {
      ctx.fillStyle = '#BDBDBD';
    }
    
    ctx.beginPath();
    ctx.roundRect(btn.x, btn.y, btn.width, btn.height, 8);
    ctx.fill();
    
    // Button border
    ctx.strokeStyle = '#FFFFFF';
    ctx.lineWidth = 2;
    ctx.stroke();
    
    // Button text
    ctx.fillStyle = '#FFFFFF';
    ctx.font = 'bold 20px Arial';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    
    if (btn.unlocked) {
      ctx.fillText(btn.label, btn.x + btn.width / 2, btn.y + btn.height / 2 - 5);
      if (btn.completed) {
        ctx.font = '16px Arial';
        ctx.fillText('✓', btn.x + btn.width / 2, btn.y + btn.height / 2 + 12);
      }
    } else {
      ctx.fillText('🔒', btn.x + btn.width / 2, btn.y + btn.height / 2);
    }
  }
  
  onMouseDown(x, y) {
    // Check level button clicks
    for (const btn of this.buttons) {
      for (const levelBtn of btn.levelButtons) {
        if (levelBtn.unlocked &&
            x >= levelBtn.x && x <= levelBtn.x + levelBtn.width &&
            y >= levelBtn.y && y <= levelBtn.y + levelBtn.height) {
          this.startLevel(levelBtn.chapter, levelBtn.level, levelBtn.levelId);
          return;
        }
      }
    }
  }
  
  startLevel(chapter, level, levelId) {
    const levelData = this.game.dataLoader.getLevel(levelId);
    if (levelData) {
      const mergeBoard = new MergeBoard(this.game, levelData, chapter, level);
      this.game.sceneManager.switchTo(mergeBoard);
    }
  }
  
  update(deltaTime) {}
  onMouseMove(x, y) {}
  onMouseUp(x, y) {}
}
```

- [ ] **Step 2: Update Game class to start with MainMenu**

Find the `init()` method in Game class, add after loading screen hide:

```javascript
// Start with main menu
const mainMenu = new MainMenu(this);
this.sceneManager.switchTo(mainMenu);
```

- [ ] **Step 3: Test MainMenu rendering**

Open index.html in Chrome.
Expected: After loading, see main menu with title "合成养成游戏" and 3 chapters with level buttons. Chapter 1 levels should be blue (unlocked), chapters 2-3 should be gray (locked).

- [ ] **Step 4: Commit**

```bash
git add index.html
git commit -m "feat: add MainMenu scene with chapter and level selection"
```

---

## Task 9: MergeBoard Scene - Structure and Grid

**Files:**
- Modify: `index.html` (add MergeBoard class)

- [ ] **Step 1: Write MergeBoard class structure**

Add after MainMenu class:

```javascript
class MergeBoard extends Scene {
  constructor(game, levelData, chapter, level) {
    super(game);
    this.levelData = levelData;
    this.chapter = chapter;
    this.level = level;
    
    this.gridCols = levelData.grid_size.cols;
    this.gridRows = levelData.grid_size.rows;
    this.cellSize = 70;
    this.gridX = (800 - this.gridCols * this.cellSize) / 2;
    this.gridY = 120;
    
    this.grid = Array(this.gridCols * this.gridRows).fill(null);
    this.goals = levelData.goals;
    this.collected = {};
    
    this.draggedItem = null;
    this.draggedFrom = -1;
    this.dragX = 0;
    this.dragY = 0;
    this.isDragging = false;
    
    this.animating = false;
    this.showVictory = false;
  }
  
  onEnter() {
    this.initializeGrid();
  }
  
  initializeGrid() {
    // Place initial items
    for (const item of this.levelData.initial_items) {
      const index = item.row * this.gridCols + item.col;
      this.grid[index] = {
        id: item.item_id,
        col: item.col,
        row: item.row
      };
    }
  }
  
  getCellIndex(col, row) {
    if (col < 0 || col >= this.gridCols || row < 0 || row >= this.gridRows) {
      return -1;
    }
    return row * this.gridCols + col;
  }
  
  getCellCoords(index) {
    const col = index % this.gridCols;
    const row = Math.floor(index / this.gridCols);
    return { col, row };
  }
  
  getCellCenter(col, row) {
    return {
      x: this.gridX + col * this.cellSize + this.cellSize / 2,
      y: this.gridY + row * this.cellSize + this.cellSize / 2
    };
  }
  
  getCellAtPosition(x, y) {
    const col = Math.floor((x - this.gridX) / this.cellSize);
    const row = Math.floor((y - this.gridY) / this.cellSize);
    return this.getCellIndex(col, row);
  }
  
  render(ctx) {
    // Background
    ctx.fillStyle = '#F5F5F5';
    ctx.fillRect(0, 0, 800, 600);
    
    // Title
    ctx.fillStyle = '#3E2723';
    ctx.font = 'bold 24px "Microsoft YaHei", Arial';
    ctx.textAlign = 'center';
    ctx.fillText(`第${this.chapter}章 - 关卡${this.level}`, 400, 40);
    
    // Goals
    ctx.font = '18px "Microsoft YaHei", Arial';
    let goalText = '目标: ';
    for (const goal of this.goals) {
      const item = this.game.dataLoader.getItem(goal.item_id);
      const collected = this.collected[goal.item_id] || 0;
      goalText += `${item.name} ${collected}/${goal.count}  `;
    }
    ctx.fillText(goalText, 400, 70);
    
    // Grid
    this.renderGrid(ctx);
    
    // Dragged item
    if (this.isDragging && this.draggedItem) {
      this.renderDraggedItem(ctx);
    }
    
    // Victory screen
    if (this.showVictory) {
      this.renderVictory(ctx);
    }
    
    // Back button
    this.renderBackButton(ctx);
  }
  
  renderGrid(ctx) {
    for (let row = 0; row < this.gridRows; row++) {
      for (let col = 0; col < this.gridCols; col++) {
        const x = this.gridX + col * this.cellSize;
        const y = this.gridY + row * this.cellSize;
        
        // Cell background
        ctx.fillStyle = '#FFFFFF';
        ctx.beginPath();
        ctx.roundRect(x + 2, y + 2, this.cellSize - 4, this.cellSize - 4, 8);
        ctx.fill();
        
        // Cell border
        ctx.strokeStyle = '#CCCCCC';
        ctx.lineWidth = 2;
        ctx.stroke();
        
        // Item in cell
        const index = this.getCellIndex(col, row);
        const item = this.grid[index];
        if (item && !(this.isDragging && index === this.draggedFrom)) {
          this.renderItem(ctx, item.id, x + this.cellSize / 2, y + this.cellSize / 2, 1.0);
        }
      }
    }
  }
  
  renderItem(ctx, itemId, x, y, alpha) {
    const itemData = this.game.dataLoader.getItem(itemId);
    if (!itemData) return;
    
    const img = this.game.assetLoader.getImage(itemId);
    if (img) {
      ctx.save();
      ctx.globalAlpha = alpha;
      const size = this.cellSize * 0.8;
      ctx.drawImage(img, x - size / 2, y - size / 2, size, size);
      ctx.restore();
    } else {
      // Fallback: colored circle
      ctx.save();
      ctx.globalAlpha = alpha;
      ctx.fillStyle = itemData.color || '#999999';
      ctx.beginPath();
      ctx.arc(x, y, this.cellSize * 0.3, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    }
  }
  
  renderDraggedItem(ctx) {
    this.renderItem(ctx, this.draggedItem.id, this.dragX, this.dragY, 0.7);
  }
  
  renderBackButton(ctx) {
    ctx.fillStyle = '#757575';
    ctx.beginPath();
    ctx.roundRect(20, 520, 100, 50, 8);
    ctx.fill();
    
    ctx.fillStyle = '#FFFFFF';
    ctx.font = 'bold 18px "Microsoft YaHei", Arial';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('返回', 70, 545);
  }
  
  renderVictory(ctx) {
    // Semi-transparent overlay
    ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
    ctx.fillRect(0, 0, 800, 600);
    
    // Victory panel
    ctx.fillStyle = '#FFFFFF';
    ctx.beginPath();
    ctx.roundRect(200, 150, 400, 300, 16);
    ctx.fill();
    
    // Title
    ctx.fillStyle = '#4CAF50';
    ctx.font = 'bold 36px "Microsoft YaHei", Arial';
    ctx.textAlign = 'center';
    ctx.fillText('关卡完成！', 400, 220);
    
    // Rewards
    ctx.fillStyle = '#3E2723';
    ctx.font = '20px "Microsoft YaHei", Arial';
    ctx.fillText('获得奖励：', 400, 280);
    
    // Show collected items
    ctx.font = '18px "Microsoft YaHei", Arial';
    let rewardY = 320;
    for (const goal of this.goals) {
      const item = this.game.dataLoader.getItem(goal.item_id);
      const collected = this.collected[goal.item_id] || 0;
      ctx.fillText(`${item.name} × ${collected}`, 400, rewardY);
      rewardY += 30;
    }
    
    // Return button
    ctx.fillStyle = '#4CAF50';
    ctx.beginPath();
    ctx.roundRect(300, 370, 200, 50, 8);
    ctx.fill();
    
    ctx.fillStyle = '#FFFFFF';
    ctx.font = 'bold 20px "Microsoft YaHei", Arial';
    ctx.fillText('返回主菜单', 400, 395);
  }
  
  update(deltaTime) {}
  onMouseMove(x, y) {}
  onMouseUp(x, y) {}
  onMouseDown(x, y) {}
}
```

- [ ] **Step 2: Test MergeBoard rendering**

Open index.html, click on level "1-1" button.
Expected: See merge board with 5×7 grid, initial items placed, goal text at top, back button at bottom.

- [ ] **Step 3: Commit**

```bash
git add index.html
git commit -m "feat: add MergeBoard scene structure and grid rendering"
```

---

## Task 10: MergeBoard - Drag and Drop Logic

**Files:**
- Modify: `index.html` (update MergeBoard class)

- [ ] **Step 1: Implement drag start**

Replace `onMouseDown` method in MergeBoard class:

```javascript
onMouseDown(x, y) {
  if (this.animating || this.showVictory) return;
  
  // Check back button
  if (x >= 20 && x <= 120 && y >= 520 && y <= 570) {
    const mainMenu = new MainMenu(this.game);
    this.game.sceneManager.switchTo(mainMenu);
    return;
  }
  
  // Check victory return button
  if (this.showVictory) {
    if (x >= 300 && x <= 500 && y >= 370 && y <= 420) {
      const mainMenu = new MainMenu(this.game);
      this.game.sceneManager.switchTo(mainMenu);
    }
    return;
  }
  
  // Check grid cell
  const cellIndex = this.getCellAtPosition(x, y);
  if (cellIndex >= 0 && this.grid[cellIndex]) {
    this.draggedItem = this.grid[cellIndex];
    this.draggedFrom = cellIndex;
    this.dragX = x;
    this.dragY = y;
    this.isDragging = true;
  }
}
```

- [ ] **Step 2: Implement drag move**

Replace `onMouseMove` method in MergeBoard class:

```javascript
onMouseMove(x, y) {
  if (this.isDragging) {
    this.dragX = x;
    this.dragY = y;
  }
}
```

- [ ] **Step 3: Implement drag end**

Replace `onMouseUp` method in MergeBoard class:

```javascript
onMouseUp(x, y) {
  if (!this.isDragging) return;
  
  const targetIndex = this.getCellAtPosition(x, y);
  
  if (targetIndex >= 0 && targetIndex !== this.draggedFrom) {
    const targetItem = this.grid[targetIndex];
    
    if (!targetItem) {
      // Move to empty cell
      this.grid[targetIndex] = this.draggedItem;
      const coords = this.getCellCoords(targetIndex);
      this.grid[targetIndex].col = coords.col;
      this.grid[targetIndex].row = coords.row;
      this.grid[this.draggedFrom] = null;
    } else if (targetItem.id === this.draggedItem.id) {
      // Try merge
      this.tryMerge(this.draggedFrom, targetIndex);
    } else {
      // Different items, return to original position
      // (item stays in grid[draggedFrom])
    }
  }
  
  // Reset drag state
  this.isDragging = false;
  this.draggedItem = null;
  this.draggedFrom = -1;
}
```

- [ ] **Step 4: Test drag and drop**

Open index.html, go to level 1-1, try dragging items.
Expected: Items follow mouse, can be moved to empty cells, return to original position if dropped on different items.

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "feat: add drag and drop logic to MergeBoard"
```

---

## Task 11: MergeBoard - Merge Logic

**Files:**
- Modify: `index.html` (add merge logic to MergeBoard)

- [ ] **Step 1: Implement tryMerge method**

Add method to MergeBoard class:

```javascript
tryMerge(fromIndex, toIndex) {
  const item1 = this.grid[fromIndex];
  const item2 = this.grid[toIndex];
  
  if (!item1 || !item2 || item1.id !== item2.id) {
    return false;
  }
  
  const itemData = this.game.dataLoader.getItem(item1.id);
  if (!itemData || !itemData.merge_into) {
    return false;
  }
  
  // Remove both items
  this.grid[fromIndex] = null;
  this.grid[toIndex] = null;
  
  // Create new item at target position
  const coords = this.getCellCoords(toIndex);
  this.grid[toIndex] = {
    id: itemData.merge_into,
    col: coords.col,
    row: coords.row
  };
  
  // Check if merged item is tier 3 (has drops)
  const newItemData = this.game.dataLoader.getItem(itemData.merge_into);
  if (newItemData && newItemData.drops) {
    for (const dropId of newItemData.drops) {
      this.game.gameState.addItem(dropId, 1);
      
      // Check if it's a goal item
      for (const goal of this.goals) {
        if (goal.item_id === dropId) {
          this.collected[dropId] = (this.collected[dropId] || 0) + 1;
        }
      }
    }
    
    this.game.saveSystem.save();
  }
  
  // Check victory
  this.checkVictory();
  
  // Try to spawn new item
  this.trySpawnItem();
  
  return true;
}
```

- [ ] **Step 2: Implement checkVictory method**

Add method to MergeBoard class:

```javascript
checkVictory() {
  const allComplete = this.goals.every(goal => {
    const collected = this.collected[goal.item_id] || 0;
    return collected >= goal.count;
  });
  
  if (allComplete && !this.showVictory) {
    this.showVictory = true;
    this.game.gameState.completeLevel(this.chapter, this.level);
    this.game.saveSystem.save();
  }
}
```

- [ ] **Step 3: Implement trySpawnItem method**

Add method to MergeBoard class:

```javascript
trySpawnItem() {
  if (Math.random() > 0.3) return; // 30% spawn chance
  
  // Find empty cells
  const emptyCells = [];
  for (let i = 0; i < this.grid.length; i++) {
    if (!this.grid[i]) {
      emptyCells.push(i);
    }
  }
  
  if (emptyCells.length === 0) return;
  
  // Pick random empty cell
  const targetIndex = emptyCells[Math.floor(Math.random() * emptyCells.length)];
  const coords = this.getCellCoords(targetIndex);
  
  // Spawn tier 1 item (leaf_1, flower_1, wood_1, or gem_1)
  const spawnPool = ['leaf_1', 'flower_1', 'wood_1', 'gem_1'];
  const itemId = spawnPool[Math.floor(Math.random() * spawnPool.length)];
  
  this.grid[targetIndex] = {
    id: itemId,
    col: coords.col,
    row: coords.row
  };
}
```

- [ ] **Step 4: Test merge logic**

Open index.html, go to level 1-1, drag two leaf_1 items together.
Expected: They merge into leaf_2. Drag two leaf_2 together → merge into leaf_3. When leaf_3 merges, goal counter increases and new items may spawn.

- [ ] **Step 5: Test victory condition**

Continue playing until goal is met (collect 1 leaf_3).
Expected: Victory screen appears with "关卡完成！" message and return button.

- [ ] **Step 6: Commit**

```bash
git add index.html
git commit -m "feat: add merge logic and victory condition to MergeBoard"
```

---

## Task 12: Final Integration and Testing

**Files:**
- Modify: `index.html` (final polish and bug fixes)

- [ ] **Step 1: Add CanvasRenderingContext2D.roundRect polyfill**

Add at the beginning of script section (before any classes):

```javascript
// Polyfill for roundRect (Safari compatibility)
if (!CanvasRenderingContext2D.prototype.roundRect) {
  CanvasRenderingContext2D.prototype.roundRect = function(x, y, width, height, radius) {
    this.moveTo(x + radius, y);
    this.lineTo(x + width - radius, y);
    this.arcTo(x + width, y, x + width, y + radius, radius);
    this.lineTo(x + width, y + height - radius);
    this.arcTo(x + width, y + height, x + width - radius, y + height, radius);
    this.lineTo(x + radius, y + height);
    this.arcTo(x, y + height, x, y + height - radius, radius);
    this.lineTo(x, y + radius);
    this.arcTo(x, y, x + radius, y, radius);
  };
}
```

- [ ] **Step 2: Test complete game flow**

Open index.html in Chrome:
1. Loading screen shows and completes
2. Main menu appears with 3 chapters
3. Click level 1-1 → board appears
4. Drag and merge items → works smoothly
5. Complete goal → victory screen appears
6. Click return → back to main menu
7. Level 1-1 now shows ✓ mark
8. Refresh page → progress is saved

Expected: All steps work correctly.

- [ ] **Step 3: Test on mobile device (optional)**

Open index.html on mobile browser (iOS Safari or Android Chrome).
Expected: Touch drag works, game scales to fit screen.

- [ ] **Step 4: Test save/load**

1. Complete level 1-1
2. Close browser tab
3. Reopen index.html
4. Check that level 1-1 shows ✓ mark

Expected: Progress persists across sessions.

- [ ] **Step 5: Final commit**

```bash
git add index.html
git commit -m "feat: complete Phase 1 MVP with all core features"
```

---

## Verification Checklist

After completing all tasks, verify these acceptance criteria:

- [ ] ✅ Double-click index.html opens game in Chrome
- [ ] ✅ Loading screen shows progress from 0% to 100%
- [ ] ✅ Main menu displays 3 chapters with level buttons
- [ ] ✅ Chapter 1 levels are unlocked (blue), others locked (gray)
- [ ] ✅ Clicking level 1-1 enters merge board
- [ ] ✅ Board shows 5×7 grid with initial items
- [ ] ✅ Items can be dragged with mouse
- [ ] ✅ Same items merge when dragged together
- [ ] ✅ Merge animation is smooth (items disappear, new item appears)
- [ ] ✅ Goal counter updates when tier 3 items merge
- [ ] ✅ New items spawn randomly after merges
- [ ] ✅ Victory screen appears when goal is met
- [ ] ✅ Clicking return goes back to main menu
- [ ] ✅ Completed level shows ✓ mark
- [ ] ✅ Refresh page preserves progress (localStorage)
- [ ] ✅ Touch drag works on mobile devices

---

## Known Limitations (Phase 1)

These are intentionally not implemented in Phase 1:

- No merge animations (items instantly disappear/appear)
- No sound effects or music
- No recipe crafting system
- No dress-up system
- No room decoration system
- No story dialogue system
- Chapter 2 and 3 levels exist but have no unique mechanics
- No star rating system (3-star completion)
- No move counter or time limit enforcement

These will be added in future phases.

