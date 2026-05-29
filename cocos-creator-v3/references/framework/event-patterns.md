# 事件系统模式 — Cocos Creator 3.8

> 📖 本文件为 `cocos-creator-3x-cn` 技能参考文件，提供事件系统的深入指导。

---

## 1. 事件系统架构

Cocos Creator 3.8 事件系统由三层构成：

| 层级 | 入口对象 | 说明 |
|------|---------|------|
| 全局输入事件 | `input` | 键盘/鼠标/触摸/重力，与节点树无关 |
| 节点事件 | `node.on(...)` | UI 触摸/鼠标，与 UI 节点树关联 |
| 自定义事件 | `EventTarget` | 游戏逻辑事件总线 |

---

## 2. 全局输入事件 (input)

### 2.1 完整 API

```typescript
import { input, Input, EventTouch, EventMouse, EventKeyboard, EventAcceleration, KeyCode } from 'cc';

// 注册（在 onEnable）
input.on(Input.EventType.TOUCH_START, this.onTouchStart, this);
input.on(Input.EventType.KEY_DOWN, this.onKeyDown, this);

// 注销（在 onDisable）
input.off(Input.EventType.TOUCH_START, this.onTouchStart, this);
input.off(Input.EventType.KEY_DOWN, this.onKeyDown, this);
```

### 2.2 触摸事件

```typescript
private onTouchStart(event: EventTouch): void {
    const screenPos = event.getLocation();       // Vec2 屏幕坐标
    const uiPos = event.getUILocation();         // Vec2 UI 坐标
    const delta = event.getDelta();              // Vec2 位移
    const touch = event.touch!;                  // Touch 对象
    const touchId = touch.getID();               // 触点 ID（多点触控）
}
```

**事件类型**:
- `TOUCH_START` — 手指按下
- `TOUCH_MOVE` — 手指移动
- `TOUCH_END` — 手指在节点区域内抬起
- `TOUCH_CANCEL` — 手指在节点区域外抬起

### 2.3 键盘事件

```typescript
private onKeyDown(event: EventKeyboard): void {
    switch (event.keyCode) {
        case KeyCode.KEY_W:
        case KeyCode.ARROW_UP:
            this.moveUp();
            break;
        case KeyCode.SPACE:
            this.jump();
            break;
        case KeyCode.ESCAPE:
            this.pause();
            break;
    }
}
```

**事件类型**:
- `KEY_DOWN` — 键按下
- `KEY_PRESSING` — 键持续按下
- `KEY_UP` — 键释放

### 2.4 鼠标事件

```typescript
import { EventMouse } from 'cc';

private onMouseWheel(event: EventMouse): void {
    const scrollY = event.getScrollY();
    // 缩放逻辑
}
```

**事件类型**: `MOUSE_DOWN`, `MOUSE_MOVE`, `MOUSE_UP`, `MOUSE_WHEEL`

### 2.5 重力传感

```typescript
protected onLoad(): void {
    input.setAccelerometerEnabled(true);
    input.on(Input.EventType.DEVICEMOTION, this.onDeviceMotion, this);
}

private onDeviceMotion(event: EventAcceleration): void {
    console.log(event.acc.x, event.acc.y, event.acc.z);
}
```

---

## 3. 节点事件

### 3.1 UI 节点触摸

2D UI 节点触摸事件依赖 `UITransform` 组件：

```typescript
import { _decorator, Component, Node, EventTouch } from 'cc';

@ccclass('NodeEventDemo')
export class NodeEventDemo extends Component {
    protected onEnable(): void {
        this.node.on(Node.EventType.TOUCH_START, this.onTouchStart, this);
        this.node.on(Node.EventType.TOUCH_MOVE, this.onTouchMove, this);
        this.node.on(Node.EventType.TOUCH_END, this.onTouchEnd, this);
        this.node.on(Node.EventType.TOUCH_CANCEL, this.onTouchCancel, this);
    }

    protected onDisable(): void {
        this.node.off(Node.EventType.TOUCH_START, this.onTouchStart, this);
        this.node.off(Node.EventType.TOUCH_MOVE, this.onTouchMove, this);
        this.node.off(Node.EventType.TOUCH_END, this.onTouchEnd, this);
        this.node.off(Node.EventType.TOUCH_CANCEL, this.onTouchCancel, this);
    }

    private onTouchStart(event: EventTouch): void {
        // event.getUILocation() — UI 坐标
        // event.propagationStopped = true — 阻止冒泡
    }
}
```

### 3.2 事件传递机制

节点事件遵循 Web 标准的事件传递：

```
捕获阶段: Scene Root → ... → Parent → Target
目标阶段: Target
冒泡阶段: Target → Parent → ... → Scene Root
```

```typescript
// 默认在冒泡阶段监听
this.node.on(Node.EventType.TOUCH_START, callback, this);

// 在捕获阶段监听（第四个参数为 true）
this.node.on(Node.EventType.TOUCH_START, callback, this, true);

// 阻止冒泡
private onTouchStart(event: EventTouch): void {
    event.propagationStopped = true;
}

// 立即停止（连同一节点上的其他监听器也不触发）
private onTouchStart2(event: EventTouch): void {
    event.propagationImmediateStopped = true;
}
```

### 3.3 事件穿透 (v3.4+)

```typescript
// 默认情况下，同级节点中顶层节点会吞噬事件
// 使用 preventSwallow 允许事件穿透到下层同级节点
private onTouchStart(event: EventTouch): void {
    event.preventSwallow = true;
}
```

**注意**: TOUCH_END 穿透需要对应的 TOUCH_START 也设置穿透。

### 3.4 事件拦截

`Button`、`Toggle`、`BlockInputEvents` 组件会自动阻止事件冒泡：

```typescript
// 如果不需要按钮组件，但需要拦截事件：
// 添加 BlockInputEvents 组件到节点
```

### 3.5 节点系统事件

```typescript
// 变换
this.node.on(Node.EventType.TRANSFORM_CHANGED, (type: TransformBit) => {
    if (type & TransformBit.POSITION) { /* 位置改变 */ }
    if (type & TransformBit.ROTATION) { /* 旋转改变 */ }
    if (type & TransformBit.SCALE) { /* 缩放改变 */ }
});

// 2D 节点事件
this.node.on(Node.EventType.SIZE_CHANGED, () => { /* UITransform 尺寸变化 */ });
this.node.on(Node.EventType.ANCHOR_CHANGED, () => { /* 锚点变化 */ });
this.node.on(Node.EventType.CHILD_ADDED, (child: Node) => { /* 添加子节点 */ });
this.node.on(Node.EventType.CHILD_REMOVED, (child: Node) => { /* 移除子节点 */ });
this.node.on(Node.EventType.ACTIVE_IN_HIERARCHY_CHANGED, () => { /* 激活状态变化 */ });
```

### 3.6 暂停/恢复节点事件

```typescript
// 暂停当前节点的系统事件
this.node.pauseSystemEvents();
// 暂停当前节点和所有子节点的系统事件
this.node.pauseSystemEvents(true);

// 恢复
this.node.resumeSystemEvents();
this.node.resumeSystemEvents(true);
```

---

## 4. 自定义事件 (EventTarget)

### 4.1 基础用法

```typescript
import { EventTarget } from 'cc';

// 创建事件总线（推荐单例模式）
class GameEvents {
    private static _instance: EventTarget;
    public static get instance(): EventTarget {
        if (!this._instance) {
            this._instance = new EventTarget();
        }
        return this._instance;
    }
}

// 监听
GameEvents.instance.on('score-changed', (score: number) => {
    console.log('Score:', score);
});

// 发射
GameEvents.instance.emit('score-changed', 100);

// 一次性监听
GameEvents.instance.once('game-start', () => { /* 只触发一次 */ });

// 取消监听
GameEvents.instance.off('score-changed', callback, target);
// 取消该类型所有监听
GameEvents.instance.off('score-changed');
```

**⚠️ 限制**: `emit` 最多支持 5 个参数。

### 4.2 类型安全的事件系统

```typescript
// 定义事件类型映射
interface GameEventMap {
    'game-start': () => void;
    'game-over': (score: number, isWin: boolean) => void;
    'level-up': (level: number) => void;
}

// 类型安全的事件总线封装
class TypedEventTarget {
    private _et = new EventTarget();

    public on<K extends keyof GameEventMap>(type: K, callback: GameEventMap[K], target?: any): void {
        this._et.on(type, callback as any, target);
    }

    public off<K extends keyof GameEventMap>(type: K, callback: GameEventMap[K], target?: any): void {
        this._et.off(type, callback as any, target);
    }

    public emit<K extends keyof GameEventMap>(type: K, ...args: Parameters<GameEventMap[K]>): void {
        this._et.emit(type, ...args);
    }
}
```

### 4.3 节点自定义事件派发

```typescript
import { Event } from 'cc';

// 自定义事件类（不要直接 new Event，它是抽象类）
class DamageEvent extends Event {
    public readonly damage: number;
    constructor(damage: number, bubbles = true) {
        super('damage', bubbles);
        this.damage = damage;
    }
}

// 派发（支持冒泡）
this.node.dispatchEvent(new DamageEvent(50));

// 父节点监听
parentNode.on('damage', (event: DamageEvent) => {
    console.log('Damage:', event.damage);
    event.propagationStopped = true; // 可选：阻止继续冒泡
});
```

---

## 5. 3D 物体触摸检测

```typescript
import { _decorator, Component, Camera, geometry, input, Input, EventTouch, PhysicsSystem, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('RaycastTouch')
export class RaycastTouch extends Component {
    @property(Camera)
    private readonly cameraCom!: Camera;

    @property(Node)
    private readonly targetNode!: Node;

    private _ray = new geometry.Ray();

    protected onEnable(): void {
        input.on(Input.EventType.TOUCH_START, this.onTouchStart, this);
    }

    protected onDisable(): void {
        input.off(Input.EventType.TOUCH_START, this.onTouchStart, this);
    }

    private onTouchStart(event: EventTouch): void {
        const touch = event.touch!;
        this.cameraCom.screenPointToRay(touch.getLocationX(), touch.getLocationY(), this._ray);
        if (PhysicsSystem.instance.raycast(this._ray)) {
            const results = PhysicsSystem.instance.raycastResults;
            for (const result of results) {
                if (result.collider.node === this.targetNode) {
                    console.log('Hit target!');
                    break;
                }
            }
        }
    }
}
```

---

## 6. 多点触控控制

```typescript
import { macro } from 'cc';

// 关闭多点触控（项目全局设置）
macro.ENABLE_MULTI_TOUCH = false;

// 也可以在菜单中设置：项目 → 项目设置 → Macro Config
```

---

## 7. 最佳实践

### 事件监听配对原则

```typescript
// ✅ 正确：onEnable / onDisable 配对
protected onEnable(): void {
    input.on(Input.EventType.TOUCH_START, this.onTouch, this);
    this.node.on(Node.EventType.TOUCH_START, this.onNodeTouch, this);
}
protected onDisable(): void {
    input.off(Input.EventType.TOUCH_START, this.onTouch, this);
    this.node.off(Node.EventType.TOUCH_START, this.onNodeTouch, this);
}

// ❌ 错误：只注册不注销 → 事件泄漏
protected onLoad(): void {
    input.on(Input.EventType.TOUCH_START, this.onTouch, this);
}
```

### 使用枚举而非字符串

```typescript
// ✅ 正确
this.node.on(Node.EventType.TOUCH_START, callback, this);
input.on(Input.EventType.KEY_DOWN, callback, this);

// ❌ 不推荐
this.node.on('touch-start', callback, this);
```

### 避免在回调中创建闭包

```typescript
// ✅ 正确：使用方法引用
protected onEnable(): void {
    input.on(Input.EventType.TOUCH_START, this.onTouch, this);
}
private onTouch(event: EventTouch): void { /* ... */ }

// ❌ 不推荐：匿名函数无法取消监听
protected onEnable2(): void {
    input.on(Input.EventType.TOUCH_START, (e) => { /* ... */ });
}
```
