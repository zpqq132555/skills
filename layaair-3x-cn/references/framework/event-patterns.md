# 事件模式 — LayaAir 3.x

> 📖 LayaAir 3.x 基于 `EventDispatcher` 事件系统，所有 `Sprite`、`Script`、`Node`、`Stage` 均继承自 `EventDispatcher`。

---

## 1. 事件系统基础

### 注册与注销模式

```typescript
const { regClass, property } = Laya;

@regClass()
export class PlayerScript extends Laya.Script {
    onEnable(): void {
        // ✅ 注册事件（与 onDisable 配对）
        this.owner.on(Laya.Event.CLICK, this, this.onClick);
        Laya.stage.on(Laya.Event.RESIZE, this, this.onResize);
    }

    onDisable(): void {
        // ✅ 注销事件（必须与 onEnable 配对）
        this.owner.off(Laya.Event.CLICK, this, this.onClick);
        Laya.stage.off(Laya.Event.RESIZE, this, this.onResize);
    }

    private onClick(evt: Laya.Event): void {
        console.log("clicked at:", evt.stageX, evt.stageY);
    }

    private onResize(): void {
        // 处理尺寸变化
    }
}
```

### EventDispatcher API

| 方法 | 说明 |
|------|------|
| `node.on(type, caller, fn)` | 持续监听 |
| `node.once(type, caller, fn)` | 只触发一次后自动注销 |
| `node.off(type, caller, fn)` | 注销指定监听 |
| `node.offAll(type)` | 注销该类型所有监听 |
| `node.offAllCaller(caller)` | **3.x 新增**：注销指定 caller 的所有事件 |
| `node.hasListener(type)` | 是否有该类监听 |
| `node.event(type, data?)` | 派发事件 |

```typescript
// 3.x 新增便捷 API：注销 caller 所有事件
onDestroy(): void {
    this.owner.offAllCaller(this);  // 一次清除所有监听
}
```

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
| `Laya.Event.MOUSE_WHEEL` | 鼠标滚轮 |
| `Laya.Event.RIGHT_CLICK` | 右键点击 |
| `Laya.Event.RIGHT_MOUSE_DOWN` | 右键按下 |

### 触摸事件

| 常量 | 说明 |
|------|------|
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
| `Laya.Event.KEY_DOWN` | 键盘按下 |
| `Laya.Event.KEY_UP` | 键盘抬起 |
| `Laya.Event.KEY_PRESS` | 键盘输入 |

---

## 3. 触摸/鼠标事件详解

```typescript
// Event 对象属性
node.on(Laya.Event.MOUSE_DOWN, this, (evt: Laya.Event) => {
    evt.stageX;          // 舞台 X 坐标
    evt.stageY;          // 舞台 Y 坐标
    evt.target;          // 事件原始目标节点
    evt.currentTarget;   // 当前处理节点
    evt.touchId;         // 触摸 ID（多点触控）

    evt.stopPropagation(); // 阻止冒泡
});

// 多点触摸
Laya.stage.on(Laya.Event.TOUCH_BEGIN, this, (evt: Laya.Event) => {
    const touches = evt.touches;
    for (const touch of touches) {
        console.log(touch.stageX, touch.stageY);
    }
});
```

---

## 4. 自定义事件

```typescript
// 方式一：直接使用 event + on
@regClass()
export class ClickHandler extends Laya.Script {
    onAwake(): void {
        this.owner.on("gameOver", this, (score: number) => {
            console.log("Game Over! Score:", score);
        });
    }

    onMouseClick(evt: Laya.Event): void {
        this.owner.event("gameOver", 100);
    }
}

// 方式二：全局事件总线（通过 Stage 或自定义 EventDispatcher）
const EventBus = new Laya.EventDispatcher();

// 发送
EventBus.event("levelComplete", { level: 5, score: 1000 });

// 监听
EventBus.on("levelComplete", this, (data: { level: number; score: number }) => {
    console.log(`完成关卡 ${data.level}，得分 ${data.score}`);
});

// 注销
EventBus.off("levelComplete", this);
```

---

## 5. Handler（回调封装）

```typescript
// 创建一次性 Handler（执行后自动回收，默认行为）
Laya.Handler.create(caller, callback, args);

// 创建持久 Handler（不自动回收，需手动 recover）
Laya.Handler.create(caller, callback, args, false);
```

> **3.x 注意**：资源加载推荐使用 Promise（`.then()`），Handler 仍可用但非首选。

---

## 6. 脚本内置事件方法 vs 手动注册

LayaAir 3.x Script 提供内置事件方法，无需手动调用 `on/off`：

```typescript
@regClass()
export class GameScript extends Laya.Script {
    // ✅ 内置方法：自动绑定到 owner 节点
    onMouseClick(evt: Laya.Event): void {
        console.log("被点击了");
    }

    onKeyDown(evt: Laya.Event): void {
        if (evt.keyCode === Laya.Keyboard.SPACE) {
            this.jump();
        }
    }
}

// ❌ 不需要手动注册
// this.owner.on(Laya.Event.CLICK, this, this.onMouseClick); // 不需要
```

**何时用手动注册**：监听非 owner 节点的事件、全局事件（Stage）、自定义事件总线。

---

## 7. 事件最佳实践

### ✅ 推荐做法
```typescript
// 1. on/off 配对，在 onEnable/onDisable 中做
onEnable(): void {
    Laya.stage.on("scoreChanged", this, this.onScoreChanged);
}
onDisable(): void {
    Laya.stage.off("scoreChanged", this, this.onScoreChanged);
}

// 2. 销毁时使用 offAllCaller 兜底
onDestroy(): void {
    Laya.stage.offAllCaller(this);
}

// 3. 一次性事件用 once
node.once(Laya.Event.COMPLETE, this, () => { });
```

### ❌ 常见错误
```typescript
// 1. 忘记注销事件 → 内存泄漏
onEnable(): void {
    node.on(Laya.Event.CLICK, this, this.onClick);
}
// 缺少 onDisable 中的 off!

// 2. 在 onUpdate 中注册事件 → 重复注册
onUpdate(): void {
    this.owner.on(Laya.Event.CLICK, this, this.onClick); // ❌ 每帧注册一次！
}

// 3. 箭头函数无法正确 off
onEnable(): void {
    node.on("evt", this, () => { }); // ❌ 匿名函数无法注销
}
```
