# 事件模式 — LayaAir 2.0

> 📖 LayaAir 2.0 基于 `EventDispatcher` 事件系统，所有 `Sprite`、`Script` 及 `Stage` 均继承自 `EventDispatcher`。

---

## 1. 事件系统基础

### 注册与注销模式

```typescript
// ✅ 标准配对模式
class PlayerScript extends Laya.Script {
    onEnable(): void {
        // 注册事件
        this.owner.on(Laya.Event.CLICK, this, this.onClick);
        Laya.stage.on(Laya.Event.RESIZE, this, this.onResize);
    }

    onDisable(): void {
        // 注销事件（必须与 onEnable 配对）
        this.owner.off(Laya.Event.CLICK, this, this.onClick);
        Laya.stage.off(Laya.Event.RESIZE, this, this.onResize);
    }

    private onClick(e: Laya.Event): void {
        console.log("clicked at:", e.stageX, e.stageY);
    }

    private onResize(): void {
        // 处理尺寸变化
    }
}
```

### 注册方式

| 方法 | 说明 |
|------|------|
| `node.on(type, caller, fn)` | 持续监听 |
| `node.once(type, caller, fn)` | 只触发一次后自动注销 |
| `node.off(type, caller, fn)` | 注销指定监听 |
| `node.offAll(type)` | 注销该类型所有监听 |
| `node.hasListener(type)` | 是否有该类监听 |

---

## 2. Laya.Event 常用常量

### 鼠标/触摸事件

| 常量 | 说明 |
|------|------|
| `Laya.Event.CLICK` | 点击 |
| `Laya.Event.DOUBLE_CLICK` | 双击 |
| `Laya.Event.MOUSE_DOWN` | 鼠标/触摸按下 |
| `Laya.Event.MOUSE_UP` | 鼠标/触摸抬起 |
| `Laya.Event.MOUSE_MOVE` | 鼠标/触摸移动 |
| `Laya.Event.MOUSE_OVER` | 鼠标悬浮进入 |
| `Laya.Event.MOUSE_OUT` | 鼠标悬浮离开 |
| `Laya.Event.TOUCH_BEGIN` | 触摸开始 |
| `Laya.Event.TOUCH_MOVE` | 触摸移动 |
| `Laya.Event.TOUCH_END` | 触摸结束 |
| `Laya.Event.TOUCH_CANCEL` | 触摸取消 |

### 系统/生命周期事件

| 常量 | 说明 |
|------|------|
| `Laya.Event.CHANGE` | 值改变（Slider/Input 等） |
| `Laya.Event.COMPLETE` | 加载/动画完成 |
| `Laya.Event.PROGRESS` | 加载进度 |
| `Laya.Event.ERROR` | 错误 |
| `Laya.Event.RESIZE` | 舞台尺寸改变 |
| `Laya.Event.BLUR` | 失去焦点 |
| `Laya.Event.FOCUS` | 获得焦点 |

---

## 3. 触摸/鼠标事件详解

```typescript
// Event 对象属性
node.on(Laya.Event.MOUSE_DOWN, this, (e: Laya.Event) => {
    console.log(e.stageX, e.stageY);    // 舞台坐标
    console.log(e.localX, e.localY);    // 本地坐标
    console.log(e.target);              // 事件目标节点
    console.log(e.currentTarget);       // 当前处理节点

    e.stopPropagation();                // 阻止冒泡
});

// 多点触摸
Laya.stage.on(Laya.Event.TOUCH_BEGIN, this, (e: Laya.Event) => {
    const touches = e.touches;  // 所有触摸点
    for (const touch of touches) {
        console.log(touch.stageX, touch.stageY);
    }
});

// 拖拽实现
class DragScript extends Laya.Script {
    private _offsetX: number = 0;
    private _offsetY: number = 0;

    onEnable(): void {
        this.owner.on(Laya.Event.MOUSE_DOWN, this, this.onDown);
    }

    onDisable(): void {
        this.owner.off(Laya.Event.MOUSE_DOWN, this, this.onDown);
        Laya.stage.off(Laya.Event.MOUSE_MOVE, this, this.onMove);
        Laya.stage.off(Laya.Event.MOUSE_UP, this, this.onUp);
    }

    private onDown(e: Laya.Event): void {
        this._offsetX = Laya.stage.mouseX - this.owner.x;
        this._offsetY = Laya.stage.mouseY - this.owner.y;
        Laya.stage.on(Laya.Event.MOUSE_MOVE, this, this.onMove);
        Laya.stage.on(Laya.Event.MOUSE_UP, this, this.onUp);
    }

    private onMove(): void {
        this.owner.x = Laya.stage.mouseX - this._offsetX;
        this.owner.y = Laya.stage.mouseY - this._offsetY;
    }

    private onUp(): void {
        Laya.stage.off(Laya.Event.MOUSE_MOVE, this, this.onMove);
        Laya.stage.off(Laya.Event.MOUSE_UP, this, this.onUp);
    }
}
```

---

## 4. 自定义事件（事件总线）

### 方案 A：通过 Sprite/Script 派发

```typescript
// 派发
this.owner.event("player-score", [100]);
// 或者通过 EventDispatcher
(this.owner as Laya.EventDispatcher).event("player-score", [100]);

// 监听（只要有该节点的引用）
playerNode.on("player-score", this, (score: number) => {
    this.updateScore(score);
});
```

### 方案 B：全局事件总线（单例 EventDispatcher）

```typescript
// EventBus.ts
class EventBus {
    private static _inst: Laya.EventDispatcher;

    public static get inst(): Laya.EventDispatcher {
        if (!this._inst) {
            this._inst = new Laya.EventDispatcher();
        }
        return this._inst;
    }
}

// 发布事件
EventBus.inst.event("GAME_OVER", [score]);

// 订阅事件
EventBus.inst.on("GAME_OVER", this, (score: number) => {
    this.showResult(score);
});

// 取消订阅（在 onDisable/onDestroy 中）
EventBus.inst.off("GAME_OVER", this, handler);
```

### 方案 C：类型安全事件总线

```typescript
// 定义事件类型
const GameEvents = {
    SCORE_CHANGED: "SCORE_CHANGED",
    PLAYER_DIED:   "PLAYER_DIED",
    LEVEL_UP:      "LEVEL_UP",
} as const;

type GameEventType = typeof GameEvents[keyof typeof GameEvents];

// 使用
EventBus.inst.on(GameEvents.SCORE_CHANGED, this, (score: number) => { });
EventBus.inst.event(GameEvents.SCORE_CHANGED, [newScore]);
```

---

## 5. 键盘事件

```typescript
// 注册键盘事件（在 Stage 上）
Laya.stage.on(Laya.Event.KEY_DOWN, this, this.onKeyDown);
Laya.stage.on(Laya.Event.KEY_UP, this, this.onKeyUp);

private onKeyDown(e: Laya.Event): void {
    switch (e.keyCode) {
        case Laya.Keyboard.LEFT:   this._moveLeft = true; break;
        case Laya.Keyboard.RIGHT:  this._moveRight = true; break;
        case Laya.Keyboard.SPACE:  this.jump(); break;
        case 65: /* 'A' 键 */      break;
    }
}

private onKeyUp(e: Laya.Event): void {
    switch (e.keyCode) {
        case Laya.Keyboard.LEFT:  this._moveLeft = false; break;
        case Laya.Keyboard.RIGHT: this._moveRight = false; break;
    }
}

// 常用 Laya.Keyboard 常量
// LEFT(37), UP(38), RIGHT(39), DOWN(40)
// SPACE(32), ENTER(13), ESCAPE(27)
// A-Z: 65-90
```

---

## 6. 事件传播控制

```typescript
// 阻止事件冒泡
node.on(Laya.Event.CLICK, this, (e: Laya.Event) => {
    e.stopPropagation();  // 阻止向父节点传播
});

// 拦截穿透
// mouseThrough = false（默认）：节点背景区域也响应事件
// mouseThrough = true：仅有子节点时才响应事件
node.mouseThrough = true;

// mouseEnabled = false：完全屏蔽该节点及子节点的事件
node.mouseEnabled = false;
```

---

## 7. 事件注销检查清单

```
每个 on() 在哪里调用？→ 对应的 off() 必须有配对：

场景                    注册位置        注销位置
────────────────────────────────────────────────
脚本组件交互事件        onEnable        onDisable
全局事件（舞台缩放等）  onLoad/onStart  onDestroy
EventBus 订阅           onEnable        onDisable
once() 注册             任意位置        触发后自动注销
```
