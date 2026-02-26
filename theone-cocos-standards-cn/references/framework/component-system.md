# Cocos Creator 组件系统

## 实体-组件（EC）系统概述

Cocos Creator 使用实体-组件（EC）架构，其中：
- **节点（Node）** = 实体（游戏对象容器）
- **组件（Component）** = 附加到节点的行为/功能
- **场景（Scene）** = 节点层级集合

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

// ✅ 优秀：完整的组件结构
@ccclass('PlayerController')
export class PlayerController extends Component {
    // @property 装饰器将字段暴露给检查器
    @property(Node)
    private readonly targetNode: Node | null = null;

    @property(Number)
    private readonly moveSpeed: number = 100;

    // 私有字段不暴露
    private currentHealth: number = 100;
    private static readonly MAX_HEALTH: number = 100;

    // 生命周期方法按执行顺序：
    // 1. onLoad() - 组件初始化
    // 2. start() - 所有组件加载完成后
    // 3. onEnable() - 启用时（可多次调用）
    // 4. update(dt) - 每帧
    // 5. lateUpdate(dt) - 所有 update() 之后
    // 6. onDisable() - 禁用时
    // 7. onDestroy() - 清理
}
```

## @ccclass 装饰器

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

// ✅ 优秀：@ccclass 带显式名称
@ccclass('GameManager')
export class GameManager extends Component {
    // 组件实现
}

// ✅ 良好：@ccclass 不带名称（使用类名）
@ccclass
export class PlayerController extends Component {
    // 组件实现
}

// ❌ 错误：缺少 @ccclass 装饰器
export class GameManager extends Component {
    // 不会工作 - Cocos 无法序列化此组件
}

// ❌ 错误：未继承 Component
@ccclass('GameManager')
export class GameManager {
    // 不会工作 - 必须继承 Component
}
```

## @property 装饰器

```typescript
import { _decorator, Component, Node, Sprite, Label } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('PropertyExamples')
export class PropertyExamples extends Component {
    // ✅ 优秀：节点引用
    @property(Node)
    private readonly playerNode: Node | null = null;

    // ✅ 优秀：组件引用
    @property(Sprite)
    private readonly spriteComponent: Sprite | null = null;

    // ✅ 优秀：基本类型
    @property(Number)
    private readonly moveSpeed: number = 100;

    @property(String)
    private readonly playerName: string = 'Player';

    @property(Boolean)
    private readonly enableDebug: boolean = false;

    // ✅ 优秀：节点数组
    @property([Node])
    private readonly enemyNodes: Node[] = [];

    // ✅ 优秀：数字数组
    @property([Number])
    private readonly levelScores: number[] = [];

    // ✅ 优秀：枚举属性
    @property({ type: Enum(GameState) })
    private currentState: GameState = GameState.LOADING;

    // ✅ 优秀：带自定义显示名称和提示的属性
    @property({
        type: Number,
        displayName: '移动速度',
        tooltip: '玩家移动速度，单位/秒',
        min: 0,
        max: 500,
        step: 10,
    })
    private readonly speed: number = 100;

    // ✅ 优秀：不应重新赋值的属性使用 readonly
    @property(Node)
    private readonly targetNode: Node | null = null; // 初始化后无法重新赋值

    // 私有字段（不暴露给检查器）
    private currentHealth: number = 100;
}

// ❌ 错误：没有类型的属性
@property
private playerNode: Node | null = null; // 无法正确序列化

// ❌ 错误：应该为 readonly 的可变属性
@property(Node)
private targetNode: Node | null = null; // 若不重新赋值应为 readonly
```

## 组件生命周期方法

### 1. onLoad() - 初始化

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('GameManager')
export class GameManager extends Component {
    @property(Node)
    private readonly playerNode: Node | null = null;

    @property(Node)
    private readonly uiRoot: Node | null = null;

    // ✅ 优秀：onLoad 用于初始化和验证
    protected onLoad(): void {
        // 验证必要引用
        if (!this.playerNode) {
            throw new Error('GameManager: playerNode 是必需的');
        }
        if (!this.uiRoot) {
            throw new Error('GameManager: uiRoot 是必需的');
        }

        // 初始化组件状态
        this.initializeGameState();

        // 缓存引用（此时不要引用其他组件）
        this.cacheNodeReferences();
    }

    private initializeGameState(): void {
        // 设置初始状态
    }

    private cacheNodeReferences(): void {
        // 缓存子节点以加速访问
    }
}

// ❌ 错误：在 onLoad 中访问其他组件
protected onLoad(): void {
    // 不要这样做 - 其他组件可能尚未加载
    const playerController = this.playerNode!.getComponent(PlayerController);
    playerController.initialize(); // 可能为 undefined！
}

// ❌ 错误：onLoad 中执行繁重操作
protected onLoad(): void {
    // 避免昂贵操作 - onLoad 应该快速
    this.loadAllLevelData(); // 应该在 start() 中异步执行
    this.generateProceduralContent(); // onLoad 中太昂贵
}
```

### 2. start() - 后初始化

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('PlayerController')
export class PlayerController extends Component {
    @property(Node)
    private readonly enemyManagerNode: Node | null = null;

    private enemyManager!: EnemyManager;

    protected onLoad(): void {
        // 验证引用
        if (!this.enemyManagerNode) {
            throw new Error('PlayerController: enemyManagerNode 是必需的');
        }
    }

    // ✅ 优秀：start() 用于引用其他组件
    protected start(): void {
        // 现在可以安全获取其他节点的组件
        const enemyManager = this.enemyManagerNode!.getComponent(EnemyManager);
        if (!enemyManager) {
            throw new Error('未找到 EnemyManager 组件');
        }
        this.enemyManager = enemyManager;

        // 基于其他组件初始化
        this.setupPlayerBasedOnEnemies();

        // 启动异步操作
        this.loadPlayerDataAsync();
    }

    private setupPlayerBasedOnEnemies(): void {
        const enemyCount = this.enemyManager.getEnemyCount();
        this.adjustDifficultyBasedOnEnemies(enemyCount);
    }

    private async loadPlayerDataAsync(): Promise<void> {
        // 异步加载在 start() 中是安全的
    }
}

// ❌ 错误：使用 start() 替代 onLoad 进行验证
protected start(): void {
    // 太晚了 - 可能在 start() 调用前就被使用
    if (!this.playerNode) {
        throw new Error('playerNode 是必需的');
    }
}
```

### 3. onEnable() - 激活

```typescript
import { _decorator, Component, Node, EventTouch } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('InputHandler')
export class InputHandler extends Component {
    @property(Node)
    private readonly buttonNode: Node | null = null;

    // ✅ 优秀：onEnable() 用于注册监听器
    protected onEnable(): void {
        // 注册事件监听器
        if (this.buttonNode) {
            this.buttonNode.on(Node.EventType.TOUCH_START, this.onTouchStart, this);
            this.buttonNode.on(Node.EventType.TOUCH_END, this.onTouchEnd, this);
        }

        // 订阅全局事件
        EventManager.on(GameEvent.LEVEL_COMPLETE, this.onLevelComplete, this);

        // 恢复组件操作
        this.resumeGameLogic();
    }

    protected onDisable(): void {
        // ✅ 关键：始终在 onDisable 中注销
        if (this.buttonNode) {
            this.buttonNode.off(Node.EventType.TOUCH_START, this.onTouchStart, this);
            this.buttonNode.off(Node.EventType.TOUCH_END, this.onTouchEnd, this);
        }

        EventManager.off(GameEvent.LEVEL_COMPLETE, this.onLevelComplete, this);

        // 暂停组件操作
        this.pauseGameLogic();
    }

    private onTouchStart(event: EventTouch): void {
        // 处理触摸
    }

    private onTouchEnd(event: EventTouch): void {
        // 处理触摸结束
    }

    private onLevelComplete(): void {
        // 处理关卡完成
    }
}

// ❌ 错误：在 onLoad 中注册监听器
protected onLoad(): void {
    // 不要在这里注册 - 禁用时不会正确注销
    this.node.on(Node.EventType.TOUCH_START, this.onTouchStart, this);
}

// ❌ 错误：onDisable 中未注销
protected onEnable(): void {
    this.node.on(Node.EventType.TOUCH_START, this.onTouchStart, this);
}

protected onDisable(): void {
    // 缺少注销 - 内存泄漏！
}
```

### 4. update(dt) - 每帧逻辑

```typescript
import { _decorator, Component, Node, Vec3 } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('PlayerMovement')
export class PlayerMovement extends Component {
    @property(Number)
    private readonly moveSpeed: number = 100;

    private readonly tempVec3: Vec3 = new Vec3();
    private inputDirection: Vec3 = new Vec3(1, 0, 0);

    // ✅ 优秀：高效的 update 实现
    protected update(dt: number): void {
        // 复用预分配的向量
        this.node.getPosition(this.tempVec3);

        // 计算移动
        this.tempVec3.x += this.inputDirection.x * this.moveSpeed * dt;
        this.tempVec3.y += this.inputDirection.y * this.moveSpeed * dt;

        // 应用新位置
        this.node.setPosition(this.tempVec3);
    }
}

// 节流昂贵操作
@ccclass('AIController')
export class AIController extends Component {
    private frameCount: number = 0;
    private static readonly AI_UPDATE_INTERVAL: number = 10;

    // ✅ 优秀：节流昂贵操作
    protected update(dt: number): void {
        this.frameCount++;

        // 廉价操作每帧执行
        this.moveTowardsTarget(dt);

        // 昂贵的 AI 决策每 10 帧执行
        if (this.frameCount % AIController.AI_UPDATE_INTERVAL === 0) {
            this.updateAIDecision();
        }
    }

    private moveTowardsTarget(dt: number): void {
        // 简单移动计算
    }

    private updateAIDecision(): void {
        // 复杂 AI 逻辑
    }
}

// ❌ 错误：update 中有内存分配
protected update(dt: number): void {
    const currentPos = this.node.position.clone(); // 每帧分配！
    currentPos.x += this.moveSpeed * dt;
    this.node.setPosition(currentPos);
}

// ❌ 错误：每帧执行昂贵操作
protected update(dt: number): void {
    this.recalculatePathfinding(); // A* 算法每秒 60 次！
    this.updateComplexAI(); // 每帧太昂贵
}

// ❌ 错误：update 中查找组件
protected update(dt: number): void {
    const sprite = this.node.getComponent(Sprite); // 应在 onLoad 中缓存！
    sprite?.doSomething();
}
```

### 5. lateUpdate(dt) - 后更新逻辑

```typescript
import { _decorator, Component, Node, Camera } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('CameraFollow')
export class CameraFollow extends Component {
    @property(Node)
    private readonly target: Node | null = null;

    @property(Camera)
    private readonly camera: Camera | null = null;

    // ✅ 优秀：lateUpdate 用于相机跟随
    // 在所有 update() 调用之后运行，确保目标已移动
    protected lateUpdate(dt: number): void {
        if (!this.target || !this.camera) return;

        // 在目标更新后跟随目标位置
        const targetPos = this.target.position;
        this.camera.node.setPosition(targetPos.x, targetPos.y, this.camera.node.position.z);
    }
}

// ✅ 良好：lateUpdate 用于依赖游戏状态的 UI
@ccclass('HealthBarUpdater')
export class HealthBarUpdater extends Component {
    @property(Node)
    private readonly healthBar: Node | null = null;

    private playerHealth: number = 100;

    // 血量在 PlayerController.update() 中更新
    // UI 在 lateUpdate() 中更新以反映最终血量值
    protected lateUpdate(dt: number): void {
        if (!this.healthBar) return;

        const healthPercentage = this.playerHealth / 100;
        this.healthBar.scale = new Vec3(healthPercentage, 1, 1);
    }
}

// ❌ 错误：使用 lateUpdate 执行常规逻辑
protected lateUpdate(dt: number): void {
    // 这应该在 update() 中，而不是 lateUpdate()
    this.movePlayer(dt);
}
```

### 6. onDestroy() - 清理

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('ResourceManager')
export class ResourceManager extends Component {
    private readonly loadedAssets: Map<string, Asset> = new Map();
    private readonly eventListeners: Set<Function> = new Set();
    private readonly scheduledCallbacks: Set<Function> = new Set();

    // ✅ 优秀：onDestroy 中完整清理
    protected onDestroy(): void {
        // 注销所有事件监听器
        this.node.off(Node.EventType.TOUCH_START);
        EventManager.off(GameEvent.LEVEL_COMPLETE, this.onLevelComplete, this);

        // 清空集合
        this.eventListeners.clear();
        this.scheduledCallbacks.clear();

        // 释放已加载的资源
        for (const [id, asset] of this.loadedAssets) {
            asset.decRef();
        }
        this.loadedAssets.clear();

        // 取消所有定时回调
        this.unscheduleAllCallbacks();

        // 清除引用以防止内存泄漏
        this.clearReferences();
    }

    private clearReferences(): void {
        // 清除缓存的引用
    }
}

// ❌ 错误：缺少清理
protected onDestroy(): void {
    // 忘记注销事件 - 内存泄漏！
    // 忘记释放资源 - 内存泄漏！
    // 忘记取消定时回调 - 可能导致错误！
}

// ❌ 错误：不完整的清理
protected onDestroy(): void {
    this.loadedAssets.clear(); // 清空了 Map 但没有 decRef 资源！
}
```

## 组件执行顺序

```typescript
// 场景加载时的执行顺序：
// 1. 所有组件：onLoad()（按层级顺序）
// 2. 所有组件：start()（按层级顺序）
// 3. 所有组件：onEnable()（如果尚未启用）
// 4. 开始帧循环：
//    - 所有组件：update(dt)
//    - 所有组件：lateUpdate(dt)
// 5. 当组件禁用时：
//    - 组件：onDisable()
// 6. 当组件销毁时：
//    - 组件：onDestroy()

// ✅ 优秀：生命周期方法组织
@ccclass('CompleteLifecycle')
export class CompleteLifecycle extends Component {
    // 1. 初始化阶段
    protected onLoad(): void {
        // 初始化组件
        // 验证必要引用
        // 缓存节点引用
        // 此时不要访问其他组件
    }

    protected start(): void {
        // 访问其他组件（现在安全了）
        // 启动异步操作
        // 基于其他组件初始化
    }

    // 2. 激活阶段
    protected onEnable(): void {
        // 注册事件监听器
        // 订阅全局事件
        // 恢复操作
    }

    // 3. 更新阶段
    protected update(dt: number): void {
        // 每帧游戏逻辑
        // 移动、输入、AI
        // 保持零内存分配
    }

    protected lateUpdate(dt: number): void {
        // 依赖 update() 的逻辑
        // 相机跟随、UI 更新
    }

    // 4. 停用阶段
    protected onDisable(): void {
        // 注销事件监听器
        // 取消订阅事件
        // 暂停操作
    }

    // 5. 清理阶段
    protected onDestroy(): void {
        // 释放资源
        // 清空集合
        // 取消定时回调
        // 最终清理
    }
}
```

## 必要引用验证

```typescript
import { _decorator, Component, Node, Sprite } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('RequiredReferences')
export class RequiredReferences extends Component {
    @property(Node)
    private readonly targetNode: Node | null = null;

    @property(Sprite)
    private readonly spriteComponent: Sprite | null = null;

    @property([Node])
    private readonly enemyNodes: Node[] = [];

    // ✅ 优秀：在 onLoad 中验证所有必要引用
    protected onLoad(): void {
        if (!this.targetNode) {
            throw new Error('RequiredReferences: targetNode 是必需的');
        }

        if (!this.spriteComponent) {
            throw new Error('RequiredReferences: spriteComponent 是必需的');
        }

        if (this.enemyNodes.length === 0) {
            throw new Error('RequiredReferences: 至少需要一个敌人节点');
        }

        // 所有引用验证通过 - 可安全使用
        this.initialize();
    }

    private initialize(): void {
        // 此处可安全使用所有引用
        this.targetNode!.setPosition(0, 0, 0);
        this.spriteComponent!.sizeMode = Sprite.SizeMode.CUSTOM;
    }
}

// ❌ 错误：无验证
protected onLoad(): void {
    // 假设引用存在 - 运行时可能崩溃
    this.targetNode!.setPosition(0, 0, 0);
}

// ❌ 错误：静默验证
protected onLoad(): void {
    if (!this.targetNode) {
        console.error('targetNode 缺失'); // 不要只是记录日志
        return; // 静默失败
    }
}
```

## 总结：组件系统清单

**组件结构：**
- [ ] 类上有 @ccclass 装饰器
- [ ] 继承 Component 基类
- [ ] 暴露给检查器的字段使用 @property 装饰器
- [ ] 不被重新赋值的属性使用 readonly
- [ ] 使用访问修饰符（public/private/protected）

**生命周期实现：**
- [ ] onLoad() - 验证必要引用、初始化状态
- [ ] start() - 访问其他组件、启动异步操作
- [ ] onEnable() - 注册事件监听器
- [ ] update(dt) - 每帧逻辑（零内存分配）
- [ ] lateUpdate(dt) - 后更新逻辑（相机、UI）
- [ ] onDisable() - 注销事件监听器
- [ ] onDestroy() - 释放资源、清除引用

**最佳实践：**
- [ ] 在 onLoad() 中验证必要的 @property 引用
- [ ] 缺少必要引用时抛出异常
- [ ] 缓存组件引用（不在 update 中查找）
- [ ] update/lateUpdate 中零内存分配
- [ ] 始终在 onDisable/onDestroy 中注销监听器
- [ ] 适当使用 readonly 修饰 @property 字段

**组件生命周期是 Cocos Creator 架构的基础。**
