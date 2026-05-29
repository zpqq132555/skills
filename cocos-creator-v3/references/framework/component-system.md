# 组件系统详解 — Cocos Creator 3.8

> 📖 本文件为 `cocos-creator-3x-cn` 技能参考文件，提供组件系统、装饰器、生命周期的深入指导。

---

## 1. 组件基础架构

### 1.1 cc 类注册

所有需要被引擎序列化、在编辑器中展示的类都必须使用 `@ccclass` 装饰器注册：

```typescript
import { _decorator, Component } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('UniqueClassName') // 全局唯一的 cc 类名
export class UniqueClassName extends Component {
    // ...
}
```

**规则**:
- cc 类名 **全局唯一**，不同目录下的同名类也不允许
- 类名不应以 `cc.` 或 `internal.` 作为前缀（引擎保留前缀）
- 未声明 `@ccclass` 的类无法作为组件添加到节点上

### 1.2 组件获取与操作

```typescript
// 获取组件
const sprite = this.node.getComponent(Sprite);           // 单个
const sprites = this.node.getComponentsInChildren(Sprite); // 递归子节点
const label = this.getComponent(Label);                   // 同节点上

// 添加/移除组件
const comp = this.node.addComponent(MyComponent);
this.node.removeComponent(comp);

// 通过 cc 类名获取
const comp = this.node.getComponent('MyComponent');
```

---

## 2. 装饰器详解

### 2.1 属性装饰器 @property

完整参数列表：

```typescript
@property({
    type: Node,           // cc 类型
    visible: true,        // 是否在检查器显示
    displayName: '目标',  // 显示名
    tooltip: '提示文字',  // 悬浮提示
    serializable: true,   // 是否序列化
    readonly: false,      // 只读
    min: 0,              // 最小值
    max: 100,            // 最大值
    step: 1,             // 步长
    range: [0, 100, 1],  // 范围快捷设置
    slide: false,        // 滑动条
    multiline: false,    // 多行文本
    formerlySerializedAs: 'oldName', // 兼容旧字段名
    editorOnly: false,   // 仅编辑器
    override: false,     // 覆盖父类同名属性
    group: { name: '分组名', id: 'default', displayOrder: 0, style: 'tab' },
})
```

### 2.2 类型声明模式

```typescript
import { _decorator, Component, Node, CCInteger, CCFloat, CCString, CCBoolean, Enum } from 'cc';
const { ccclass, property, integer, float, type } = _decorator;

enum Direction { Up, Down, Left, Right }
Enum(Direction);

@ccclass('TypeExample')
export class TypeExample extends Component {
    // 自动推导类型
    @property
    private readonly speed = 10;                    // → CCFloat

    @property
    private readonly name = 'player';               // → CCString

    @property
    private readonly active = true;                 // → CCBoolean

    // 显式指定 cc 类型
    @property(Node)
    private readonly target: Node | null = null;    // 等价于 @property({type: Node})

    // 数组类型
    @property({ type: [Node] })
    private readonly children: Node[] = [];

    // 整数简写
    @integer
    private readonly count = 0;

    // 浮点简写
    @float
    private readonly ratio = 1.0;

    // 枚举类型
    @property({ type: Direction })
    private readonly dir: Direction = Direction.Up;

    // 基础类型数组
    @property({ type: [CCInteger] })
    private readonly scores: number[] = [];

    // 以 _ 开头：序列化但不显示在面板
    @property
    private readonly _cachedValue = '';
}
```

### 2.3 组件类装饰器

```typescript
const { ccclass, executeInEditMode, requireComponent, executionOrder, disallowMultiple, menu, help } = _decorator;

@ccclass('AdvancedComponent')
@executeInEditMode(true)           // 编辑器模式下也执行生命周期
@requireComponent(Sprite)          // 自动添加依赖组件
@executionOrder(-1)                // 优先执行（数值越小越先）
@disallowMultiple(true)            // 同一节点禁止重复添加
@menu('Custom/Advanced')           // 组件菜单路径
@help('https://docs.example.com')  // 帮助文档 URL
export class AdvancedComponent extends Component {
    // ...
}
```

**executionOrder 规则**:
- 小于 0 → 优先执行
- 等于 0 → 默认
- 大于 0 → 最后执行
- 仅影响 `onLoad`、`onEnable`、`start`、`update`、`lateUpdate`
- 对 `onDisable` 和 `onDestroy` 无效

---

## 3. 生命周期详解

### 3.1 完整生命周期流程

```
┌──────────────────────────────────────────────────────┐
│                   初始化阶段                          │
│  ┌─────────┐                                        │
│  │ onLoad  │ ← 节点首次激活（只调用一次）              │
│  └────┬────┘                                        │
│       ▼                                             │
│  ┌──────────┐                                       │
│  │ onEnable │ ← 组件每次启用                         │
│  └────┬─────┘                                       │
│       ▼                                             │
│  ┌─────────┐                                        │
│  │  start  │ ← 首次 update 前（只调用一次）           │
│  └────┬────┘                                        │
├───────┼──────────────────────────────────────────────┤
│       ▼           游戏循环                           │
│  ┌─────────┐                                        │
│  │ update  │ ← 每帧调用                              │
│  └────┬────┘                                        │
│       ▼                                             │
│  ┌────────────┐                                     │
│  │ lateUpdate │ ← 所有 update 执行完后                │
│  └────────────┘                                     │
├──────────────────────────────────────────────────────┤
│                   销毁阶段                           │
│  ┌───────────┐                                      │
│  │ onDisable │ ← 组件每次禁用                        │
│  └────┬──────┘                                      │
│       ▼                                             │
│  ┌─────────────┐                                    │
│  │  onDestroy  │ ← 节点销毁前                        │
│  └─────────────┘                                    │
└──────────────────────────────────────────────────────┘
```

### 3.2 各回调最佳实践

```typescript
@ccclass('LifecycleDemo')
export class LifecycleDemo extends Component {
    private _pool: NodePool | null = null;

    /**
     * onLoad: 初始化引用、设置常量
     * - 此时节点已挂载到节点树
     * - 可安全获取其他组件引用
     * - 不要在此处理依赖其他组件 onLoad 完成的逻辑
     */
    protected onLoad(): void {
        this._pool = new NodePool('Bullet');
    }

    /**
     * onEnable: 注册事件监听
     * - 与 onDisable 配对
     * - 可能被多次调用
     */
    protected onEnable(): void {
        input.on(Input.EventType.TOUCH_START, this.onTouch, this);
        this.node.on(Node.EventType.TOUCH_START, this.onNodeTouch, this);
    }

    /**
     * start: 依赖初始化
     * - 可确保同场景所有组件的 onLoad 已完成
     * - 只调用一次
     */
    protected start(): void {
        const otherComp = find('Canvas/Manager')?.getComponent(GameManager);
        // 安全使用 otherComp
    }

    /**
     * update: 每帧逻辑
     * - dt 为上一帧耗时（秒）
     */
    protected update(dt: number): void {
        this.node.angle += this.rotateSpeed * dt;
    }

    /**
     * lateUpdate: 后处理
     * - 在所有 update 之后
     * - 适合相机跟随、最终位置调整
     */
    protected lateUpdate(dt: number): void {
        // 相机跟随逻辑
    }

    /**
     * onDisable: 注销事件监听
     * - 与 onEnable 配对
     */
    protected onDisable(): void {
        input.off(Input.EventType.TOUCH_START, this.onTouch, this);
        this.node.off(Node.EventType.TOUCH_START, this.onNodeTouch, this);
    }

    /**
     * onDestroy: 清理资源
     * - 释放动态加载的资源
     * - 清理对象池
     */
    protected onDestroy(): void {
        this._pool?.clear();
        this._pool = null;
    }
}
```

---

## 4. 节点操作

### 4.1 节点创建与销毁

```typescript
import { instantiate, Prefab, Node, director } from 'cc';

// 从 Prefab 实例化
resources.load('prefabs/bullet', Prefab, (err, prefab) => {
    const bullet = instantiate(prefab);
    this.node.addChild(bullet);
    bullet.setPosition(0, 0, 0);
});

// 销毁节点（延迟到当帧末尾执行）
bullet.destroy();

// 仅从父节点移除（不销毁）
bullet.removeFromParent();
```

### 4.2 节点层级操作

```typescript
// 设置父节点
node.parent = targetParent;
node.setParent(targetParent);

// 排序
node.setSiblingIndex(0); // 移到兄弟节点最前

// 激活/禁用
node.active = false; // 会触发 onDisable
node.active = true;  // 会触发 onEnable

// 遍历子节点
this.node.children.forEach(child => { /* ... */ });
```

### 4.3 坐标系转换

```typescript
import { Vec3, UITransform } from 'cc';

// 世界坐标 ↔ 本地坐标
const worldPos = this.node.worldPosition;
const localPos = parent.getComponent(UITransform)!
    .convertToNodeSpaceAR(worldPos);

// 屏幕坐标 → UI 坐标
const uiPos = event.getUILocation(); // 在触摸事件中使用
```

---

## 5. 定时器与调度

```typescript
// schedule: 重复调度
this.schedule(this.tick, 1.0);          // 每秒
this.schedule(this.tick, 0.5, 10, 2);   // 延迟2秒，每0.5秒，共10次

// scheduleOnce: 延迟调用一次
this.scheduleOnce(() => {
    console.log('delayed');
}, 2.0);

// 取消调度
this.unschedule(this.tick);
this.unscheduleAllCallbacks();
```

---

## 6. 常见反模式

| 反模式 | 问题 | 修正 |
|--------|------|------|
| 在 `onLoad` 中访问其他组件的 `start` 才初始化的数据 | 数据可能为空 | 移到 `start` 或添加 null 检查 |
| 在 `onEnable` 注册事件但不在 `onDisable` 取消 | 事件泄漏 | 配对使用 `on`/`off` |
| 在 `update` 中创建大量临时对象 | GC 压力 | 使用类字段缓存临时变量 |
| 使用字符串注册事件类型 | 易拼写错误 | 使用 `Node.EventType.TOUCH_START` 枚举 |
| `@property` 类型不写 `| null` | 运行时空指针 | 使用 `Type \| null = null` 或 `Type = null!` |
