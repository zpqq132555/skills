# 性能优化指南 — Cocos Creator 3.8

> 📖 本文件为 `cocos-creator-3x-cn` 技能参考文件，提供性能优化的全面指导。

---

## 1. 性能优化层次

```
┌─────────────────────────────────────┐
│         架构层优化 (影响最大)         │
│  对象池、资源管理、加载策略           │
├─────────────────────────────────────┤
│         渲染层优化                   │
│  Draw Call、合批、纹理压缩           │
├─────────────────────────────────────┤
│         逻辑层优化                   │
│  算法、缓存、调度频率               │
├─────────────────────────────────────┤
│         内存层优化 (基础保障)         │
│  GC 减压、引用管理、泄漏预防        │
└─────────────────────────────────────┘
```

---

## 2. 渲染性能

### 2.1 Draw Call 优化

```typescript
// 1. 使用图集（SpriteAtlas）合并碎图
// 同一图集 + 同一材质 + 相邻渲染顺序 = 自动合批

// 2. 合理规划渲染层级，避免合批打断
// ❌ 打断合批的排列：
// Sprite(Atlas_A) → Sprite(Atlas_B) → Sprite(Atlas_A)
// ✅ 友好排列：
// Sprite(Atlas_A) → Sprite(Atlas_A) → Sprite(Atlas_B)

// 3. 减少 Mask 使用（每个 Mask 增加 2 个 draw call）

// 4. Label 优化
// - 使用 BMFont 替代系统字体
// - 静态文本使用 BITMAP 缓存模式
// - 频繁更新的文本使用 CHAR 缓存模式
```

### 2.2 纹理优化

```
纹理规范:
- 使用 2 的幂次方尺寸（256/512/1024/2048）
- 尽量使用图集而非散图
- 大面积背景考虑使用 JPEG + 单独 Alpha 通道
- 移动端使用压缩纹理格式（ASTC/ETC2/PVRTC）
- UI 图集建议不超过 2048x2048
```

### 2.3 节点树优化

```typescript
// 1. 不可见节点设为 inactive（跳过整棵子树）
node.active = false; // ✅ 比 opacity = 0 更高效

// 2. 减少节点树深度
// 扁平化结构比深层嵌套更高效

// 3. 避免频繁增删节点
// 使用对象池 + active 控制显隐
```

---

## 3. 内存优化

### 3.1 对象池模式

```typescript
import { NodePool, instantiate, Prefab, Node } from 'cc';

class ObjectPool {
    private _pool: NodePool;
    private _prefab: Prefab;

    constructor(prefab: Prefab, name: string, initCount = 10) {
        this._prefab = prefab;
        this._pool = new NodePool(name);
        // 预热
        for (let i = 0; i < initCount; i++) {
            this._pool.put(instantiate(prefab));
        }
    }

    public get(): Node {
        return this._pool.size() > 0
            ? this._pool.get()!
            : instantiate(this._prefab);
    }

    public put(node: Node) {
        this._pool.put(node);
    }

    public clear() {
        this._pool.clear();
    }

    public get size(): number {
        return this._pool.size();
    }
}
```

### 3.2 避免 GC 抖动

```typescript
// ❌ 每帧创建临时对象
update(dt: number) {
    const dir = new Vec3(1, 0, 0);
    Vec3.multiplyScalar(dir, dir, this.speed * dt);
    this.node.position = this.node.position.add(dir);
}

// ✅ 复用预分配对象
private _tempDir = new Vec3();
private _tempPos = new Vec3();

update(dt: number) {
    Vec3.set(this._tempDir, 1, 0, 0);
    Vec3.multiplyScalar(this._tempDir, this._tempDir, this.speed * dt);
    Vec3.add(this._tempPos, this.node.position, this._tempDir);
    this.node.setPosition(this._tempPos);
}
```

### 3.3 数组操作优化

```typescript
// ❌ 频繁 splice 删除（触发数组重排）
for (let i = arr.length - 1; i >= 0; i--) {
    if (arr[i].dead) arr.splice(i, 1);
}

// ✅ 交换删除法（无需重排）
function swapRemove<T>(arr: T[], index: number): void {
    arr[index] = arr[arr.length - 1];
    arr.pop();
}

// ✅ 标记-清除（批量处理）
const alive: Enemy[] = [];
for (const e of enemies) {
    if (!e.dead) alive.push(e);
}
enemies.length = 0;
enemies.push(...alive);
```

### 3.4 字符串优化

```typescript
// ❌ 频繁字符串拼接
let result = '';
for (const item of items) {
    result += item.name + ',';
}

// ✅ 使用数组 join
const parts: string[] = [];
for (const item of items) {
    parts.push(item.name);
}
const result = parts.join(',');
```

---

## 4. 逻辑优化

### 4.1 更新频率控制

```typescript
// ❌ 所有逻辑都放 update（每帧执行）
update(dt: number) {
    this.checkEnemies();    // 不需要每帧
    this.updateUI();        // 不需要每帧
    this.movePlayer(dt);    // 需要每帧
}

// ✅ 低频逻辑使用 schedule
start() {
    this.schedule(this.checkEnemies, 0.5);  // 每 0.5 秒
    this.schedule(this.updateUI, 0.1);      // 每 0.1 秒
}

update(dt: number) {
    this.movePlayer(dt);  // 仅高频逻辑
}
```

### 4.2 计算缓存

```typescript
// ❌ 重复计算
update() {
    const dist = Vec3.distance(this.node.position, this.target.position);
    if (dist < 100) { /* ... */ }
}

// ✅ 使用距离平方比较（避免 sqrt）
private readonly RANGE_SQ = 100 * 100;
update() {
    const distSq = Vec3.squaredDistance(this.node.position, this.target.position);
    if (distSq < this.RANGE_SQ) { /* ... */ }
}
```

### 4.3 查找优化

```typescript
// ❌ 每帧 find/getComponent
update() {
    const player = find('Canvas/Player');
    const hp = player?.getComponent(HealthBar);
}

// ✅ onLoad/start 中缓存
private _player: Node | null = null;
private _hp: HealthBar | null = null;

start() {
    this._player = find('Canvas/Player');
    this._hp = this._player?.getComponent(HealthBar) ?? null;
}
```

### 4.4 条件判断优化

```typescript
// ✅ 提前返回减少嵌套
update(dt: number) {
    if (!this._isPlaying) return;
    if (!this._target?.isValid) return;
    
    // 核心逻辑
}

// ✅ 高概率条件前置
if (commonCase) {
    // 最可能的分支
} else if (lessCommon) {
    // ...
} else {
    // 极少情况
}
```

---

## 5. 加载性能

### 5.1 资源预加载

```typescript
// 场景预加载
director.preloadScene('GameScene', (err) => {
    // 预加载完成，切换更快
    director.loadScene('GameScene');
});

// 资源预加载
resources.preload('prefabs/boss', Prefab);
resources.preload('audio/battle', AudioClip);
```

### 5.2 分帧加载

```typescript
// 大量节点分帧创建，避免单帧卡顿
async createItems(count: number, prefab: Prefab, parent: Node) {
    const BATCH = 5; // 每帧创建 5 个
    for (let i = 0; i < count; i++) {
        const node = instantiate(prefab);
        parent.addChild(node);
        if ((i + 1) % BATCH === 0) {
            await this.nextFrame(); // 等待下一帧
        }
    }
}

private nextFrame(): Promise<void> {
    return new Promise(resolve => {
        this.scheduleOnce(resolve, 0);
    });
}
```

### 5.3 Bundle 按需加载

```typescript
// 根据游戏进度加载资源
async loadLevel(level: number) {
    return new Promise<void>((resolve, reject) => {
        assetManager.loadBundle(`level_${level}`, (err, bundle) => {
            if (err) { reject(err); return; }
            bundle.loadScene('main', (err, scene) => {
                if (err) { reject(err); return; }
                director.runScene(scene);
                resolve();
            });
        });
    });
}
```

---

## 6. 性能监测

### 6.1 帧率监控

```typescript
import { director, game } from 'cc';

// 设置目标帧率
game.frameRate = 60;

// 获取当前帧间隔
const dt = director.getDeltaTime();
const currentFPS = 1 / dt;
```

### 6.2 调试工具

```
Chrome DevTools 性能分析:
1. Performance 面板 → 录制游戏片段
2. 查看 Scripting/Rendering/GC 时间占比
3. 关注长任务（>16ms）

Cocos Creator 调试面板:
- 菜单栏 → 开发者 → 调试面板
- 查看 Draw Call、Node Count、Triangles 等指标
```

---

## 7. 性能优化清单

| 优先级 | 检查项 | 目标 |
|--------|--------|------|
| P0 | Draw Call 数量 | 2D 游戏 < 50, 可试玩广告 < 30 |
| P0 | 帧率稳定性 | ≥ 30fps, 目标 60fps |
| P0 | 内存占用 | 移动端 < 150MB |
| P1 | 图集使用率 | > 70% 使用率 |
| P1 | 对象池覆盖 | 频繁创建/销毁的节点使用池 |
| P1 | 事件泄漏 | on/off 严格配对 |
| P2 | 临时对象分配 | update 中零分配 |
| P2 | 查找调用缓存 | find/getComponent 缓存结果 |
| P2 | 低频逻辑分离 | 从 update 移到 schedule |
| P3 | 资源按需加载 | 使用 Bundle 分模块 |
| P3 | 压缩纹理 | 启用平台对应格式 |
