# TypeScript 代码质量与卫生规范 — Cocos Creator 3.8

> 📖 本文件为 `cocos-creator-3x-cn` 技能参考文件，提供 TypeScript 代码质量规范。

---

## 1. 导入规范

### 1.1 模块导入

```typescript
// ✅ 正确：从 'cc' 统一导入
import { _decorator, Component, Node, Vec3, Sprite, SpriteFrame, resources } from 'cc';
const { ccclass, property } = _decorator;

// ✅ 正确：环境宏从 'cc/env' 导入
import { DEBUG, EDITOR, PREVIEW, BUILD } from 'cc/env';

// ❌ 错误：不使用 cc. 全局前缀（3.x 中不存在）
// const node = new cc.Node();

// ✅ 按需导入第三方库
import { someUtil } from '../utils/SomeUtil';
```

### 1.2 导入顺序

```typescript
// 1. 引擎核心模块
import { _decorator, Component, Node, Vec3 } from 'cc';
import { DEBUG } from 'cc/env';

// 2. 引擎 UI/渲染组件
import { Sprite, Label, Button } from 'cc';

// 3. 项目公共模块
import { EventDispatcher } from '../common/EventDispatcher';
import { GameConfig } from '../config/GameConfig';

// 4. 当前模块相关
import { PlayerData } from './PlayerData';
```

---

## 2. 命名规范

| 类别 | 规范 | 示例 |
|------|------|------|
| 类名 | PascalCase | `PlayerController`, `GameManager` |
| cc 类名 | 与类名一致 | `@ccclass('PlayerController')` |
| 方法名 | camelCase | `moveForward()`, `onTouchStart()` |
| 属性名 | camelCase | `moveSpeed`, `targetNode` |
| 私有成员 | _camelCase | `_isMoving`, `_cachedPos` |
| 常量 | UPPER_SNAKE_CASE | `MAX_HEALTH`, `MOVE_SPEED` |
| 枚举名 | PascalCase | `GameState`, `Direction` |
| 枚举值 | PascalCase | `GameState.Playing` |
| 事件名 | kebab-case | `'game-over'`, `'level-up'` |
| 文件名 | PascalCase (与类名一致) | `PlayerController.ts` |

---

## 3. 类型安全

### 3.1 属性声明

```typescript
// ✅ 使用联合类型 + null 初始值
@property(Node)
targetNode: Node | null = null;

// ✅ 使用非空断言（确保在编辑器中赋值）
@property(Sprite)
readonly sprite!: Sprite;

// ✅ 数组初始化
@property({ type: [Node] })
waypoints: Node[] = [];

// ❌ 避免 any
// @property
// data: any = null;
```

### 3.2 Null 安全

```typescript
// ✅ 使用可选链
const pos = this.targetNode?.position;
const sprite = this.node.getComponent(Sprite)?.spriteFrame;

// ✅ 空值合并
const speed = this.config?.speed ?? 10;

// ✅ 提前返回
onTouchStart(event: EventTouch) {
    if (!this.targetNode) return;
    // 安全使用 this.targetNode
}

// ✅ 非空断言（仅在确信不为空时）
const label = this.getComponent(Label)!;
```

### 3.3 枚举使用

```typescript
import { Enum } from 'cc';

// 需要在编辑器面板显示的枚举
enum GameState {
    Idle = 0,
    Playing = 1,
    Paused = 2,
    GameOver = 3,
}
Enum(GameState); // 注册到 cc 枚举系统

@ccclass('GameManager')
export class GameManager extends Component {
    @property({ type: GameState })
    state: GameState = GameState.Idle;
}

// 仅代码使用的枚举，可用 const enum（编译后内联为数值）
const enum Direction {
    Up = 0,
    Down = 1,
    Left = 2,
    Right = 3,
}
```

---

## 4. 生命周期卫生

### 4.1 事件监听配对

```typescript
// ✅ 正确：onEnable / onDisable 严格配对
onEnable() {
    input.on(Input.EventType.TOUCH_START, this.onTouchStart, this);
    input.on(Input.EventType.KEY_DOWN, this.onKeyDown, this);
    this.node.on(Node.EventType.TOUCH_START, this.onNodeTouch, this);
}

onDisable() {
    input.off(Input.EventType.TOUCH_START, this.onTouchStart, this);
    input.off(Input.EventType.KEY_DOWN, this.onKeyDown, this);
    this.node.off(Node.EventType.TOUCH_START, this.onNodeTouch, this);
}
```

### 4.2 资源引用管理

```typescript
@ccclass('ResourceHolder')
export class ResourceHolder extends Component {
    private _loadedAssets: Asset[] = [];

    loadAsset(path: string, type: typeof Asset) {
        resources.load(path, type, (err, asset) => {
            if (err) return;
            asset.addRef();
            this._loadedAssets.push(asset);
        });
    }

    onDestroy() {
        // 释放所有持有的资源
        for (const asset of this._loadedAssets) {
            asset.decRef();
        }
        this._loadedAssets.length = 0;
    }
}
```

### 4.3 定时器清理

```typescript
onDestroy() {
    this.unscheduleAllCallbacks();
    Tween.stopAllByTarget(this.node);
}
```

---

## 5. 代码组织

### 5.1 文件结构

```
assets/scripts/
├── common/              # 公共工具
│   ├── EventDispatcher.ts
│   ├── ObjectPool.ts
│   └── Utils.ts
├── config/              # 配置
│   ├── GameConfig.ts
│   └── AudioConfig.ts
├── manager/             # 管理器（单例）
│   ├── GameManager.ts
│   ├── AudioManager.ts
│   └── UIManager.ts
├── ui/                  # UI 组件
│   ├── HUD.ts
│   ├── ResultPanel.ts
│   └── LoadingScreen.ts
├── game/                # 游戏逻辑
│   ├── Player.ts
│   ├── Enemy.ts
│   └── Bullet.ts
└── data/                # 数据模型
    ├── PlayerData.ts
    └── LevelData.ts
```

### 5.2 单一职责

```typescript
// ✅ 每个组件职责单一
@ccclass('PlayerMovement')
export class PlayerMovement extends Component {
    // 只负责移动逻辑
}

@ccclass('PlayerAnimation')
export class PlayerAnimation extends Component {
    // 只负责动画控制
}

@ccclass('PlayerHealth')  
export class PlayerHealth extends Component {
    // 只负责血量管理
}

// ❌ 避免上帝组件
// class PlayerController { /* 包含移动+动画+血量+UI+音效 */ }
```

### 5.3 访问修饰符

```typescript
@ccclass('Example')
export class Example extends Component {
    // public: 编辑器属性 + 外部 API
    @property
    speed = 10;
    
    // protected: 子类可访问
    protected _state = GameState.Idle;
    
    // private: 仅内部使用
    private _timer = 0;
    private _cache: Map<string, any> = new Map();

    // public 方法：对外接口
    startGame() { /* ... */ }
    
    // private 方法：内部实现
    private calculateScore() { /* ... */ }
}
```

---

## 6. 常见代码异味

| 异味 | 问题 | 修正 |
|------|------|------|
| `as any` 类型断言 | 绕过类型检查 | 使用正确类型或类型守卫 |
| 魔法数字 | 可读性差 | 提取为命名常量 |
| 深层嵌套回调 | 可读性差 | 使用 Promise 或 async/await |
| 超长函数 (>50行) | 难以维护 | 拆分为小函数 |
| 重复代码 | 维护成本高 | 提取公共方法/基类 |
| `console.log` 残留 | 影响性能和包体 | 使用 `DEBUG` 宏包裹 |
| 未处理 `err` 参数 | 静默失败 | 添加错误处理 |
| 硬编码路径字符串 | 易出错 | 提取为常量/配置 |

---

## 7. 调试规范

```typescript
import { DEBUG } from 'cc/env';

// ✅ 使用 DEBUG 宏包裹调试代码
if (DEBUG) {
    console.log('Player position:', this.node.position);
}

// ✅ 封装日志工具
class Logger {
    static log(msg: string, ...args: any[]) {
        if (DEBUG) console.log(`[Game] ${msg}`, ...args);
    }
    static warn(msg: string, ...args: any[]) {
        if (DEBUG) console.warn(`[Game] ${msg}`, ...args);
    }
    static error(msg: string, ...args: any[]) {
        console.error(`[Game] ${msg}`, ...args); // 错误始终输出
    }
}
```
