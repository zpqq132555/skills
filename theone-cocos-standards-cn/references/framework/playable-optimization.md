# 可试玩广告性能优化

## DrawCall 合批（可试玩广告关键）

**目标：<10 个 DrawCall 以实现流畅的 60fps 可试玩广告**

```typescript
import { _decorator, Component, Sprite, SpriteAtlas, SpriteFrame } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('SpriteAtlasManager')
export class SpriteAtlasManager extends Component {
    // ✅ 优秀：使用精灵图集进行 DrawCall 合批
    @property(SpriteAtlas)
    private readonly characterAtlas: SpriteAtlas | null = null;

    @property(SpriteAtlas)
    private readonly uiAtlas: SpriteAtlas | null = null;

    private readonly spriteFrameCache: Map<string, SpriteFrame> = new Map();

    protected onLoad(): void {
        if (!this.characterAtlas || !this.uiAtlas) {
            throw new Error('SpriteAtlasManager: 图集是必需的');
        }

        // ✅ 优秀：从图集预热精灵帧
        this.prewarmAtlas(this.characterAtlas, 'character');
        this.prewarmAtlas(this.uiAtlas, 'ui');
    }

    private prewarmAtlas(atlas: SpriteAtlas, prefix: string): void {
        const spriteFrames = atlas.getSpriteFrames();
        for (const frame of spriteFrames) {
            const key = `${prefix}_${frame.name}`;
            this.spriteFrameCache.set(key, frame);
        }
    }

    // ✅ 优秀：从缓存获取精灵帧（在同一个 DrawCall 中合批）
    public getSpriteFrame(atlasName: string, frameName: string): SpriteFrame | null {
        const key = `${atlasName}_${frameName}`;
        return this.spriteFrameCache.get(key) ?? null;
    }
}

// 用法：同一图集的所有精灵 = 一个 DrawCall
@ccclass('CharacterSprite')
export class CharacterSprite extends Component {
    @property(Sprite)
    private readonly sprite: Sprite | null = null;

    private atlasManager!: SpriteAtlasManager;

    protected start(): void {
        const manager = this.node.parent?.getComponent(SpriteAtlasManager);
        if (!manager) throw new Error('未找到 SpriteAtlasManager');
        this.atlasManager = manager;

        // ✅ 良好：从图集设置精灵帧（合批）
        const frame = this.atlasManager.getSpriteFrame('character', 'idle_01');
        if (frame && this.sprite) {
            this.sprite.spriteFrame = frame;
        }
    }
}

// ❌ 错误：单独纹理（多个 DrawCall）
@property(SpriteFrame)
private characterIdleFrame: SpriteFrame | null = null; // DrawCall 1

@property(SpriteFrame)
private characterWalkFrame: SpriteFrame | null = null; // DrawCall 2

@property(SpriteFrame)
private characterJumpFrame: SpriteFrame | null = null; // DrawCall 3
// 结果：3 个精灵 = 3 个 DrawCall！

// ✅ 更好：单个图集
@property(SpriteAtlas)
private characterAtlas: SpriteAtlas | null = null; // 所有帧 1 个 DrawCall
```

## GPU 蒙皮（骨骼动画）

```typescript
import { _decorator, Component, SkeletalAnimation } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('AnimationController')
export class AnimationController extends Component {
    @property(SkeletalAnimation)
    private readonly skeleton: SkeletalAnimation | null = null;

    protected onLoad(): void {
        if (!this.skeleton) {
            throw new Error('AnimationController: skeleton 是必需的');
        }

        // ✅ 优秀：启用 GPU 蒙皮以获得更好性能
        // GPU 处理骨骼变换而非 CPU
        this.skeleton.useBakedAnimation = true; // 烘焙动画数据
    }

    public playAnimation(animName: string, loop: boolean = false): void {
        if (!this.skeleton) return;

        const state = this.skeleton.getState(animName);
        if (state) {
            state.wrapMode = loop ? SkeletalAnimation.WrapMode.Loop : SkeletalAnimation.WrapMode.Normal;
            this.skeleton.play(animName);
        }
    }
}

// ❌ 错误：CPU 蒙皮（默认，较慢）
// 可试玩广告中不要将 useBakedAnimation 设为 false
```

## 可试玩广告对象池

```typescript
import { _decorator, Component, Node, Prefab, instantiate, NodePool } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('PlayableObjectPool')
export class PlayableObjectPool extends Component {
    @property(Prefab)
    private readonly bulletPrefab: Prefab | null = null;

    @property(Prefab)
    private readonly effectPrefab: Prefab | null = null;

    private readonly bulletPool: NodePool = new NodePool();
    private readonly effectPool: NodePool = new NodePool();
    private static readonly PREWARM_COUNT: number = 20;

    // ✅ 优秀：预热池以避免游戏过程中的内存分配
    protected onLoad(): void {
        if (!this.bulletPrefab || !this.effectPrefab) {
            throw new Error('PlayableObjectPool: 预制体是必需的');
        }

        // 预热子弹池
        for (let i = 0; i < PlayableObjectPool.PREWARM_COUNT; i++) {
            const bullet = instantiate(this.bulletPrefab);
            this.bulletPool.put(bullet);
        }

        // 预热特效池
        for (let i = 0; i < PlayableObjectPool.PREWARM_COUNT; i++) {
            const effect = instantiate(this.effectPrefab);
            this.effectPool.put(effect);
        }
    }

    // ✅ 优秀：从池中获取（游戏中零内存分配）
    public getBullet(): Node {
        if (this.bulletPool.size() > 0) {
            const bullet = this.bulletPool.get()!;
            bullet.active = true;
            return bullet;
        }

        // 后备方案：创建新的（如果正确预热应该很少发生）
        if (!this.bulletPrefab) {
            throw new Error('bulletPrefab 为 null');
        }
        return instantiate(this.bulletPrefab);
    }

    public returnBullet(bullet: Node): void {
        bullet.active = false;
        this.bulletPool.put(bullet);
    }

    protected onDestroy(): void {
        this.bulletPool.clear();
        this.effectPool.clear();
    }
}

// ❌ 错误：游戏过程中创建/销毁对象
public shoot(): void {
    const bullet = instantiate(this.bulletPrefab!); // 每次都分配
    this.scheduleOnce(() => {
        bullet.destroy(); // 触发 GC
    }, 2.0);
}
```

## 可试玩广告 Update 循环优化

```typescript
import { _decorator, Component, Node, Vec3 } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('OptimizedUpdate')
export class OptimizedUpdate extends Component {
    @property([Node])
    private readonly enemies: Node[] = [];

    // ✅ 优秀：预分配以避免 update 中的内存分配
    private readonly tempVec3: Vec3 = new Vec3();
    private readonly activeEnemies: Node[] = [];
    private activeEnemiesDirty: boolean = true;
    private frameCount: number = 0;

    // ✅ 优秀：昂贵操作每 N 帧更新
    protected update(dt: number): void {
        this.frameCount++;

        // 廉价操作：每帧
        this.updateMovement(dt);

        // 昂贵操作：每 10 帧（60fps 下每秒 6 次）
        if (this.frameCount % 10 === 0) {
            this.updateAI();
        }

        // 非常昂贵：每 60 帧（60fps 下每秒一次）
        if (this.frameCount % 60 === 0) {
            this.updatePathfinding();
        }
    }

    private updateMovement(dt: number): void {
        // 使用缓存的活跃敌人列表
        const activeEnemies = this.getActiveEnemies();

        for (const enemy of activeEnemies) {
            // 复用预分配的向量
            enemy.getPosition(this.tempVec3);
            this.tempVec3.y += 10 * dt;
            enemy.setPosition(this.tempVec3);
        }
    }

    private getActiveEnemies(): Node[] {
        if (this.activeEnemiesDirty) {
            this.activeEnemies.length = 0;
            for (const enemy of this.enemies) {
                if (enemy.active) {
                    this.activeEnemies.push(enemy);
                }
            }
            this.activeEnemiesDirty = false;
        }
        return this.activeEnemies;
    }

    private updateAI(): void {
        // 昂贵的 AI 逻辑
    }

    private updatePathfinding(): void {
        // 非常昂贵的寻路
    }
}

// ❌ 错误：所有逻辑在 update 中，到处分配内存
protected update(dt: number): void {
    // 每帧分配数组
    const activeEnemies = this.enemies.filter(e => e.active);

    for (const enemy of activeEnemies) {
        // 每帧分配向量
        const pos = enemy.position.clone();
        pos.y += 10 * dt;
        enemy.setPosition(pos);
    }

    // 每帧执行昂贵操作
    this.updatePathfinding(); // 每秒 60 次！
    this.updateAI(); // 每秒 60 次！
}
```

## 资源加载和预加载

```typescript
import { _decorator, Component, resources, SpriteFrame, AudioClip } from 'cc';
const { ccclass } = _decorator;

@ccclass('ResourcePreloader')
export class ResourcePreloader extends Component {
    private readonly loadedResources: Map<string, Asset> = new Map();

    // ✅ 优秀：游戏开始时预加载所有资源
    protected async start(): Promise<void> {
        await this.preloadAllResources();
    }

    private async preloadAllResources(): Promise<void> {
        const resourcePaths = [
            'sprites/character',
            'sprites/enemies',
            'audio/bgm',
            'audio/sfx',
        ];

        const promises = resourcePaths.map(path => this.preloadResource(path));
        await Promise.all(promises);

        console.log('所有资源预加载完成');
    }

    private async preloadResource(path: string): Promise<void> {
        return new Promise((resolve, reject) => {
            resources.load(path, (err, asset) => {
                if (err) {
                    console.error(`加载 ${path} 失败:`, err);
                    reject(err);
                    return;
                }

                this.loadedResources.set(path, asset);
                resolve();
            });
        });
    }

    public getResource<T extends Asset>(path: string): T | null {
        return (this.loadedResources.get(path) as T) ?? null;
    }

    protected onDestroy(): void {
        // ✅ 优秀：释放所有已加载的资源
        for (const [path, asset] of this.loadedResources) {
            asset.decRef();
        }
        this.loadedResources.clear();
    }
}

// ❌ 错误：游戏过程中加载资源
protected update(dt: number): void {
    if (this.shouldSpawnEnemy()) {
        // 游戏过程中加载会导致帧率下降！
        resources.load('sprites/enemy', SpriteFrame, (err, sprite) => {
            this.spawnEnemy(sprite);
        });
    }
}

// ✅ 更好：预加载后复用
protected start(): void {
    resources.load('sprites/enemy', SpriteFrame, (err, sprite) => {
        this.enemySprite = sprite;
    });
}

protected update(dt: number): void {
    if (this.shouldSpawnEnemy() && this.enemySprite) {
        this.spawnEnemy(this.enemySprite); // 即时，无加载
    }
}
```

## 可试玩广告内存管理

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass } = _decorator;

@ccclass('MemoryOptimized')
export class MemoryOptimized extends Component {
    // ✅ 优秀：大数据集使用类型化数组
    private positions: Float32Array = new Float32Array(300); // 100 个 Vec3
    private velocities: Float32Array = new Float32Array(300);

    // ✅ 优秀：复用数组而不是创建新数组
    private readonly tempArray: number[] = [];

    protected update(dt: number): void {
        // 复用数组，不分配内存
        this.tempArray.length = 0;

        for (let i = 0; i < 100; i++) {
            this.tempArray.push(i * dt);
        }
    }

    // ✅ 优秀：WeakMap 用于缓存（自动清理）
    private readonly nodeCache: WeakMap<Node, CachedData> = new WeakMap();

    public getCachedData(node: Node): CachedData | undefined {
        return this.nodeCache.get(node);
    }

    protected onDestroy(): void {
        // ✅ 优秀：清除引用
        this.tempArray.length = 0;
        // WeakMap 条目在节点销毁时自动清除
    }
}
```

## 总结：可试玩广告优化清单

**DrawCall 合批（<10 目标）：**
- [ ] 所有精灵使用精灵图集（非单独纹理）
- [ ] 在 onLoad() 中预热精灵帧缓存
- [ ] UI 元素合并到单个图集
- [ ] 相似对象使用相同材质

**动画性能：**
- [ ] 启用 GPU 蒙皮（useBakedAnimation = true）
- [ ] 烘焙骨骼动画
- [ ] 限制同时播放的动画数量

**对象池：**
- [ ] 子弹、特效、敌人使用对象池（任何频繁生成的对象）
- [ ] 在 onLoad() 中预热池（至少 20 个对象）
- [ ] 游戏过程中绝不 instantiate/destroy

**Update 循环：**
- [ ] update() 中零内存分配
- [ ] 昂贵操作节流（每 10-60 帧）
- [ ] 缓存活跃对象列表
- [ ] 复用预分配的向量/数组

**资源管理：**
- [ ] 游戏开始时预加载所有资源
- [ ] 游戏过程中绝不加载资源
- [ ] 在 onDestroy() 中释放资源
- [ ] 使用 WeakMap 进行自动清理缓存

**目标：60fps，<10 个 DrawCall，可试玩广告包体 <5MB。**
