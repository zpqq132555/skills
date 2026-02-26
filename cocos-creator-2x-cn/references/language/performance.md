# TypeScript 性能模式（Cocos Creator 2.4）

## 目录

- [update 循环优化](#update-循环优化)
- [缓存策略](#缓存策略)
- [零分配模式](#零分配模式)
- [数组与集合优化](#数组与集合优化)
- [字符串处理](#字符串处理)
- [定时器与延迟调用](#定时器与延迟调用)
- [对象池模式](#对象池模式)

---

## update 循环优化

> update() 每帧调用，是性能热点。必须消除一切不必要的消耗。

```typescript
const { ccclass, property } = cc._decorator;

// ✅ 优秀：精简的 update
@ccclass
export default class OptimizedMovement extends cc.Component {
    @property
    public speed: number = 200;

    // 预分配的临时变量
    private tempPos: cc.Vec2 = cc.v2();
    private direction: cc.Vec2 = cc.v2();
    private isMoving: boolean = false;

    // 缓存的组件引用
    private rb: cc.RigidBody = null;

    protected onLoad(): void {
        this.rb = this.getComponent(cc.RigidBody);
    }

    protected update(dt: number): void {
        // ✅ 早退（Early return）减少不必要的计算
        if (!this.isMoving) return;

        // ✅ 使用预分配向量，零 GC
        this.node.getPosition(this.tempPos);
        this.tempPos.x += this.direction.x * this.speed * dt;
        this.tempPos.y += this.direction.y * this.speed * dt;
        this.node.setPosition(this.tempPos);
    }
}

// ❌ 差：update 中的常见问题
@ccclass
export default class BadMovement extends cc.Component {
    update(dt: number): void {
        // ❌ 每帧 getComponent
        const sprite = this.getComponent(cc.Sprite);

        // ❌ 每帧创建新对象
        const pos = cc.v2(this.node.x + 1, this.node.y);
        this.node.setPosition(pos);

        // ❌ 每帧字符串拼接
        this.node.name = "enemy_" + Date.now();

        // ❌ 每帧数组操作
        const enemies = this.node.parent.children.filter(
            c => c.name.startsWith("enemy")
        );
    }
}
```

### update 检查清单

| 检查项 | 说明 |
|--------|------|
| 无 `getComponent()` | 在 `onLoad`/`start` 中缓存 |
| 无 `new` / `cc.v2()` / `cc.v3()` | 使用预分配对象 |
| 无 `find()` / `getChildByName()` | 引用在初始化时获取 |
| 无数组 `filter/map/reduce` | 使用 for 循环 + 索引 |
| 无字符串拼接 | 使用数值或枚举比较 |
| 有 early return | 非活跃时跳过计算 |
| 无日志输出 | `CC_DEBUG` 包裹或移除 |

---

## 缓存策略

```typescript
@ccclass
export default class CachedExample extends cc.Component {
    // ✅ 组件缓存
    private sprite: cc.Sprite = null;
    private label: cc.Label = null;
    private anim: cc.Animation = null;
    private collider: cc.BoxCollider = null;

    // ✅ 节点引用缓存
    @property(cc.Node)
    private healthBar: cc.Node = null;

    @property(cc.Node)
    private scoreLabel: cc.Node = null;

    // ✅ 计算结果缓存
    private cachedWorldPos: cc.Vec2 = cc.v2();
    private worldPosDirty: boolean = true;

    protected onLoad(): void {
        // ✅ 一次性获取所有需要的组件
        this.sprite = this.getComponent(cc.Sprite);
        this.label = this.getComponent(cc.Label);
        this.anim = this.getComponent(cc.Animation);
        this.collider = this.getComponent(cc.BoxCollider);
    }

    // ✅ 脏标记模式：仅在必要时重算
    public getWorldPosition(): cc.Vec2 {
        if (this.worldPosDirty) {
            this.node.convertToWorldSpaceAR(cc.v2(), this.cachedWorldPos);
            this.worldPosDirty = false;
        }
        return this.cachedWorldPos;
    }

    // 移动时标记脏
    public setPosition(x: number, y: number): void {
        this.node.setPosition(x, y);
        this.worldPosDirty = true;
    }
}
```

---

## 零分配模式

> 在热路径中（update、碰撞回调、频繁调用的方法），避免创建新对象。

```typescript
@ccclass
export default class ZeroAllocExample extends cc.Component {
    // ✅ 预分配临时变量（类级别）
    private static readonly _tempVec2: cc.Vec2 = cc.v2();
    private static readonly _tempVec3: cc.Vec3 = cc.v3();
    private static readonly _tempColor: cc.Color = new cc.Color();

    // ✅ 实例级别临时变量
    private tempPos: cc.Vec2 = cc.v2();
    private tempSize: cc.Size = new cc.Size();

    // ✅ 距离计算：不创建中间向量
    public distanceTo(other: cc.Node): number {
        const dx = this.node.x - other.x;
        const dy = this.node.y - other.y;
        return Math.sqrt(dx * dx + dy * dy);
    }

    // ✅ 方向计算：复用临时变量
    public getDirectionTo(target: cc.Node): cc.Vec2 {
        const dir = this.tempPos;
        dir.x = target.x - this.node.x;
        dir.y = target.y - this.node.y;
        dir.normalizeSelf();
        return dir;
    }

    // ✅ 颜色插值：复用静态临时变量
    public lerpColor(from: cc.Color, to: cc.Color, t: number): cc.Color {
        const out = ZeroAllocExample._tempColor;
        out.r = from.r + (to.r - from.r) * t;
        out.g = from.g + (to.g - from.g) * t;
        out.b = from.b + (to.b - from.b) * t;
        out.a = from.a + (to.a - from.a) * t;
        return out;
    }

    // ❌ 差：每次调用创建新对象
    public badDistanceTo(other: cc.Node): number {
        const myPos = cc.v2(this.node.x, this.node.y);      // 新对象
        const otherPos = cc.v2(other.x, other.y);            // 新对象
        return myPos.sub(otherPos).mag();                     // 又一个新对象
    }
}
```

---

## 数组与集合优化

```typescript
// ✅ 优秀：使用 for 循环替代高阶函数（热路径中）
class EnemyManager {
    private enemies: Enemy[] = [];
    private activeCount: number = 0;

    // ✅ 手动循环，避免闭包和中间数组
    public updateAll(dt: number): void {
        const list = this.enemies;
        const len = list.length;
        for (let i = 0; i < len; i++) {
            const enemy = list[i];
            if (enemy.isActive) {
                enemy.update(dt);
            }
        }
    }

    // ✅ 倒序遍历安全删除
    public removeDeadEnemies(): void {
        const list = this.enemies;
        for (let i = list.length - 1; i >= 0; i--) {
            if (list[i].isDead) {
                // 用最后一个元素填充空位（O(1) 删除）
                list[i] = list[list.length - 1];
                list.length--;
            }
        }
    }

    // ✅ 预分配数组容量（如果引擎支持或手动管理）
    public init(maxEnemies: number): void {
        this.enemies = new Array<Enemy>(maxEnemies);
        this.activeCount = 0;
    }

    // ❌ 差：高阶函数链（每个步骤创建中间数组）
    public badGetActiveEnemies(): Enemy[] {
        return this.enemies
            .filter(e => e.isActive)       // 中间数组 1
            .sort((a, b) => a.x - b.x)    // 排序
            .slice(0, 10);                 // 中间数组 2
    }
}

// ✅ Map vs Object 选择
// 频繁增删键 → 使用 Map
const dynamicCache = new Map<string, cc.SpriteFrame>();

// 固定键集合 → 使用 Object / enum
const CONFIG = {
    maxHealth: 100,
    moveSpeed: 200,
} as const;
```

---

## 字符串处理

```typescript
// ✅ 优秀：避免在热路径中使用字符串
enum EnemyType {
    NORMAL = 0,
    ELITE = 1,
    BOSS = 2,
}

// ✅ 使用数值比较替代字符串比较
public getEnemyDamage(type: EnemyType): number {
    switch (type) {
        case EnemyType.NORMAL: return 10;
        case EnemyType.ELITE: return 25;
        case EnemyType.BOSS: return 50;
        default: return 0;
    }
}

// ❌ 差：热路径中使用字符串
public badGetDamage(type: string): number {
    if (type === "normal") return 10;    // 字符串比较慢
    if (type === "elite") return 25;
    if (type === "boss") return 50;
    return 0;
}

// ✅ 批量字符串拼接使用数组 join
public buildLeaderboard(players: { name: string; score: number }[]): string {
    const parts: string[] = [];
    for (let i = 0; i < players.length; i++) {
        parts.push(`${i + 1}. ${players[i].name}: ${players[i].score}`);
    }
    return parts.join("\n");
}
```

---

## 定时器与延迟调用

```typescript
@ccclass
export default class TimerExample extends cc.Component {
    // ✅ 优秀：使用 schedule 系统
    protected onLoad(): void {
        // 延迟调用（单次）
        this.scheduleOnce(this.delayedInit, 0.5);

        // 重复调用（间隔 1 秒）
        this.schedule(this.checkEnemySpawn, 1.0);

        // 有限次数重复（重复 5 次，间隔 0.2 秒，延迟 1 秒开始）
        this.schedule(this.spawnWave, 0.2, 5, 1.0);
    }

    protected onDestroy(): void {
        // ✅ 必须清理定时器
        this.unschedule(this.checkEnemySpawn);
        this.unscheduleAllCallbacks();
    }

    private delayedInit(): void { /* ... */ }
    private checkEnemySpawn(): void { /* ... */ }
    private spawnWave(): void { /* ... */ }

    // ❌ 差：使用 setTimeout/setInterval
    badExample(): void {
        setTimeout(() => {
            // 不受 Cocos 生命周期管理
            // 节点销毁后仍会触发 → 空引用崩溃
            this.node.setPosition(0, 0);
        }, 1000);

        setInterval(() => {
            // 不会随着组件销毁自动清除
            // 内存泄漏！
            this.updateScore();
        }, 500);
    }
}
```

---

## 对象池模式

```typescript
// ✅ 优秀：使用 cc.NodePool 的高性能对象池
@ccclass
export default class BulletManager extends cc.Component {
    @property(cc.Prefab)
    private bulletPrefab: cc.Prefab = null;

    private bulletPool: cc.NodePool = new cc.NodePool("BulletController");

    // 预创建对象
    protected onLoad(): void {
        this.prewarm(20);
    }

    private prewarm(count: number): void {
        for (let i = 0; i < count; i++) {
            const node = cc.instantiate(this.bulletPrefab);
            this.bulletPool.put(node);
        }
    }

    // 获取对象（优先从池中取）
    public spawn(pos: cc.Vec2): cc.Node {
        let node: cc.Node;
        if (this.bulletPool.size() > 0) {
            node = this.bulletPool.get();  // 触发 reuse()
        } else {
            node = cc.instantiate(this.bulletPrefab);
        }
        node.setPosition(pos);
        node.parent = this.node;
        return node;
    }

    // 回收对象
    public recycle(node: cc.Node): void {
        this.bulletPool.put(node);  // 触发 unuse()
    }

    // 清理池
    protected onDestroy(): void {
        this.bulletPool.clear();
    }
}

// BulletController 组件：实现 reuse/unuse 生命周期
@ccclass
export default class BulletController extends cc.Component {
    private speed: number = 500;
    private direction: cc.Vec2 = cc.v2(0, 1);

    // cc.NodePool.get() 时调用
    public reuse(): void {
        this.node.active = true;
        this.node.opacity = 255;
        this.direction.x = 0;
        this.direction.y = 1;
    }

    // cc.NodePool.put() 时调用
    public unuse(): void {
        this.node.active = false;
        this.node.stopAllActions();
        this.unscheduleAllCallbacks();
    }

    protected update(dt: number): void {
        this.node.x += this.direction.x * this.speed * dt;
        this.node.y += this.direction.y * this.speed * dt;

        // 超出屏幕回收
        if (Math.abs(this.node.y) > 600) {
            const mgr = this.node.parent.getComponent(BulletManager);
            if (mgr) mgr.recycle(this.node);
        }
    }
}
```
