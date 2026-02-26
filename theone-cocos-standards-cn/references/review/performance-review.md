# Cocos Creator 性能审查

本审查关注可试玩广告中影响帧率和加载时间的性能问题。

## DrawCall 爆炸

### 未合批的精灵

```typescript
// ❌ 严重：多个材质导致 DrawCall 过多
// 场景中每个精灵使用不同的纹理 = 每个都产生一次 DrawCall
// 10 个精灵 × 10 个不同纹理 = 10 个 DrawCall

// ✅ 正确：使用图集合批
// 1. 将精灵打入同一图集
// 2. 确保它们使用同一材质
// 3. 同一层级下相邻渲染

// 编辑器设置：
// - 将精灵图打入同一 SpriteAtlas
// - 使用 builtin-sprite 材质
// - 检查渲染顺序

// 严重级别：🔴 严重
// 影响：低端设备帧率直接崩溃
// 修复：使用图集、合并材质、检查渲染排序
```

### Label 打断合批

```typescript
// ❌ 严重：Label 穿插在精灵中间
// Sprite A (atlas1)
// Label       ← 打断合批！
// Sprite B (atlas1)
// 结果：3 个 DrawCall

// ✅ 正确：Label 统一放在精灵上方
// Sprite A (atlas1)
// Sprite B (atlas1)
// Label
// 结果：2 个 DrawCall

// 严重级别：🔴 严重
// 影响：每个 Label 穿插都会增加 DrawCall
// 修复：调整节点层级，Label 不要穿插在相同图集的精灵之间
```

## Update 循环分配

### 每帧创建临时对象

```typescript
// ❌ 严重：update 中每帧创建对象
@ccclass('FrameAllocationBad')
export class FrameAllocationBad extends Component {
    protected update(dt: number): void {
        const pos = new Vec3();                    // 每帧分配！
        const dir = new Vec3(1, 0, 0);            // 每帧分配！
        Vec3.add(pos, this.node.position, dir);
        this.node.setPosition(pos);

        const enemies = this.getEnemies();         // 每帧新数组！
        enemies.forEach(e => {
            const dist = Vec3.distance(
                this.node.position,
                e.node.position
            );
        });
    }

    private getEnemies(): Enemy[] {
        return this.node.parent!.getComponentsInChildren(Enemy); // 每帧遍历！
    }
}

// ✅ 正确：预分配并复用
@ccclass('FrameAllocationGood')
export class FrameAllocationGood extends Component {
    private readonly tempPos: Vec3 = new Vec3();
    private readonly tempDir: Vec3 = new Vec3(1, 0, 0);
    private readonly enemies: Enemy[] = [];

    protected start(): void {
        this.cacheEnemies();
    }

    protected update(dt: number): void {
        this.node.getPosition(this.tempPos);
        Vec3.add(this.tempPos, this.tempPos, this.tempDir);
        this.node.setPosition(this.tempPos);

        for (let i = 0, len = this.enemies.length; i < len; i++) {
            // 使用缓存数组
        }
    }

    private cacheEnemies(): void {
        const found = this.node.parent!.getComponentsInChildren(Enemy);
        this.enemies.length = 0;
        for (let i = 0; i < found.length; i++) {
            this.enemies.push(found[i]);
        }
    }
}

// 严重级别：🔴 严重
// 影响：GC 暂停、掉帧
// 修复：在成员变量中预分配对象,在 update 中复用
```

### 字符串拼接

```typescript
// ❌ 重要：update 中字符串拼接
protected update(dt: number): void {
    this.scoreLabel.string = "分数: " + this.score;     // 每帧创建新字符串
    this.timerLabel.string = `时间: ${this.time}`;      // 每帧创建新字符串
}

// ✅ 正确：仅在变化时更新
private lastScore: number = -1;

protected update(dt: number): void {
    if (this.score !== this.lastScore) {
        this.lastScore = this.score;
        this.scoreLabel.string = `分数: ${this.score}`;
    }
}

// 严重级别：🟡 重要
// 影响：不必要的字符串分配
// 修复：脏检查,仅在值变化时更新
```

## 缺少对象池

### 频繁创建和销毁节点

```typescript
// ❌ 严重：频繁 instantiate/destroy
@ccclass('NoPooingBad')
export class NoPoolingBad extends Component {
    @property(Prefab)
    private readonly bulletPrefab: Prefab | null = null;

    private shoot(): void {
        const bullet = instantiate(this.bulletPrefab!);
        this.node.addChild(bullet);
    }

    private onBulletHit(bullet: Node): void {
        bullet.destroy(); // 昂贵！
    }
}

// ✅ 正确：使用对象池
@ccclass('WithPoolingGood')
export class WithPoolingGood extends Component {
    @property(Prefab)
    private readonly bulletPrefab: Prefab | null = null;

    private readonly bulletPool: Node[] = [];
    private static readonly POOL_SIZE: number = 20;

    protected onLoad(): void {
        this.prewarm();
    }

    private prewarm(): void {
        for (let i = 0; i < WithPoolingGood.POOL_SIZE; i++) {
            const bullet = instantiate(this.bulletPrefab!);
            bullet.active = false;
            this.node.addChild(bullet);
            this.bulletPool.push(bullet);
        }
    }

    private shoot(): void {
        const bullet = this.acquire();
        if (!bullet) return;
        bullet.active = true;
        bullet.setPosition(this.node.position);
    }

    private acquire(): Node | null {
        for (let i = this.bulletPool.length - 1; i >= 0; i--) {
            if (!this.bulletPool[i].active) {
                return this.bulletPool[i];
            }
        }
        return null;
    }

    private release(bullet: Node): void {
        bullet.active = false;
    }
}

// 严重级别：🔴 严重
// 影响：掉帧尖峰、GC 暂停
// 修复：使用对象池管理频繁创建/销毁的对象
```

## 未节流的操作

### 每帧执行昂贵计算

```typescript
// ❌ 重要：每帧碰撞检测
@ccclass('UnthrottledBad')
export class UnthrottledBad extends Component {
    protected update(dt: number): void {
        this.checkAllCollisions();        // 每帧！
        this.updatePathfinding();         // 每帧！
        this.sortRenderOrder();           // 每帧！
    }
}

// ✅ 正确：节流到每 N 帧
@ccclass('ThrottledGood')
export class ThrottledGood extends Component {
    private frameCount: number = 0;

    protected update(dt: number): void {
        this.frameCount++;

        // 每 3 帧检测一次碰撞
        if (this.frameCount % 3 === 0) {
            this.checkAllCollisions();
        }

        // 每 10 帧更新一次寻路
        if (this.frameCount % 10 === 0) {
            this.updatePathfinding();
        }

        // 每 5 帧排序一次渲染顺序
        if (this.frameCount % 5 === 0) {
            this.sortRenderOrder();
        }
    }
}

// 严重级别：🟡 重要
// 影响：浪费 CPU 周期
// 修复：节流不需要每帧执行的昂贵操作
```

## 包体大小超标（>5MB）

### 未压缩的纹理

```typescript
// ❌ 严重：原始 PNG 纹理
// 1024x1024 PNG = ~2MB
// 多个这样的纹理轻松超过 5MB

// ✅ 正确：使用纹理压缩
// 编辑器纹理设置：
// - 格式: ASTC 4x4 / ETC2 / PVRTC (按平台)
// - 开启 "packable" 打入图集
// - 合理的最大尺寸 (512x512 或更小)
// - 移除不需要的 mipmap

// 严重级别：🔴 严重
// 影响：包体超标、加载慢
// 修复：压缩纹理,减小尺寸,使用图集
```

### 音频未优化

```typescript
// ❌ 重要：高品质 WAV/未压缩音频
// BGM: 44100Hz stereo WAV = 几 MB
// 音效: 多个未压缩文件

// ✅ 正确：优化音频
// BGM:
// - 格式: MP3 / OGG
// - 采样率: 22050Hz
// - 声道: mono
// - 码率: 64-96kbps
//
// 音效:
// - 格式: MP3
// - 采样率: 22050Hz
// - 声道: mono
// - 时长: 尽量短（<2s）

// 严重级别：🟡 重要
// 影响：包体膨胀
// 修复：压缩音频,降低采样率和声道
```

## 游戏过程中加载资源

### 同步加载阻塞主线程

```typescript
// ❌ 严重：游戏进行中加载资源
@ccclass('RuntimeLoadBad')
export class RuntimeLoadBad extends Component {
    private onLevelStart(): void {
        resources.load('prefabs/boss', Prefab, (err, prefab) => {
            // 加载期间可能卡顿！
            const boss = instantiate(prefab);
            this.node.addChild(boss);
        });
    }
}

// ✅ 正确：预加载
@ccclass('PreloadGood')
export class PreloadGood extends Component {
    private readonly preloadedAssets: Map<string, Asset> = new Map();

    protected onLoad(): void {
        this.preloadAll();
    }

    private preloadAll(): void {
        const paths = ['prefabs/boss', 'prefabs/effects'];
        let loaded = 0;

        for (const path of paths) {
            resources.preload(path, Prefab, () => {
                loaded++;
                if (loaded === paths.length) {
                    this.onAllLoaded();
                }
            });
        }
    }

    private onAllLoaded(): void {
        // 所有资源已预加载,可以开始游戏
    }

    private spawnBoss(): void {
        resources.load('prefabs/boss', Prefab, (err, prefab) => {
            if (err) {
                throw new Error(`加载 Boss 失败: ${err.message}`);
            }
            prefab.addRef();
            this.preloadedAssets.set('boss', prefab);
            const boss = instantiate(prefab);
            this.node.addChild(boss);
        });
    }

    protected onDestroy(): void {
        for (const [, asset] of this.preloadedAssets) {
            asset.decRef();
        }
        this.preloadedAssets.clear();
    }
}

// 严重级别：🔴 严重
// 影响：游戏中卡顿
// 修复：使用预加载,在游戏开始前加载所有必要资源
```

## GPU 蒙皮未启用

```typescript
// ❌ 重要：CPU 蒙皮动画
// SkeletalAnimation 组件默认使用 CPU 蒙皮
// CPU 蒙皮在低端设备上性能差

// ✅ 正确：启用 GPU 蒙皮
// 1. 选中带 SkeletalAnimation 的节点
// 2. 在 SkinnedMeshRenderer 中:
//    - useBakedAnimation = true（使用烘焙动画）
// 3. 或在脚本中:
//    skinnedMesh.useBakedAnimation = true;

// 注意事项：
// - GPU 蒙皮不支持动态骨骼数过多的模型
// - 需要测试目标平台兼容性
// - 烘焙动画会增加一些内存

// 严重级别：🟡 重要
// 影响：CPU 负载高、帧率低
// 修复：启用 GPU 蒙皮 / 烘焙动画
```

## 总结：性能审查清单

**🔴 严重（必须修复）：**
- [ ] DrawCall 数量合理（使用图集合批）
- [ ] update() 中零内存分配（预分配复用）
- [ ] 频繁生成/回收使用对象池
- [ ] 纹理已压缩（ASTC/ETC2/PVRTC）
- [ ] 包体大小 <5MB
- [ ] 游戏前预加载所有必要资源
- [ ] 资源正确释放（decRef + clear）

**🟡 重要（应该修复）：**
- [ ] Label 不打断精灵合批
- [ ] 字符串仅在变化时更新
- [ ] 昂贵操作已节流（N 帧一次）
- [ ] 音频已压缩优化
- [ ] 启用 GPU 蒙皮 / 烘焙动画

**性能关乎用户体验 - 可试玩广告如果卡顿,用户会直接关掉。**
