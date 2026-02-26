# Cocos Creator 事件模式

## EventDispatcher 模式（自定义事件）

```typescript
import { _decorator, Component, EventTarget } from 'cc';
const { ccclass } = _decorator;

// ✅ 优秀：集中式事件系统
export enum GameEvent {
    SCORE_CHANGED = 'score_changed',
    LEVEL_COMPLETE = 'level_complete',
    PLAYER_DIED = 'player_died',
    ENEMY_SPAWNED = 'enemy_spawned',
}

export interface ScoreChangedEvent {
    oldScore: number;
    newScore: number;
    combo: number;
}

export interface LevelCompleteEvent {
    level: number;
    stars: number;
    time: number;
}

@ccclass('EventManager')
export class EventManager extends Component {
    private static instance: EventManager | null = null;
    private readonly eventTarget: EventTarget = new EventTarget();

    protected onLoad(): void {
        if (EventManager.instance) {
            throw new Error('EventManager: 实例已存在');
        }
        EventManager.instance = this;
    }

    protected onDestroy(): void {
        this.eventTarget.clear();
        EventManager.instance = null;
    }

    // ✅ 优秀：类型安全的发送
    public static emit<T>(event: GameEvent, data?: T): void {
        if (!EventManager.instance) {
            throw new Error('EventManager: 实例未初始化');
        }
        EventManager.instance.eventTarget.emit(event, data);
    }

    // ✅ 优秀：类型安全的订阅
    public static on<T>(event: GameEvent, callback: (data: T) => void, target?: any): void {
        if (!EventManager.instance) {
            throw new Error('EventManager: 实例未初始化');
        }
        EventManager.instance.eventTarget.on(event, callback, target);
    }

    // ✅ 优秀：类型安全的取消订阅
    public static off<T>(event: GameEvent, callback: (data: T) => void, target?: any): void {
        if (!EventManager.instance) {
            throw new Error('EventManager: 实例未初始化');
        }
        EventManager.instance.eventTarget.off(event, callback, target);
    }

    // ✅ 优秀：一次性订阅（第一次调用后自动取消）
    public static once<T>(event: GameEvent, callback: (data: T) => void, target?: any): void {
        if (!EventManager.instance) {
            throw new Error('EventManager: 实例未初始化');
        }
        EventManager.instance.eventTarget.once(event, callback, target);
    }
}

// 在组件中使用
@ccclass('ScoreManager')
export class ScoreManager extends Component {
    private currentScore: number = 0;

    public addScore(points: number): void {
        const oldScore = this.currentScore;
        this.currentScore += points;

        // ✅ 优秀：发送类型化事件
        EventManager.emit<ScoreChangedEvent>(GameEvent.SCORE_CHANGED, {
            oldScore,
            newScore: this.currentScore,
            combo: 1,
        });
    }
}

// 订阅者组件
@ccclass('ScoreDisplay')
export class ScoreDisplay extends Component {
    protected onEnable(): void {
        // ✅ 优秀：在 onEnable 中订阅
        EventManager.on<ScoreChangedEvent>(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);
    }

    protected onDisable(): void {
        // ✅ 关键：始终在 onDisable 中取消订阅
        EventManager.off<ScoreChangedEvent>(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);
    }

    private onScoreChanged(data: ScoreChangedEvent): void {
        console.log(`分数: ${data.oldScore} → ${data.newScore}`);
        this.updateDisplay(data.newScore);
    }

    private updateDisplay(score: number): void {
        // 更新 UI
    }
}

// ❌ 错误：未取消订阅（内存泄漏）
protected onEnable(): void {
    EventManager.on<ScoreChangedEvent>(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);
}

// 缺少 onDisable - 内存泄漏！

// ❌ 错误：基于字符串的事件（非类型安全）
EventManager.emit('score_changed', { score: 100 }); // 容易打错
```

## 节点事件系统（内置事件）

```typescript
import { _decorator, Component, Node, EventTouch, EventKeyboard } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('TouchHandler')
export class TouchHandler extends Component {
    @property(Node)
    private readonly buttonNode: Node | null = null;

    // ✅ 优秀：触摸事件处理
    protected onEnable(): void {
        if (!this.buttonNode) return;

        this.buttonNode.on(Node.EventType.TOUCH_START, this.onTouchStart, this);
        this.buttonNode.on(Node.EventType.TOUCH_MOVE, this.onTouchMove, this);
        this.buttonNode.on(Node.EventType.TOUCH_END, this.onTouchEnd, this);
        this.buttonNode.on(Node.EventType.TOUCH_CANCEL, this.onTouchCancel, this);
    }

    protected onDisable(): void {
        if (!this.buttonNode) return;

        this.buttonNode.off(Node.EventType.TOUCH_START, this.onTouchStart, this);
        this.buttonNode.off(Node.EventType.TOUCH_MOVE, this.onTouchMove, this);
        this.buttonNode.off(Node.EventType.TOUCH_END, this.onTouchEnd, this);
        this.buttonNode.off(Node.EventType.TOUCH_CANCEL, this.onTouchCancel, this);
    }

    private onTouchStart(event: EventTouch): void {
        const location = event.getUILocation();
        console.log(`触摸开始于: ${location.x}, ${location.y}`);
    }

    private onTouchMove(event: EventTouch): void {
        const delta = event.getUIDelta();
        console.log(`触摸增量: ${delta.x}, ${delta.y}`);
    }

    private onTouchEnd(event: EventTouch): void {
        console.log('触摸结束');
    }

    private onTouchCancel(event: EventTouch): void {
        console.log('触摸取消');
    }
}

// ✅ 优秀：键盘事件处理
@ccclass('KeyboardHandler')
export class KeyboardHandler extends Component {
    protected onEnable(): void {
        this.node.on(Node.EventType.KEY_DOWN, this.onKeyDown, this);
        this.node.on(Node.EventType.KEY_UP, this.onKeyUp, this);
    }

    protected onDisable(): void {
        this.node.off(Node.EventType.KEY_DOWN, this.onKeyDown, this);
        this.node.off(Node.EventType.KEY_UP, this.onKeyUp, this);
    }

    private onKeyDown(event: EventKeyboard): void {
        switch (event.keyCode) {
            case macro.KEY.w:
            case macro.KEY.up:
                this.moveUp();
                break;
            case macro.KEY.s:
            case macro.KEY.down:
                this.moveDown();
                break;
        }
    }

    private onKeyUp(event: EventKeyboard): void {
        this.stopMovement();
    }
}
```

## 事件清理模式

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

// ✅ 优秀：完整的清理模式
@ccclass('CompleteEventCleanup')
export class CompleteEventCleanup extends Component {
    @property(Node)
    private readonly targetNode: Node | null = null;

    // 跟踪已注册的监听器以便完整清理
    private readonly registeredListeners: Array<{
        node: Node;
        eventType: string;
        callback: Function;
    }> = [];

    protected onEnable(): void {
        if (!this.targetNode) return;

        // 注册并跟踪监听器
        this.registerListener(
            this.targetNode,
            Node.EventType.TOUCH_START,
            this.onTouchStart
        );
        this.registerListener(
            this.node,
            Node.EventType.CHILD_ADDED,
            this.onChildAdded
        );

        // 订阅全局事件
        EventManager.on(GameEvent.LEVEL_COMPLETE, this.onLevelComplete, this);
    }

    protected onDisable(): void {
        // 注销所有已跟踪的监听器
        for (const { node, eventType, callback } of this.registeredListeners) {
            node.off(eventType, callback, this);
        }
        this.registeredListeners.length = 0;

        // 取消订阅全局事件
        EventManager.off(GameEvent.LEVEL_COMPLETE, this.onLevelComplete, this);
    }

    private registerListener(node: Node, eventType: string, callback: Function): void {
        node.on(eventType, callback, this);
        this.registeredListeners.push({ node, eventType, callback });
    }

    private onTouchStart(event: EventTouch): void {
        // 处理触摸
    }

    private onChildAdded(child: Node): void {
        // 处理子节点添加
    }

    private onLevelComplete(): void {
        // 处理关卡完成
    }
}

// ✅ 优秀：使用可释放模式的自动清理
interface IDisposable {
    dispose(): void;
}

class EventSubscription implements IDisposable {
    constructor(
        private readonly eventManager: EventManager,
        private readonly event: GameEvent,
        private readonly callback: Function,
        private readonly target: any
    ) {}

    public dispose(): void {
        EventManager.off(this.event, this.callback as any, this.target);
    }
}

@ccclass('DisposablePattern')
export class DisposablePattern extends Component {
    private readonly subscriptions: IDisposable[] = [];

    protected onEnable(): void {
        // ✅ 优秀：跟踪订阅以便自动清理
        this.subscriptions.push(
            new EventSubscription(
                EventManager.instance!,
                GameEvent.SCORE_CHANGED,
                this.onScoreChanged,
                this
            )
        );
    }

    protected onDisable(): void {
        // ✅ 优秀：释放所有订阅
        for (const subscription of this.subscriptions) {
            subscription.dispose();
        }
        this.subscriptions.length = 0;
    }

    private onScoreChanged(data: ScoreChangedEvent): void {
        // 处理分数变化
    }
}
```

## 事件性能最佳实践

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

@ccclass('PerformanceOptimizedEvents')
export class PerformanceOptimizedEvents extends Component {
    // ✅ 优秀：高频事件节流
    private lastEmitTime: number = 0;
    private static readonly EMIT_THROTTLE_MS: number = 100; // 每秒最多 10 个事件

    public emitThrottled(event: GameEvent, data: any): void {
        const now = Date.now();
        if (now - this.lastEmitTime >= PerformanceOptimizedEvents.EMIT_THROTTLE_MS) {
            EventManager.emit(event, data);
            this.lastEmitTime = now;
        }
    }

    // ✅ 优秀：批量事件以减少开销
    private readonly pendingEvents: Array<{ event: GameEvent; data: any }> = [];
    private batchEmitScheduled: boolean = false;

    public emitBatched(event: GameEvent, data: any): void {
        this.pendingEvents.push({ event, data });

        if (!this.batchEmitScheduled) {
            this.batchEmitScheduled = true;
            this.scheduleOnce(() => {
                this.flushBatchedEvents();
            }, 0);
        }
    }

    private flushBatchedEvents(): void {
        for (const { event, data } of this.pendingEvents) {
            EventManager.emit(event, data);
        }
        this.pendingEvents.length = 0;
        this.batchEmitScheduled = false;
    }

    // ✅ 优秀：防抖事件（仅在静默期后发送）
    private debounceTimer: number | null = null;
    private static readonly DEBOUNCE_MS: number = 300;

    public emitDebounced(event: GameEvent, data: any): void {
        if (this.debounceTimer !== null) {
            clearTimeout(this.debounceTimer);
        }

        this.debounceTimer = setTimeout(() => {
            EventManager.emit(event, data);
            this.debounceTimer = null;
        }, PerformanceOptimizedEvents.DEBOUNCE_MS) as any;
    }
}

// ❌ 错误：在 update 循环中发送事件
protected update(dt: number): void {
    // 每秒发送 60 个事件！
    EventManager.emit(GameEvent.PLAYER_MOVED, this.node.position);
}

// ✅ 更好：节流或仅在显著变化时发送
private lastPosition: Vec3 = new Vec3();
private static readonly MOVE_THRESHOLD: number = 1.0;

protected update(dt: number): void {
    const distance = Vec3.distance(this.node.position, this.lastPosition);

    if (distance >= PerformanceOptimizedEvents.MOVE_THRESHOLD) {
        EventManager.emit(GameEvent.PLAYER_MOVED, this.node.position.clone());
        this.lastPosition.set(this.node.position);
    }
}
```

## 总结：事件模式清单

**EventDispatcher（自定义事件）：**
- [ ] 使用集中式 EventManager 配合 EventTarget
- [ ] 使用枚举定义事件名称（非字符串）
- [ ] 使用类型化的事件数据接口
- [ ] 在 onEnable() 中订阅，在 onDisable() 中取消订阅
- [ ] 始终传递 `this` 作为 target 参数以正确清理

**节点事件（内置）：**
- [ ] 使用 Node.EventType 常量（TOUCH_START、KEY_DOWN 等）
- [ ] 在 onEnable() 中注册监听器
- [ ] 在 onDisable() 中使用相同参数注销监听器
- [ ] 正确处理 EventTouch 和 EventKeyboard

**事件清理：**
- [ ] 跟踪所有已注册的监听器以便完整清理
- [ ] 在 onDisable() 和 onDestroy() 中都注销
- [ ] 使用可释放模式进行自动清理
- [ ] 在 onDestroy() 中清空事件集合

**性能：**
- [ ] 高频事件节流（每秒最多 10 个）
- [ ] 批量事件以减少开销
- [ ] 用户输入事件防抖
- [ ] 不在 update() 中无节流地发送事件

**始终取消订阅事件以防止内存泄漏。**
