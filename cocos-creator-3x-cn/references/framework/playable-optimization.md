# 可试玩广告优化 — Cocos Creator 3.8

> 📖 本文件为 `cocos-creator-3x-cn` 技能参考文件，提供可试玩广告的包体与性能优化指导。

---

## 1. 可试玩广告概述

可试玩广告 (Playable Ad) 是一种交互式广告格式，通常要求：
- **单文件 HTML** 输出（内联所有资源）
- **包体限制**: 2MB-5MB（根据平台要求）
- **快速加载**: 3 秒内可交互
- **全程流畅**: 30fps+ 无卡顿

---

## 2. 包体优化策略

### 2.1 引擎模块裁剪

在 **项目设置 → 功能裁剪** 中关闭不需要的模块：

| 可安全关闭的模块 | 节省大小 |
|----------------|---------|
| 3D 相关（Mesh/Skinning/Animation3D） | ≈200KB |
| 物理系统（不需要时） | ≈150KB |
| 粒子系统（不需要时） | ≈100KB |
| 地形系统 | ≈50KB |
| WebSocket/SocketIO | ≈30KB |
| 原生渲染器 | ≈100KB |
| DragonBones/Spine | ≈80KB |

### 2.2 资源压缩

```
图片压缩优先级:
1. 使用 TinyPNG/Squoosh 压缩 PNG → 通常减少 60-80%
2. 考虑 JPEG 替代透明度不重要的大图
3. 使用图集合并碎图（减少 draw call + JSON 合并）
4. 降低分辨率：2048→1024 或 1024→512
5. 使用 2 的幂次方尺寸（GPU 友好）
```

### 2.3 代码优化

```typescript
// ✅ 使用 import 按需导入（tree-shaking 友好）
import { _decorator, Component, tween, Vec3 } from 'cc';

// ❌ 避免导入不使用的模块
// import * as cc from 'cc';

// ✅ 使用 const enum 替代 Enum（编译后内联为数值）
const enum GameState {
    Idle = 0,
    Playing = 1,
    GameOver = 2,
}

// ✅ 使用 DEBUG 宏排除调试代码
import { DEBUG } from 'cc/env';
if (DEBUG) {
    console.log('debug info');
}
```

### 2.4 构建配置

构建发布面板关键设置：
- **压缩纹理**: 启用，选择合适格式（WebP/ASTC/ETC2）
- **MD5 Cache**: 可试玩广告不需要，关闭
- **内联所有 SpriteFrame**: 启用
- **合并所有 JSON**: 启用（Asset Bundle 压缩类型选"合并所有 JSON"）
- **勾选 Zip 压缩**: 根据平台（Web 可不用）
- **Source Maps**: 禁用

---

## 3. 性能优化策略

### 3.1 Draw Call 优化

```typescript
// 1. 使用图集（SpriteAtlas）合并同材质精灵
// 2. 使用自动图集功能

// 3. 手动管理合批
// 同一图集 + 同一材质 + 相邻渲染顺序 = 自动合批

// 4. 避免打断合批的操作：
// - 不同材质/纹理的穿插
// - 使用 Mask 组件
// - 修改渲染状态
```

### 3.2 内存优化

```typescript
// 1. 对象池减少 GC
import { NodePool, instantiate, Prefab } from 'cc';

class BulletPool {
    private _pool = new NodePool('Bullet');
    private _prefab: Prefab | null = null;

    public init(prefab: Prefab) {
        this._prefab = prefab;
        // 预热
        for (let i = 0; i < 10; i++) {
            const node = instantiate(prefab);
            this._pool.put(node);
        }
    }

    public get(): Node {
        if (this._pool.size() > 0) {
            return this._pool.get()!;
        }
        return instantiate(this._prefab!);
    }

    public put(node: Node) {
        this._pool.put(node);
    }

    public clear() {
        this._pool.clear();
    }
}

// 2. 避免 update 中创建临时对象
// ❌
update(dt: number) {
    const pos = new Vec3(this.node.position);  // 每帧创建
}
// ✅
private _tempVec3 = new Vec3();
update(dt: number) {
    Vec3.copy(this._tempVec3, this.node.position);
}
```

### 3.3 渲染优化

```typescript
// 1. 减少透明节点数量
// 2. 合理使用 Canvas 分层
// 3. 避免频繁更新 Label（使用 BMFont 替代动态字体）
// 4. 使用 Cache Mode = CHAR 减少 Label 纹理

// 5. 控制节点树深度，减少递归遍历
// 6. 隐藏不可见节点（active = false 比 opacity = 0 更高效）
node.active = false; // ✅ 跳过渲染和更新
```

### 3.4 逻辑优化

```typescript
// 1. 减少 find/getComponent 调用频率
// ❌ 每帧查找
update() {
    const sprite = find('Canvas/Player')?.getComponent(Sprite);
}
// ✅ 缓存引用
private _sprite: Sprite | null = null;
start() {
    this._sprite = find('Canvas/Player')?.getComponent(Sprite) ?? null;
}

// 2. 使用 schedule 替代 update 中的低频逻辑
start() {
    this.schedule(this.checkEnemies, 0.5); // 每 0.5 秒检查一次
}

// 3. 使用位运算优化频繁计算
const LAYER_ENEMY = 1 << 0;
const LAYER_BULLET = 1 << 1;
function canCollide(a: number, b: number): boolean {
    return (a & b) !== 0;
}
```

---

## 4. 可试玩广告特定优化

### 4.1 启动优化

```typescript
// 1. 首屏资源最小化
// 只加载第一帧需要的资源，其余异步加载

// 2. 使用加载界面遮罩异步加载
@ccclass('LoadingScreen')
export class LoadingScreen extends Component {
    protected start() {
        const tasks = [
            this.loadPrefabs(),
            this.loadAudio(),
            this.loadTextures(),
        ];
        Promise.all(tasks).then(() => {
            this.startGame();
        });
    }

    private loadPrefabs(): Promise<void> {
        return new Promise((resolve) => {
            resources.loadDir('prefabs', Prefab, (err, prefabs) => {
                resolve();
            });
        });
    }
}
```

### 4.2 CTA (Call To Action)

```typescript
// 安装按钮跳转
function gotoStore() {
    const url = 'https://play.google.com/store/apps/details?id=com.example.game';
    if (typeof window !== 'undefined') {
        // 广告 SDK 提供的跳转方法
        if ((window as any).mraid) {
            (window as any).mraid.open(url);
        } else {
            window.open(url);
        }
    }
}
```

### 4.3 包体检查清单

- [ ] 引擎模块裁剪完成
- [ ] 图片全部压缩（TinyPNG/WebP）
- [ ] 音频格式优化（MP3 CBR 64kbps 或更低）
- [ ] 删除未使用的资源
- [ ] DEBUG 代码通过宏排除
- [ ] console.log 在构建版本中移除
- [ ] Source Maps 关闭
- [ ] JSON 合并启用
- [ ] 最终 HTML 文件大小 ≤ 目标限制

---

## 5. 平台特定注意事项

| 平台 | 包体限制 | 特殊要求 |
|------|---------|---------|
| Facebook | 2MB (HTML) / 5MB (ZIP) | 需要 MRAID 合规 |
| Google Ads | 5MB (ZIP) | 支持多文件 |
| Unity Ads | 5MB | 单 HTML 文件 |
| IronSource | 5MB | 单 HTML 文件 |
| AppLovin | 5MB | 支持 MRAID |
| TikTok | 2MB (单文件) / 5MB (多文件) | 需要 SDK 回调 |
