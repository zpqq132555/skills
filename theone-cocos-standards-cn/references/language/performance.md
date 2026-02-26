# TypeScript 性能优化

## update() 中零内存分配

**关键规则**：绝不在 `update()`、`lateUpdate()` 或任何每帧调用的方法中分配对象。

```typescript
import { _decorator, Component, Node, Vec3, Quat } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('OptimizedController')
export class OptimizedController extends Component {
    @property(Node)
    private readonly targetNode: Node | null = null;

    // ✅ 优秀：预分配的可复用对象
    private readonly tempVec3: Vec3 = new Vec3();
    private readonly tempQuat: Quat = new Quat();
    private readonly tempVec3Array: Vec3[] = [];

    // ✅ 优秀：update 中无内存分配
    protected update(dt: number): void {
        if (!this.targetNode) return;

        // 复用预分配的向量
        this.targetNode.getPosition(this.tempVec3);
        this.tempVec3.y += 10 * dt;
        this.targetNode.setPosition(this.tempVec3);

        // 复用预分配的四元数
        this.targetNode.getRotation(this.tempQuat);
        Quat.rotateY(this.tempQuat, this.tempQuat, dt);
        this.targetNode.setRotation(this.tempQuat);
    }

    // ✅ 优秀：复用数组而不是创建新数组
    public updateMultipleNodes(nodes: Node[]): void {
        this.tempVec3Array.length = 0; // 清空而不分配

        for (const node of nodes) {
            node.getPosition(this.tempVec3);
            this.tempVec3Array.push(this.tempVec3.clone());
        }
    }
}

// ❌ 错误：update 中分配内存
protected update(dt: number): void {
    if (!this.targetNode) return;

    // 每帧创建新的 Vec3（每秒 60 次分配）
    const currentPos = this.targetNode.position.clone();
    currentPos.y += 10 * dt;
    this.targetNode.setPosition(currentPos);

    // 每帧创建新数组
    const positions = this.nodes.map(n => n.position.clone());
}

// ❌ 错误：update 中字符串拼接
protected update(dt: number): void {
    // 每帧创建新字符串
    const debugInfo = `位置: ${this.node.position.x}, ${this.node.position.y}`;
    console.log(debugInfo);
}
```

## 对象池模式

```typescript
import { _decorator, Component, Node, Prefab, instantiate, NodePool } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('BulletPool')
export class BulletPool extends Component {
    @property(Prefab)
    private readonly bulletPrefab: Prefab | null = null;

    private readonly pool: NodePool = new NodePool();
    private static readonly INITIAL_POOL_SIZE: number = 20;

    // ✅ 优秀：初始化时预热池
    protected onLoad(): void {
        if (!this.bulletPrefab) {
            throw new Error('BulletPool: bulletPrefab 是必需的');
        }

        for (let i = 0; i < BulletPool.INITIAL_POOL_SIZE; i++) {
            const bullet = instantiate(this.bulletPrefab);
            this.pool.put(bullet);
        }
    }

    // ✅ 优秀：从池中获取（有可用时无内存分配）
    public getBullet(): Node {
        let bullet: Node;

        if (this.pool.size() > 0) {
            bullet = this.pool.get()!;
        } else {
            // 仅在池为空时分配
            if (!this.bulletPrefab) {
                throw new Error('BulletPool: bulletPrefab 是必需的');
            }
            bullet = instantiate(this.bulletPrefab);
        }

        bullet.active = true;
        return bullet;
    }

    // ✅ 优秀：返回池中（无释放开销）
    public returnBullet(bullet: Node): void {
        bullet.active = false;
        this.pool.put(bullet);
    }

    // ✅ 优秀：清理时清空池
    protected onDestroy(): void {
        this.pool.clear();
    }
}

// 游戏中使用
@ccclass('Gun')
export class Gun extends Component {
    private readonly bulletPool!: BulletPool;

    public shoot(): void {
        // ✅ 良好：从池中获取而非 instantiate
        const bullet = this.bulletPool.getBullet();
        bullet.setPosition(this.node.position);

        // 设置定时器将子弹返回池中
        this.scheduleOnce(() => {
            this.bulletPool.returnBullet(bullet);
        }, 3.0);
    }
}

// ❌ 错误：每次都创建新实例
public shoot(): void {
    // 不断分配和释放
    const bullet = instantiate(this.bulletPrefab!);
    bullet.setPosition(this.node.position);

    this.scheduleOnce(() => {
        bullet.destroy(); // 触发垃圾回收
    }, 3.0);
}
```

## 缓存昂贵操作

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('EnemyManager')
export class EnemyManager extends Component {
    @property([Node])
    private readonly enemyNodes: Node[] = [];

    // ✅ 优秀：缓存组件引用
    private readonly enemyControllers: EnemyController[] = [];
    private cachedActiveEnemies: EnemyController[] = [];
    private activeEnemiesDirty: boolean = true;

    protected onLoad(): void {
        // 初始化时缓存组件引用
        for (const node of this.enemyNodes) {
            const controller = node.getComponent(EnemyController);
            if (controller) {
                this.enemyControllers.push(controller);
            }
        }
    }

    // ✅ 优秀：标记缓存为脏而不是重新计算
    public onEnemyStateChanged(): void {
        this.activeEnemiesDirty = true;
    }

    // ✅ 优秀：仅在需要时惰性重新计算
    public getActiveEnemies(): EnemyController[] {
        if (this.activeEnemiesDirty) {
            this.cachedActiveEnemies = this.enemyControllers.filter(e => e.isActive);
            this.activeEnemiesDirty = false;
        }
        return this.cachedActiveEnemies;
    }

    protected update(dt: number): void {
        // ✅ 良好：使用缓存的活跃敌人
        const activeEnemies = this.getActiveEnemies();

        for (const enemy of activeEnemies) {
            enemy.update(dt);
        }
    }
}

// ❌ 错误：每帧查找组件
protected update(dt: number): void {
    for (const node of this.enemyNodes) {
        const controller = node.getComponent(EnemyController); // 昂贵的查找！
        if (controller?.isActive) {
            controller.update(dt);
        }
    }
}

// ❌ 错误：每帧过滤
protected update(dt: number): void {
    const activeEnemies = this.enemyControllers.filter(e => e.isActive); // 每帧分配数组！
    for (const enemy of activeEnemies) {
        enemy.update(dt);
    }
}
```

## 节流昂贵操作

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

@ccclass('AIController')
export class AIController extends Component {
    private frameCount: number = 0;
    private static readonly AI_UPDATE_INTERVAL: number = 10; // 每 10 帧
    private static readonly PATHFINDING_INTERVAL: number = 60; // 每 60 帧（60fps 下每秒一次）

    // ✅ 优秀：每 N 帧更新 AI，而非每帧
    protected update(dt: number): void {
        this.frameCount++;

        // 每 10 帧运行昂贵的 AI 逻辑
        if (this.frameCount % AIController.AI_UPDATE_INTERVAL === 0) {
            this.updateAIDecision();
        }

        // 每 60 帧运行非常昂贵的寻路（每秒一次）
        if (this.frameCount % AIController.PATHFINDING_INTERVAL === 0) {
            this.recalculatePath();
        }

        // 廉价操作可每帧运行
        this.moveTowardsTarget(dt);
    }

    private updateAIDecision(): void {
        // 昂贵：检查所有敌人，评估威胁等
    }

    private recalculatePath(): void {
        // 非常昂贵：A* 寻路
    }

    private moveTowardsTarget(dt: number): void {
        // 廉价：简单移动
    }
}

// ❌ 错误：每帧执行昂贵操作
protected update(dt: number): void {
    this.recalculatePath(); // A* 寻路每秒 60 次！
    this.updateAIDecision(); // 复杂 AI 逻辑每秒 60 次！
    this.moveTowardsTarget(dt);
}
```

## 基于时间的节流

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

@ccclass('PerformanceMonitor')
export class PerformanceMonitor extends Component {
    private lastUpdateTime: number = 0;
    private static readonly UPDATE_INTERVAL: number = 1.0; // 1 秒

    // ✅ 优秀：基于时间的节流
    protected update(dt: number): void {
        const currentTime = Date.now() / 1000;

        if (currentTime - this.lastUpdateTime >= PerformanceMonitor.UPDATE_INTERVAL) {
            this.performExpensiveOperation();
            this.lastUpdateTime = currentTime;
        }
    }

    private performExpensiveOperation(): void {
        // 每秒运行一次的昂贵操作
    }
}

// 使用 scheduleOnce 的替代方案
@ccclass('TimerBased')
export class TimerBased extends Component {
    private static readonly CHECK_INTERVAL: number = 2.0; // 2 秒

    protected start(): void {
        this.scheduleCheckRecurring();
    }

    private scheduleCheckRecurring(): void {
        this.performCheck();
        this.scheduleOnce(this.scheduleCheckRecurring, TimerBased.CHECK_INTERVAL);
    }

    private performCheck(): void {
        // 昂贵的检查操作
    }
}
```

## 避免昂贵的查找

```typescript
import { _decorator, Component, Node, find } from 'cc';
const { ccclass } = _decorator;

@ccclass('GameManager')
export class GameManager extends Component {
    // ✅ 优秀：在 onLoad 中缓存引用
    private uiRootNode!: Node;
    private playerNode!: Node;
    private enemyNodes: Node[] = [];

    protected onLoad(): void {
        // 一次性缓存节点引用
        const uiRoot = find('Canvas/UI');
        if (!uiRoot) {
            throw new Error('GameManager: 未找到 UI 根节点');
        }
        this.uiRootNode = uiRoot;

        const player = find('Canvas/Player');
        if (!player) {
            throw new Error('GameManager: 未找到 Player');
        }
        this.playerNode = player;

        // 缓存敌人节点数组
        const enemyParent = find('Canvas/Enemies');
        if (enemyParent) {
            this.enemyNodes = enemyParent.children.slice();
        }
    }

    protected update(dt: number): void {
        // ✅ 良好：使用缓存的引用
        this.updatePlayer(this.playerNode, dt);
        this.updateEnemies(this.enemyNodes, dt);
    }
}

// ❌ 错误：每帧查找节点
protected update(dt: number): void {
    const player = find('Canvas/Player'); // 每帧昂贵搜索！
    const enemies = find('Canvas/Enemies')?.children; // 每帧昂贵搜索！

    if (player) {
        this.updatePlayer(player, dt);
    }
    if (enemies) {
        this.updateEnemies(enemies, dt);
    }
}

// ❌ 错误：每帧 getComponent
protected update(dt: number): void {
    const playerController = this.playerNode.getComponent(PlayerController); // 昂贵查找！
    playerController?.update(dt);
}

// ✅ 更好：缓存组件引用
private playerController!: PlayerController;

protected onLoad(): void {
    const controller = this.playerNode.getComponent(PlayerController);
    if (!controller) {
        throw new Error('未找到 PlayerController');
    }
    this.playerController = controller;
}

protected update(dt: number): void {
    this.playerController.update(dt);
}
```

## 字符串拼接性能

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

@ccclass('DebugDisplay')
export class DebugDisplay extends Component {
    // ✅ 优秀：使用模板字面量提高可读性
    public getDebugInfo(player: Player): string {
        return `玩家: ${player.name}, HP: ${player.health}/${player.maxHealth}, 等级: ${player.level}`;
    }

    // ✅ 优秀：大字符串用数组 join 高效构建
    public generateReport(players: Player[]): string {
        const lines: string[] = [];
        lines.push('=== 玩家报告 ===');

        for (const player of players) {
            lines.push(`${player.name}: 等级 ${player.level}, HP ${player.health}`);
        }

        lines.push('=== 报告结束 ===');
        return lines.join('\n');
    }

    // ✅ 优秀：避免 update 循环中的字符串操作
    private debugText: string = '';
    private frameCount: number = 0;

    protected update(dt: number): void {
        this.frameCount++;

        // 每 30 帧才更新调试文本
        if (this.frameCount % 30 === 0) {
            this.debugText = this.generateDebugText();
        }
    }
}

// ❌ 错误：循环中的字符串拼接
public generateReport(players: Player[]): string {
    let report = '=== 玩家报告 ===\n';

    for (const player of players) {
        report += `${player.name}: 等级 ${player.level}\n`; // 每次迭代分配新字符串
    }

    report += '=== 报告结束 ===';
    return report;
}

// ❌ 错误：update 中构建字符串
protected update(dt: number): void {
    this.debugText = `FPS: ${1/dt}, 位置: ${this.node.position}`; // 每帧分配
}
```

## 数值运算性能

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

@ccclass('MathOptimizations')
export class MathOptimizations extends Component {
    // ✅ 优秀：使用乘法替代除法
    private static readonly INV_FRAME_RATE: number = 1 / 60;

    public calculateTimedValue(value: number): number {
        return value * MathOptimizations.INV_FRAME_RATE; // 比 value / 60 快
    }

    // ✅ 优秀：使用位运算进行整数运算
    public fastFloor(value: number): number {
        return value | 0; // 对正数比 Math.floor 快
    }

    public isPowerOfTwo(value: number): boolean {
        return (value & (value - 1)) === 0; // 比对数检查快
    }

    // ✅ 优秀：缓存昂贵的数学运算
    private readonly sinCache: Map<number, number> = new Map();

    public getCachedSin(angle: number): number {
        if (!this.sinCache.has(angle)) {
            this.sinCache.set(angle, Math.sin(angle));
        }
        return this.sinCache.get(angle)!;
    }

    // ✅ 优秀：使用距离平方避免 sqrt
    public isWithinRange(pos1: Vec3, pos2: Vec3, range: number): boolean {
        const dx = pos2.x - pos1.x;
        const dy = pos2.y - pos1.y;
        const dz = pos2.z - pos1.z;
        const distSquared = dx * dx + dy * dy + dz * dz;
        const rangeSquared = range * range;
        return distSquared <= rangeSquared; // 无需 sqrt
    }
}

// ❌ 错误：使用昂贵操作
public isWithinRange(pos1: Vec3, pos2: Vec3, range: number): boolean {
    const distance = Vec3.distance(pos1, pos2); // 内部使用 sqrt
    return distance <= range;
}

// ❌ 错误：热路径中使用除法
protected update(dt: number): void {
    const value = this.baseValue / 60; // 除法比乘法慢
}
```

## 内存管理最佳实践

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass } = _decorator;

@ccclass('ResourceManager')
export class ResourceManager extends Component {
    private readonly loadedAssets: Map<string, Asset> = new Map();
    private readonly nodeReferences: Set<Node> = new Set();

    // ✅ 优秀：清理时清除引用
    protected onDestroy(): void {
        // 清空 Map 和 Set
        this.loadedAssets.clear();
        this.nodeReferences.clear();

        // 移除事件监听器
        this.node.off(Node.EventType.TOUCH_START);
    }

    // ✅ 优秀：移除未使用的资源
    public unloadAsset(assetId: string): void {
        const asset = this.loadedAssets.get(assetId);
        if (asset) {
            asset.decRef(); // 释放引用
            this.loadedAssets.delete(assetId);
        }
    }

    // ✅ 优秀：缓存使用弱引用
    private readonly weakNodeCache: WeakMap<Node, CachedData> = new WeakMap();

    public getCachedData(node: Node): CachedData | undefined {
        return this.weakNodeCache.get(node);
    }

    public setCachedData(node: Node, data: CachedData): void {
        this.weakNodeCache.set(node, data);
        // 节点被垃圾回收时 → 缓存条目自动移除
    }
}

// ❌ 错误：内存泄漏
protected onDestroy(): void {
    // 忘记清除引用 - 内存泄漏！
    // this.loadedAssets.clear();
    // this.nodeReferences.clear();
}

// ❌ 错误：强引用阻止垃圾回收
private readonly nodeCache: Map<Node, CachedData> = new Map();
// 即使节点销毁也不会被垃圾回收
```

## 总结：性能清单

**可试玩广告关键（<5MB，<10 DrawCall）：**

- [ ] update() 中零内存分配（预分配并复用）
- [ ] 频繁创建/销毁的对象使用对象池
- [ ] 缓存组件和节点引用（update 中不 getComponent）
- [ ] 节流昂贵操作（每 N 帧，而非每帧）
- [ ] 避免热路径中的字符串操作
- [ ] 使用乘法替代除法
- [ ] 使用距离平方替代距离（避免 sqrt）
- [ ] 在 onDestroy() 中清除引用以防止内存泄漏
- [ ] 使用 WeakMap 进行应被垃圾回收的缓存
- [ ] 使用 Array.length = 0 清空数组（不创建新数组）

**性能对于流畅的 60fps 可试玩广告至关重要。**
