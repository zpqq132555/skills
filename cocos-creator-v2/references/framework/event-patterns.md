# Cocos Creator 2.4 事件模式

> 官方文档：https://docs.cocos.com/creator/2.4/manual/zh/scripting/events.html

## 目录

- [节点事件（触摸/鼠标）](#节点事件)
- [系统全局事件（键盘/重力）](#系统全局事件)
- [自定义事件](#自定义事件)
- [事件冒泡（dispatchEvent）](#事件冒泡)
- [EventTarget 全局事件总线](#全局事件总线)
- [事件清理规范](#事件清理规范)
- [常见错误](#常见错误)

---

## 节点事件

### 触摸事件

```typescript
const { ccclass } = cc._decorator;

@ccclass
export default class TouchHandler extends cc.Component {
    protected onEnable(): void {
        this.node.on(cc.Node.EventType.TOUCH_START, this.onTouchStart, this);
        this.node.on(cc.Node.EventType.TOUCH_MOVE, this.onTouchMove, this);
        this.node.on(cc.Node.EventType.TOUCH_END, this.onTouchEnd, this);
        this.node.on(cc.Node.EventType.TOUCH_CANCEL, this.onTouchCancel, this);
    }

    protected onDisable(): void {
        this.node.off(cc.Node.EventType.TOUCH_START, this.onTouchStart, this);
        this.node.off(cc.Node.EventType.TOUCH_MOVE, this.onTouchMove, this);
        this.node.off(cc.Node.EventType.TOUCH_END, this.onTouchEnd, this);
        this.node.off(cc.Node.EventType.TOUCH_CANCEL, this.onTouchCancel, this);
    }

    private onTouchStart(event: cc.Event.EventTouch): void {
        const touchPos = event.getLocation();         // 世界坐标
        const localPos = this.node.convertToNodeSpaceAR(touchPos); // 本地坐标
        if (CC_DEBUG) {
            cc.log("触摸开始:", touchPos.x, touchPos.y);
        }
    }

    private onTouchMove(event: cc.Event.EventTouch): void {
        const delta = event.getDelta(); // 移动增量
        this.node.x += delta.x;
        this.node.y += delta.y;
    }

    private onTouchEnd(event: cc.Event.EventTouch): void {
        // 触摸结束
    }

    private onTouchCancel(event: cc.Event.EventTouch): void {
        // 触摸取消（被中断）
    }
}
```

### 触摸事件 API

| 方法 | 说明 |
|------|------|
| `event.getLocation()` | 触摸点世界坐标 (cc.Vec2) |
| `event.getLocationX()` | 触摸点 X 世界坐标 |
| `event.getLocationY()` | 触摸点 Y 世界坐标 |
| `event.getDelta()` | 与上一次位置的增量 |
| `event.getStartLocation()` | 触摸开始的位置 |
| `event.getPreviousLocation()` | 上一次触摸的位置 |
| `event.getID()` | 触摸 ID（多点触摸） |
| `event.stopPropagation()` | 停止事件冒泡 |

### 鼠标事件

```typescript
onEnable(): void {
    this.node.on(cc.Node.EventType.MOUSE_DOWN, this.onMouseDown, this);
    this.node.on(cc.Node.EventType.MOUSE_MOVE, this.onMouseMove, this);
    this.node.on(cc.Node.EventType.MOUSE_UP, this.onMouseUp, this);
    this.node.on(cc.Node.EventType.MOUSE_WHEEL, this.onMouseWheel, this);
    this.node.on(cc.Node.EventType.MOUSE_ENTER, this.onMouseEnter, this);
    this.node.on(cc.Node.EventType.MOUSE_LEAVE, this.onMouseLeave, this);
}

private onMouseDown(event: cc.Event.EventMouse): void {
    if (event.getButton() === cc.Event.EventMouse.BUTTON_LEFT) {
        cc.log("左键点击");
    } else if (event.getButton() === cc.Event.EventMouse.BUTTON_RIGHT) {
        cc.log("右键点击");
    }
}

private onMouseWheel(event: cc.Event.EventMouse): void {
    const scrollY = event.getScrollY(); // 滚轮增量
}
```

---

## 系统全局事件

### 键盘事件

```typescript
@ccclass
export default class KeyboardHandler extends cc.Component {
    private moveDir: cc.Vec2 = cc.v2(0, 0);
    private pressedKeys: Set<number> = new Set();

    protected onEnable(): void {
        cc.systemEvent.on(cc.SystemEvent.EventType.KEY_DOWN, this.onKeyDown, this);
        cc.systemEvent.on(cc.SystemEvent.EventType.KEY_UP, this.onKeyUp, this);
    }

    protected onDisable(): void {
        cc.systemEvent.off(cc.SystemEvent.EventType.KEY_DOWN, this.onKeyDown, this);
        cc.systemEvent.off(cc.SystemEvent.EventType.KEY_UP, this.onKeyUp, this);
    }

    private onKeyDown(event: cc.Event.EventKeyboard): void {
        this.pressedKeys.add(event.keyCode);
        this.updateMoveDirection();
    }

    private onKeyUp(event: cc.Event.EventKeyboard): void {
        this.pressedKeys.delete(event.keyCode);
        this.updateMoveDirection();
    }

    private updateMoveDirection(): void {
        this.moveDir.x = 0;
        this.moveDir.y = 0;

        if (this.pressedKeys.has(cc.macro.KEY.w) || this.pressedKeys.has(cc.macro.KEY.up)) {
            this.moveDir.y = 1;
        }
        if (this.pressedKeys.has(cc.macro.KEY.s) || this.pressedKeys.has(cc.macro.KEY.down)) {
            this.moveDir.y = -1;
        }
        if (this.pressedKeys.has(cc.macro.KEY.a) || this.pressedKeys.has(cc.macro.KEY.left)) {
            this.moveDir.x = -1;
        }
        if (this.pressedKeys.has(cc.macro.KEY.d) || this.pressedKeys.has(cc.macro.KEY.right)) {
            this.moveDir.x = 1;
        }
    }

    protected update(dt: number): void {
        if (this.moveDir.x !== 0 || this.moveDir.y !== 0) {
            this.node.x += this.moveDir.x * this.moveSpeed * dt;
            this.node.y += this.moveDir.y * this.moveSpeed * dt;
        }
    }
}
```

### 重力感应事件

```typescript
onEnable(): void {
    cc.systemEvent.on(
        cc.SystemEvent.EventType.DEVICEMOTION,
        this.onDeviceMotion,
        this
    );
    // 启用重力感应
    cc.systemEvent.setAccelerometerEnabled(true);
    cc.systemEvent.setAccelerometerInterval(1 / 60);
}

onDisable(): void {
    cc.systemEvent.off(
        cc.SystemEvent.EventType.DEVICEMOTION,
        this.onDeviceMotion,
        this
    );
}

private onDeviceMotion(event: cc.Event.EventAcceleration): void {
    const acc = event.acc;
    this.node.x += acc.x * 10;
    this.node.y += acc.y * 10;
}
```

---

## 自定义事件

### 节点级自定义事件（emit）

```typescript
// 发射自定义事件（不冒泡）
this.node.emit("score-changed", 100, 200);

// 监听
this.node.on("score-changed", (oldScore: number, newScore: number) => {
    cc.log(`分数: ${oldScore} → ${newScore}`);
});

// ⚠️ emit 最多支持传递 5 个参数
this.node.emit("custom-event", arg1, arg2, arg3, arg4, arg5);
```

### 节点事件冒泡（dispatchEvent）

```typescript
// 发射冒泡事件（从子节点向上传递给父节点）
const customEvent = new cc.Event.EventCustom("game-over", true); // true = 冒泡
customEvent.setUserData({ score: 100, level: 5 });
this.node.dispatchEvent(customEvent);

// 父节点监听
parentNode.on("game-over", (event: cc.Event.EventCustom) => {
    const data = event.getUserData();
    cc.log("游戏结束，分数:", data.score);

    // 可选：停止冒泡
    event.stopPropagation();
});
```

---

## 全局事件总线

### 使用 cc.EventTarget 实现全局事件

```typescript
// EventBus.ts - 全局事件总线（单例模式）
export const GameEvent = {
    SCORE_CHANGED: "score_changed",
    LEVEL_COMPLETE: "level_complete",
    PLAYER_DIED: "player_died",
    GAME_PAUSE: "game_pause",
    GAME_RESUME: "game_resume",
};

// 方法 1：简单的全局 EventTarget
export const eventBus = new cc.EventTarget();

// 方法 2：组件式事件管理器
const { ccclass } = cc._decorator;

@ccclass
export default class EventManager extends cc.Component {
    private static _instance: EventManager = null;
    private _eventTarget: cc.EventTarget = new cc.EventTarget();

    public static get instance(): EventManager {
        if (!EventManager._instance) {
            throw new Error("EventManager: 实例未初始化");
        }
        return EventManager._instance;
    }

    protected onLoad(): void {
        if (EventManager._instance) {
            this.node.destroy();
            return;
        }
        EventManager._instance = this;
        cc.game.addPersistRootNode(this.node); // 跨场景保留
    }

    protected onDestroy(): void {
        this._eventTarget.clear();
        EventManager._instance = null;
    }

    public static emit(event: string, ...args: any[]): void {
        EventManager.instance._eventTarget.emit(event, ...args);
    }

    public static on(event: string, callback: Function, target?: any): void {
        EventManager.instance._eventTarget.on(event, callback, target);
    }

    public static off(event: string, callback: Function, target?: any): void {
        EventManager.instance._eventTarget.off(event, callback, target);
    }

    public static once(event: string, callback: Function, target?: any): void {
        EventManager.instance._eventTarget.once(event, callback, target);
    }
}
```

### 使用全局事件总线

```typescript
import { GameEvent, eventBus } from "./EventBus";

@ccclass
export default class ScoreDisplay extends cc.Component {
    @property(cc.Label)
    public scoreLabel: cc.Label = null;

    protected onEnable(): void {
        // ✅ 在 onEnable 中注册
        eventBus.on(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);
    }

    protected onDisable(): void {
        // ✅ 在 onDisable 中注销
        eventBus.off(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);
    }

    private onScoreChanged(newScore: number): void {
        this.scoreLabel.string = `分数: ${newScore}`;
    }
}

// 其他组件中发射事件
eventBus.emit(GameEvent.SCORE_CHANGED, 1000);
```

---

## 事件清理规范

### ✅ 正确的事件注册/注销模式

```typescript
@ccclass
export default class ProperEventHandling extends cc.Component {
    // 规则：在哪里注册，就在配对的生命周期中注销

    // 模式 1：onEnable / onDisable 配对（推荐）
    protected onEnable(): void {
        this.node.on(cc.Node.EventType.TOUCH_START, this.onTouch, this);
        cc.systemEvent.on(cc.SystemEvent.EventType.KEY_DOWN, this.onKey, this);
        eventBus.on("custom-event", this.onCustom, this);
    }

    protected onDisable(): void {
        this.node.off(cc.Node.EventType.TOUCH_START, this.onTouch, this);
        cc.systemEvent.off(cc.SystemEvent.EventType.KEY_DOWN, this.onKey, this);
        eventBus.off("custom-event", this.onCustom, this);
    }

    // 模式 2：onLoad / onDestroy 配对（一次性注册）
    protected onLoad(): void {
        this.node.on("size-changed", this.onSizeChanged, this);
    }

    protected onDestroy(): void {
        this.node.off("size-changed", this.onSizeChanged, this);
        // 同时清理其他资源
        cc.Tween.stopAllByTarget(this.node);
        this.unscheduleAllCallbacks();
    }
}
```

### ❌ 常见事件泄漏

```typescript
// ❌ 错误 1：注册了但没注销
onLoad(): void {
    this.node.on("click", this.onClick, this);
    // 忘记在 onDestroy 中 off → 内存泄漏
}

// ❌ 错误 2：匿名函数无法注销
onLoad(): void {
    this.node.on("click", () => {
        // 匿名箭头函数无法被 off 移除！
    });
}

// ❌ 错误 3：注册/注销不配对
onEnable(): void {
    this.node.on("click", this.onClick, this);
}
onDestroy(): void {
    // 应该在 onDisable 中注销，不是 onDestroy
    this.node.off("click", this.onClick, this);
}
```

---

## 常见错误

### ❌ 不要

1. **使用匿名函数注册事件** → 无法注销，导致内存泄漏
2. **只在 onLoad 注册事件，不在 onDestroy 注销** → 内存泄漏
3. **onEnable 注册但在 onDestroy 注销** → 节点禁用时事件仍然活跃
4. **忘记 stopPropagation** → 冒泡事件传递到不需要的父节点
5. **emit 传递超过 5 个参数** → 超过的参数会被忽略
6. **全局事件不清理** → 场景切换时事件仍活跃

### ✅ 要做

1. **具名函数 + this 作为 target** → `this.node.on("event", this.handler, this)`
2. **onEnable/onDisable 配对** → 最安全的事件注册模式
3. **冒泡事件用 dispatchEvent** → 非冒泡用 emit
4. **全局事件使用 cc.EventTarget** → 统一事件管理
5. **复杂数据用 setUserData** → 而不是多个参数
