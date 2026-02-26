# Cocos Creator 架构审查

本审查关注 Cocos Creator 特定的架构问题，包括组件生命周期违规、事件管理问题以及可试玩广告特有的性能问题。

## 组件生命周期违规

### 在 onLoad 中访问组件

```typescript
// ❌ 严重：在 onLoad 中访问其他组件
@ccclass('BadLifecycle')
export class BadLifecycle extends Component {
    @property(Node)
    private playerNode: Node | null = null;

    protected onLoad(): void {
        // 错误：其他组件可能尚未加载
        const controller = this.playerNode!.getComponent(PlayerController);
        controller.initialize(); // 可能为 undefined！
    }
}

// ✅ 正确：在 start() 中访问组件
@ccclass('GoodLifecycle')
export class GoodLifecycle extends Component {
    @property(Node)
    private readonly playerNode: Node | null = null;

    private playerController!: PlayerController;

    protected onLoad(): void {
        if (!this.playerNode) {
            throw new Error('GoodLifecycle: playerNode 是必需的');
        }
    }

    protected start(): void {
        const controller = this.playerNode!.getComponent(PlayerController);
        if (!controller) {
            throw new Error('未找到 PlayerController');
        }
        this.playerController = controller;
        this.playerController.initialize();
    }
}

// 严重级别：🔴 严重
// 影响：未定义行为、崩溃
// 修复：将组件访问从 onLoad() 移到 start()
```

### 事件监听器内存泄漏

```typescript
// ❌ 严重：未注销事件监听器
@ccclass('EventLeakBad')
export class EventLeakBad extends Component {
    protected onEnable(): void {
        this.node.on(Node.EventType.TOUCH_START, this.onTouchStart, this);
        EventManager.on(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);
    }

    // 缺少：onDisable() - 内存泄漏！
}

// ✅ 正确：始终在 onDisable 中注销
@ccclass('EventLeakGood')
export class EventLeakGood extends Component {
    protected onEnable(): void {
        this.node.on(Node.EventType.TOUCH_START, this.onTouchStart, this);
        EventManager.on(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);
    }

    protected onDisable(): void {
        this.node.off(Node.EventType.TOUCH_START, this.onTouchStart, this);
        EventManager.off(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);
    }

    private onTouchStart(event: EventTouch): void {}
    private onScoreChanged(data: ScoreChangedEvent): void {}
}

// 严重级别：🔴 严重
// 影响：内存泄漏、性能下降
// 修复：始终实现 onDisable() 以注销监听器
```

### 缺少必要引用验证

```typescript
// ❌ 严重：未验证必要引用
@ccclass('NoValidation')
export class NoValidation extends Component {
    @property(Node)
    private targetNode: Node | null = null;

    protected onLoad(): void {
        this.targetNode!.setPosition(0, 0, 0); // 为 null 时会崩溃
    }
}

// ✅ 正确：在 onLoad 中验证
@ccclass('WithValidation')
export class WithValidation extends Component {
    @property(Node)
    private readonly targetNode: Node | null = null;

    protected onLoad(): void {
        if (!this.targetNode) {
            throw new Error('WithValidation: targetNode 是必需的');
        }
        this.targetNode.setPosition(0, 0, 0);
    }
}

// 严重级别：🔴 严重
// 影响：运行时崩溃且错误信息不友好
// 修复：在 onLoad() 中验证所有必要的 @property 引用
```

### 资源清理违规

```typescript
// ❌ 严重：未释放资源
@ccclass('ResourceLeakBad')
export class ResourceLeakBad extends Component {
    private readonly loadedAssets: Map<string, Asset> = new Map();

    protected onDestroy(): void {
        // 缺少：decRef() 和 clear()
    }
}

// ✅ 正确：完整的清理
@ccclass('ResourceLeakGood')
export class ResourceLeakGood extends Component {
    private readonly loadedAssets: Map<string, Asset> = new Map();

    protected onDestroy(): void {
        for (const [id, asset] of this.loadedAssets) {
            asset.decRef();
        }
        this.loadedAssets.clear();
        this.unscheduleAllCallbacks();
    }
}

// 严重级别：🔴 严重
// 影响：内存泄漏
// 修复：在 onDestroy() 中释放资源并清空集合
```

## 性能违规（可试玩广告特有）

### Update 循环中的内存分配

```typescript
// ❌ 严重：每帧分配内存
@ccclass('UpdateAllocationsBad')
export class UpdateAllocationsBad extends Component {
    protected update(dt: number): void {
        const pos = this.node.position.clone(); // 每秒 60 次分配
        pos.y += 10 * dt;
        this.node.setPosition(pos);
    }
}

// ✅ 正确：预分配并复用
@ccclass('UpdateAllocationsGood')
export class UpdateAllocationsGood extends Component {
    private readonly tempVec3: Vec3 = new Vec3();

    protected update(dt: number): void {
        this.node.getPosition(this.tempVec3);
        this.tempVec3.y += 10 * dt;
        this.node.setPosition(this.tempVec3);
    }
}

// 严重级别：🔴 严重
// 影响：掉帧、GC 暂停
// 修复：预分配对象，在 update 中复用
```

### Update 中查找组件

```typescript
// ❌ 重要：update 中 getComponent
@ccclass('ComponentLookupBad')
export class ComponentLookupBad extends Component {
    @property(Node)
    private playerNode: Node | null = null;

    protected update(dt: number): void {
        const controller = this.playerNode!.getComponent(PlayerController); // 昂贵！
        controller?.update(dt);
    }
}

// ✅ 正确：缓存组件引用
@ccclass('ComponentLookupGood')
export class ComponentLookupGood extends Component {
    @property(Node)
    private readonly playerNode: Node | null = null;

    private playerController!: PlayerController;

    protected start(): void {
        if (!this.playerNode) {
            throw new Error('playerNode 是必需的');
        }
        const controller = this.playerNode.getComponent(PlayerController);
        if (!controller) {
            throw new Error('未找到 PlayerController');
        }
        this.playerController = controller;
    }

    protected update(dt: number): void {
        this.playerController.update(dt);
    }
}

// 严重级别：🟡 重要
// 影响：显著的性能开销
// 修复：在 start() 中缓存组件引用
```

## 总结：架构审查清单

**🔴 严重（必须修复）：**
- [ ] onLoad() 中不访问其他组件（使用 start()）
- [ ] 所有事件监听器在 onDisable() 中注销
- [ ] 必要的 @property 引用在 onLoad() 中验证
- [ ] 资源在 onDestroy() 中释放
- [ ] update() 循环中零内存分配
- [ ] 不被重新赋值的 @property 使用 readonly

**🟡 重要（应该修复）：**
- [ ] 组件引用已缓存（update 中不 getComponent）
- [ ] 昂贵操作已节流（每 N 帧）
- [ ] 节点引用已缓存（update 中不 find()）
- [ ] 数组使用 .length = 0 清空（不创建新数组）

**🟢 建议（锦上添花）：**
- [ ] 频繁生成/回收使用对象池
- [ ] WeakMap 用于自动清理缓存
- [ ] 可释放模式用于订阅管理

**始终修复生命周期和事件清理问题 - 它们会导致崩溃和内存泄漏。**
