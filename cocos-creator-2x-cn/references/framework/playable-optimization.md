# Cocos Creator 2.4 可试玩广告优化

## 目录

- [DrawCall 优化](#drawcall-优化)
- [对象池 cc.NodePool](#对象池)
- [纹理与图集优化](#纹理与图集优化)
- [内存管理](#内存管理)
- [包体大小优化](#包体大小优化)
- [构建发布优化](#构建发布优化)

---

## DrawCall 优化

### 目标：<10 个 DrawCall

```typescript
// ✅ 使用自动图集减少 DrawCall
// 在编辑器中：资源管理器 → 右键 → 新建 → 自动图集配置
// 将同一 UI 界面的碎图放在同一目录下

// ✅ 使用 BMFont 替代系统字体
// BMFont 使用纹理渲染，可以参与合批
// 系统字体每个 Label 都是独立的 DrawCall

// ✅ 确保合批条件
// 1. 相同纹理（同一图集）
// 2. 相同混合模式
// 3. 相邻渲染顺序（节点树中相邻）
// 4. 无遮罩（Mask 会打断合批）
```

### 合批打断原因

| 原因 | 解决方案 |
|------|----------|
| 不同纹理 | 合并到同一图集 |
| Mask 组件 | 尽量避免使用，或集中放置 |
| 不同混合模式 | 统一混合模式 |
| 节点间插入了不同纹理 | 调整节点顺序 |
| Label 使用系统字体 | 改用 BMFont |
| RichText 组件 | 用多个 Label 替代 |
| Spine/DragonBones | 放在同一层级、合并图集 |

### 查看 DrawCall

```typescript
// 开启调试信息显示
cc.debug.setDisplayStats(true);
// 左下角会显示 DrawCall 数量
```

---

## 对象池

### cc.NodePool 使用

```typescript
const { ccclass, property } = cc._decorator;

@ccclass
export default class BulletManager extends cc.Component {
    @property(cc.Prefab)
    bulletPrefab: cc.Prefab = null;

    private bulletPool: cc.NodePool = new cc.NodePool("BulletComponent");

    onLoad(): void {
        // 预创建对象池
        this.initPool(20);
    }

    private initPool(count: number): void {
        for (let i = 0; i < count; i++) {
            const bullet = cc.instantiate(this.bulletPrefab);
            this.bulletPool.put(bullet);
        }
    }

    /**
     * 从对象池获取子弹
     * - 如果池中有可用对象，直接取出（调用组件的 reuse 方法）
     * - 如果池为空，创建新的
     */
    public spawnBullet(position: cc.Vec2): cc.Node {
        let bullet: cc.Node;

        if (this.bulletPool.size() > 0) {
            bullet = this.bulletPool.get();
        } else {
            bullet = cc.instantiate(this.bulletPrefab);
        }

        bullet.parent = this.node;
        bullet.setPosition(position);
        bullet.active = true;
        return bullet;
    }

    /**
     * 回收子弹到对象池
     * - 调用组件的 unuse 方法
     * - 从父节点移除
     */
    public recycleBullet(bullet: cc.Node): void {
        this.bulletPool.put(bullet);
    }

    onDestroy(): void {
        this.bulletPool.clear();
    }
}
```

### 对象池组件生命周期

```typescript
@ccclass
export default class BulletComponent extends cc.Component {
    private speed: number = 500;
    private direction: cc.Vec2 = cc.v2(0, 1);

    /**
     * 对象池取出时调用（替代 onLoad/start）
     * 用于重置状态
     */
    reuse(): void {
        this.speed = 500;
        this.direction = cc.v2(0, 1);
        this.node.opacity = 255;
    }

    /**
     * 对象池回收时调用（替代 onDestroy）
     * 用于清理状态
     */
    unuse(): void {
        this.node.stopAllActions();
        cc.Tween.stopAllByTarget(this.node);
        this.unscheduleAllCallbacks();
    }

    update(dt: number): void {
        this.node.x += this.direction.x * this.speed * dt;
        this.node.y += this.direction.y * this.speed * dt;

        // 超出屏幕时回收
        if (this.isOutOfScreen()) {
            // 通知管理器回收
            this.node.emit("recycle");
        }
    }

    private isOutOfScreen(): boolean {
        const pos = this.node.position;
        return Math.abs(pos.x) > 600 || Math.abs(pos.y) > 400;
    }
}
```

---

## 纹理与图集优化

### 自动图集配置

```
资源管理器中：
1. 在图片目录右键 → 新建 → 自动图集配置
2. 配置参数：
   - Max Width / Max Height: 2048（推荐 1024 或 2048）
   - Padding: 2
   - Allow Rotation: false（部分平台可能有问题）
   - Force Squared: false
   - 纹理格式：根据平台选择压缩格式
```

### 纹理压缩设置

```
项目设置 → 纹理压缩：
- Android: ETC2（GLES 3.0+）或 ETC1（兼容模式）
- iOS: PVRTC 4bpp 或 ASTC
- Web: 使用 WebP 或原始 PNG

构建面板 → 纹理压缩：
- 启用 "压缩纹理"
- 选择合适的质量级别
```

### 图片优化建议

```
1. 使用 2 的幂次方尺寸（256x256, 512x512, 1024x1024）
2. 去除图片周围的透明像素（Trim）
3. 降低不重要图片的分辨率
4. 使用 9-slice 切图替代大背景图
5. 纯色区域使用单像素 + 缩放
```

---

## 内存管理

### update 循环中零内存分配

```typescript
@ccclass
export default class OptimizedUpdate extends cc.Component {
    // ✅ 预分配可复用对象
    private readonly tempVec2: cc.Vec2 = cc.v2();
    private readonly tempColor: cc.Color = cc.color();
    private frameCount: number = 0;

    update(dt: number): void {
        // ✅ 复用预分配的向量
        this.tempVec2.x = this.node.x + 10 * dt;
        this.tempVec2.y = this.node.y;
        this.node.setPosition(this.tempVec2);

        // ✅ 节流昂贵操作
        this.frameCount++;
        if (this.frameCount % 10 === 0) {
            this.expensiveOperation();
        }

        // ❌ 不要在 update 中创建新对象
        // const pos = cc.v2(this.node.x + 10, this.node.y); // 每帧创建新对象！
        // const arr = this.enemies.filter(e => e.active);    // 每帧创建新数组！
    }

    private expensiveOperation(): void {
        // 昂贵计算放这里
    }
}
```

### 资源释放策略

```typescript
// 场景切换时释放资源
cc.director.on(cc.Director.EVENT_BEFORE_SCENE_LOADING, () => {
    // 释放当前场景的动态资源
    cc.assetManager.releaseUnusedAssets();
});

// 定期清理缓存（Web/小游戏平台）
if (cc.assetManager.cacheManager) {
    cc.assetManager.cacheManager.clearLRU();
}
```

---

## 包体大小优化

### 目标：可试玩广告 <5MB

| 优化手段 | 预估节省 |
|----------|----------|
| 纹理压缩 | 40-60% |
| 音频压缩（MP3/OGG） | 30-50% |
| 移除未使用资源 | 10-30% |
| 代码压缩（uglify） | 20-40% |
| Spine 数据精简 | 10-20% |
| 字体子集化 | 50-80% |

### 具体措施

```
1. 纹理：
   - 使用 WebP 格式（Web 平台）
   - 启用纹理压缩
   - 降低不重要纹理分辨率
   - 9-slice 替代大背景

2. 音频：
   - 使用 MP3（44.1kHz → 22.05kHz）
   - 短音效用低采样率
   - 背景音乐考虑流式加载

3. 代码：
   - 构建时启用代码压缩
   - 移除 console.log（使用 CC_DEBUG）
   - Tree Shaking 移除未使用代码

4. 字体：
   - 使用 BMFont 替代 TTF
   - TTF 字体子集化（只包含用到的字符）
   - 中文字体特别大，优先 BMFont

5. Spine/DragonBones：
   - 降低关键帧采样率
   - 合并骨骼动画图集
   - 移除未使用的动画数据
```

---

## 构建发布优化

### 构建面板设置

```
项目 → 构建发布：

1. ✅ 内联所有 SpriteFrame（减少请求数）
2. ✅ 合并图集中的 SpriteFrame（合并 JSON）
3. ✅ 压缩纹理（启用纹理压缩）
4. ✅ MD5 Cache（缓存管理）
5. ✅ 代码压缩（Release 模式）

Web 平台特殊设置：
- 启用 WebGL 2.0（如目标浏览器支持）
- 使用 WebP 纹理格式
- 开启 GZIP 压缩（服务器端）
```

### 性能监控代码

```typescript
@ccclass
export default class PerfMonitor extends cc.Component {
    start(): void {
        if (CC_DEBUG) {
            cc.debug.setDisplayStats(true);
        }
    }

    // 在需要时输出性能信息
    logPerformance(): void {
        if (CC_DEBUG) {
            cc.log("DrawCall:", cc.renderer.drawCalls);
            cc.log("节点数:", cc.director.getTotalFrames());
        }
    }
}
```
