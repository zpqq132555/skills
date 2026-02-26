# 事件模式 — LayaAir 1.0

> 📖 LayaAir 1.0 基于 `EventDispatcher` 事件系统。`Sprite`、`Stage`、`Loader` 等所有可监听对象均继承自 `EventDispatcher`。

---

## 1. 事件基础用法

```typescript
// 加事件监听
node.on(Laya.Event.CLICK, this, this.onClick);
node.once(Laya.Event.CLICK, this, this.onClick); // 触发一次后自动注销

// 注销事件
node.off(Laya.Event.CLICK, this, this.onClick);
node.offAll(Laya.Event.CLICK);  // 注销该事件所有监听

// 触发自定义事件
node.event("game-over", [score]);
// 或通过 EventDispatcher
(node as Laya.EventDispatcher).event("game-input", [key, value]);
```

### 注意：注册注销必须同一函数引用

```typescript
// ❌ 匿名函数无法注销！
node.on(Laya.Event.CLICK, this, () => { this.doSomething(); });
// 后面无法 off 这个匿名函数

// ✅ 使用命名方法
node.on(Laya.Event.CLICK, this, this.doSomething);
node.off(Laya.Event.CLICK, this, this.doSomething);
```

---

## 2. Laya.Event 常用常量

### 鼠标/触摸事件

| 常量 | 说明 |
|------|------|
| `Laya.Event.CLICK` | 点击 |
| `Laya.Event.MOUSE_DOWN` | 按下 |
| `Laya.Event.MOUSE_UP` | 抬起 |
| `Laya.Event.MOUSE_MOVE` | 移动 |
| `Laya.Event.MOUSE_OVER` | 悬浮进入 |
| `Laya.Event.MOUSE_OUT` | 悬浮离开 |
| `Laya.Event.TOUCH_BEGIN` | 触摸开始 |
| `Laya.Event.TOUCH_MOVE` | 触摸移动 |
| `Laya.Event.TOUCH_END` | 触摸结束 |

### 系统事件

| 常量 | 说明 |
|------|------|
| `Laya.Event.CHANGE` | 值改变 |
| `Laya.Event.COMPLETE` | 完成（加载/动画） |
| `Laya.Event.PROGRESS` | 进度更新 |
| `Laya.Event.ERROR` | 错误 |
| `Laya.Event.RESIZE` | 舞台缩放 |
| `Laya.Event.BLUR` | 失去焦点 |
| `Laya.Event.FOCUS` | 获得焦点 |

---

## 3. 触摸/鼠标事件

```typescript
// 鼠标位置
Laya.stage.mouseX;   // 舞台坐标 X（实时）
Laya.stage.mouseY;   // 舞台坐标 Y（实时）

// 事件回调中的 Event 对象
node.on(Laya.Event.MOUSE_DOWN, this, (e: Laya.Event) => {
    console.log(e.stageX, e.stageY);   // 舞台坐标
    console.log(e.localX, e.localY);   // 局部坐标
    console.log(e.target);             // 触发事件的节点
    e.stopPropagation();               // 阻止冒泡
});

// 开启节点交互（必须设置！默认 false）
node.mouseEnabled = true;
```

### 拖拽示例

```typescript
class DraggableSprite extends Laya.Sprite {
    private _offsetX: number = 0;
    private _offsetY: number = 0;

    constructor() {
        super();
        this.mouseEnabled = true;
        this.on(Laya.Event.MOUSE_DOWN, this, this.onDown);
    }

    private onDown(e: Laya.Event): void {
        this._offsetX = Laya.stage.mouseX - this.x;
        this._offsetY = Laya.stage.mouseY - this.y;
        Laya.stage.on(Laya.Event.MOUSE_MOVE, this, this.onMove);
        Laya.stage.on(Laya.Event.MOUSE_UP, this, this.onUp);
    }

    private onMove(): void {
        this.x = Laya.stage.mouseX - this._offsetX;
        this.y = Laya.stage.mouseY - this._offsetY;
    }

    private onUp(): void {
        Laya.stage.off(Laya.Event.MOUSE_MOVE, this, this.onMove);
        Laya.stage.off(Laya.Event.MOUSE_UP, this, this.onUp);
    }

    public destroy(destroyChild: boolean = true): void {
        this.offAll(); // 清除所有事件
        Laya.stage.off(Laya.Event.MOUSE_MOVE, this, this.onMove);
        Laya.stage.off(Laya.Event.MOUSE_UP, this, this.onUp);
        super.destroy(destroyChild);
    }
}
```

---

## 4. 自定义事件

### 方案 A：节点自定义事件

```typescript
// 派发（第二个参数为数组，会展开为回调参数）
playerSprite.event("player-dead", [player, score]);

// 监听（需要 playerSprite 的引用）
playerSprite.on("player-dead", this, (player: Laya.Sprite, score: number) => {
    this.onPlayerDead(player, score);
});
```

### 方案 B：全局事件总线（单例）

```typescript
// EventBus.ts
class EventBus {
    private static _bus: Laya.EventDispatcher;

    public static get inst(): Laya.EventDispatcher {
        if (!EventBus._bus) {
            EventBus._bus = new Laya.EventDispatcher();
        }
        return EventBus._bus;
    }
}

// 发布
EventBus.inst.event("SCORE_UPDATE", [currentScore]);

// 订阅（在构造函数或初始化时）
EventBus.inst.on("SCORE_UPDATE", this, this.onScoreUpdate);

// 取消订阅（在 destroy 中！！！）
EventBus.inst.off("SCORE_UPDATE", this, this.onScoreUpdate);
```

### 方案 C：事件名常量（避免字符串错误）

```typescript
const GameEvent = {
    SCORE:     "SCORE",
    GAME_OVER: "GAME_OVER",
    LEVEL_UP:  "LEVEL_UP",
    PAUSE:     "PAUSE",
    RESUME:    "RESUME",
} as const;

// 使用
EventBus.inst.on(GameEvent.GAME_OVER, this, this.onGameOver);
EventBus.inst.event(GameEvent.GAME_OVER, [finalScore]);
```

---

## 5. 键盘事件（1.0）

```typescript
// 在 stage 上注册键盘事件
Laya.stage.on(Laya.Event.KEY_DOWN, this, this.onKeyDown);
Laya.stage.on(Laya.Event.KEY_UP,   this, this.onKeyUp);

private onKeyDown(e: Laya.Event): void {
    const key = e.keyCode;
    if (key === 37) { /* 左方向键 */ }
    if (key === 39) { /* 右方向键 */ }
    if (key === 32) { /* 空格 */ }
}

// 在销毁时注销
public destroy(): void {
    Laya.stage.off(Laya.Event.KEY_DOWN, this, this.onKeyDown);
    Laya.stage.off(Laya.Event.KEY_UP,   this, this.onKeyUp);
    Laya.timer.clearAll(this);
    super.destroy();
}

// 常用 keyCode
// 37=Left, 38=Up, 39=Right, 40=Down
// 32=Space, 13=Enter, 27=Escape
// A-Z = 65-90, 0-9 = 48-57
```

---

## 6. 加载事件

```typescript
// 加载进度
Laya.loader.load(assets,
    Laya.Handler.create(this, this.onComplete),
    Laya.Handler.create(this, this.onProgress, null, false)); // false=不自动销毁

private onProgress(progress: number): void {
    // 0 ~ 1
    this.progressBar.value = progress * 100;
}

private onComplete(): void {
    // 全部加载完成
}

// 单个资源加载事件
Laya.loader.load("res/big.json",
    Laya.Handler.create(this, (data: any) => { }));
```

---

## 7. 事件泄漏防护

```typescript
// 继承 Sprite 的类必须重写 destroy
class MyView extends Laya.Sprite {
    constructor() {
        super();
        // 注册各种事件
        this.on(Laya.Event.CLICK, this, this.onClick);
        Laya.stage.on(Laya.Event.RESIZE, this, this.onResize);
        EventBus.inst.on("GAME_OVER", this, this.onGameOver);
        Laya.timer.loop(1000, this, this.onTick);
    }

    public destroy(destroyChild: boolean = true): void {
        // 注销所有事件
        this.off(Laya.Event.CLICK, this, this.onClick);
        Laya.stage.off(Laya.Event.RESIZE, this, this.onResize);
        EventBus.inst.off("GAME_OVER", this, this.onGameOver);
        // 清理定时器
        Laya.timer.clearAll(this);
        super.destroy(destroyChild);
    }
}
```
