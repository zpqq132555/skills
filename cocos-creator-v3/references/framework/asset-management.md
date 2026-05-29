# 资源管理 — Cocos Creator 3.8

> 📖 本文件为 `cocos-creator-3x-cn` 技能参考文件，提供资源管理系统深入指导。

---

## 1. 资源管理架构

Cocos Creator 3.8 使用 **Asset Manager** 进行资源管理，核心模块：

| 模块 | 说明 |
|------|------|
| `resources` | 加载 `resources` 目录下的资源 |
| `assetManager` | 全局资源管理器，加载远程/Bundle/自定义资源 |
| `AssetManager.Bundle` | Asset Bundle 实例，模块化资源加载 |

---

## 2. resources 动态加载

### 2.1 基础加载

```typescript
import { resources, Prefab, instantiate, SpriteFrame, Sprite, AudioClip, AnimationClip, Animation, JsonAsset } from 'cc';

// 加载 Prefab
resources.load('prefabs/enemy', Prefab, (err, prefab) => {
    if (err) { console.error(err); return; }
    const node = instantiate(prefab);
    this.node.addChild(node);
});

// 加载 SpriteFrame（注意路径包含子资源名）
resources.load('images/hero/spriteFrame', SpriteFrame, (err, sf) => {
    this.getComponent(Sprite)!.spriteFrame = sf;
});

// 加载 Texture2D
resources.load('images/bg/texture', Texture2D, (err, texture) => {
    const sf = new SpriteFrame();
    sf.texture = texture;
});

// 加载 JSON
resources.load('configs/level1', JsonAsset, (err, json) => {
    const data = json.json;
});

// 加载音频
resources.load('audio/bgm', AudioClip, (err, clip) => { /* ... */ });

// 加载动画
resources.load('anims/run', AnimationClip, (err, clip) => {
    this.getComponent(Animation)!.addClip(clip, 'run');
});
```

### 2.2 图集 SpriteFrame

```typescript
import { SpriteAtlas } from 'cc';

resources.load('atlas/ui', SpriteAtlas, (err, atlas) => {
    const frame = atlas.getSpriteFrame('btn_normal');
    this.getComponent(Sprite)!.spriteFrame = frame;
});
```

### 2.3 批量加载

```typescript
// 加载目录下所有资源
resources.loadDir('textures', (err, assets) => {
    console.log('Loaded', assets.length, 'assets');
});

// 指定类型
resources.loadDir('textures', SpriteFrame, (err, assets) => {
    // assets: SpriteFrame[]
});
```

### 2.4 预加载

```typescript
// 预加载（只下载不解析，性能消耗低）
resources.preload('images/boss/spriteFrame', SpriteFrame);

// 后续正常加载会复用预加载的数据，加载更快
resources.load('images/boss/spriteFrame', SpriteFrame, (err, sf) => {
    // 立即可用
});

// 批量预加载
resources.preloadDir('effects', SpriteFrame);
```

---

## 3. Asset Bundle

### 3.1 概述

Asset Bundle 是资源模块化工具，允许按需加载资源模块，减少首包大小。

**内置 Bundle**:

| Bundle | 优先级 | 说明 |
|--------|--------|------|
| `internal` | 21 | 引擎内置默认资源 |
| `start-scene` | 20 | 首场景分包 |
| `resources` | 8 | resources 目录资源 |
| `main` | 7 | 参与构建的场景及依赖 |

### 3.2 加载 Bundle

```typescript
import { assetManager, Prefab, director } from 'cc';

// 通过名称加载
assetManager.loadBundle('gameBundle', (err, bundle) => {
    if (err) { console.error(err); return; }
    
    // 加载 Bundle 中的资源
    bundle.load('prefabs/player', Prefab, (err, prefab) => {
        const node = instantiate(prefab);
        director.getScene()!.addChild(node);
    });
});

// 通过远程 URL 加载
assetManager.loadBundle('https://cdn.example.com/bundles/remote', (err, bundle) => {
    bundle.load('xxx', Prefab, (err, prefab) => { /* ... */ });
});

// 带版本号加载（热更新）
assetManager.loadBundle('gameBundle', { version: 'abc123' }, (err, bundle) => {
    // 跳过缓存，加载指定版本
});

// 获取已加载的 Bundle
const bundle = assetManager.getBundle('gameBundle');
```

### 3.3 Bundle 资源加载

```typescript
const bundle = assetManager.getBundle('gameBundle')!;

// 加载单个资源
bundle.load('prefabs/enemy', Prefab, (err, prefab) => { /* ... */ });

// 加载 SpriteFrame
bundle.load('images/icon/spriteFrame', SpriteFrame, (err, sf) => { /* ... */ });

// 批量加载
bundle.loadDir('textures', Texture2D, (err, textures) => { /* ... */ });

// 加载场景
bundle.loadScene('level1', (err, scene) => {
    director.runScene(scene);
});

// 预加载
bundle.preload('prefabs/boss', Prefab);
bundle.preloadDir('effects');
```

### 3.4 Bundle 释放与移除

```typescript
const bundle = assetManager.getBundle('gameBundle')!;

// 释放单个资源
bundle.release('images/icon', SpriteFrame);

// 释放所有资源（慎用！包括外部依赖）
bundle.releaseAll();

// 移除 Bundle（先释放资源，再移除）
bundle.releaseAll();
assetManager.removeBundle(bundle);
```

---

## 4. 资源释放

### 4.1 手动释放

```typescript
import { assetManager } from 'cc';

// 释放单个资源（自动处理依赖）
assetManager.releaseAsset(asset);
```

### 4.2 引用计数管理

```typescript
// 动态加载的资源，引用计数初始为 0
resources.load('img/spriteFrame', SpriteFrame, (err, sf) => {
    // 需要长期持有时，增加引用
    sf.addRef();
    this._spriteFrame = sf;
    this.getComponent(Sprite)!.spriteFrame = sf;
});

// 不再使用时，减少引用
onDestroy() {
    if (this._spriteFrame) {
        this._spriteFrame.decRef();
        this._spriteFrame = null;
    }
}
```

**引用计数规则**:
- 加载完成后，资源引用计数初始为 0
- 资源的静态依赖会自动被统计（引擎自动处理依赖资源的引用计数）
- 动态引用（脚本中 `load` 后赋值给组件）需要手动 `addRef`/`decRef`
- 引用计数归 0 时，引擎会尝试自动释放

### 4.3 场景自动释放

在编辑器中，选中场景节点 → 属性检查器 → 勾选 **自动释放资源**。
切换场景时会自动释放该场景所有依赖资源。

**建议**: 除高频使用的主场景外，其他场景都勾选自动释放。

---

## 5. 远程资源加载

```typescript
import { assetManager, ImageAsset, Texture2D, SpriteFrame } from 'cc';

// 远程图片（带后缀名）
assetManager.loadRemote<ImageAsset>('https://example.com/avatar.png', (err, imageAsset) => {
    const texture = new Texture2D();
    texture.image = imageAsset;
    const sf = new SpriteFrame();
    sf.texture = texture;
});

// 远程图片（无后缀名需指定 ext）
assetManager.loadRemote<ImageAsset>('https://example.com/img?id=123', { ext: '.png' }, (err, imageAsset) => {
    // ...
});

// 远程音频
assetManager.loadRemote('https://example.com/sfx.mp3', (err, clip) => { /* ... */ });

// 远程文本
assetManager.loadRemote('https://example.com/data.txt', (err, textAsset) => { /* ... */ });

// 本地绝对路径（原生平台）
assetManager.loadRemote<ImageAsset>('/storage/emulated/0/image.png', (err, img) => { /* ... */ });
```

**限制**:
- 仅支持原生资源类型（图片、音频、文本）
- 不支持直接加载 SpriteFrame、SpriteAtlas 等
- Web 端受 CORS 限制

---

## 6. 资源管理最佳实践

### 6.1 resources 目录规范

```
assets/
├── resources/         ← 仅放需要动态加载的资源
│   ├── prefabs/
│   ├── configs/
│   └── dynamic/
├── textures/          ← 静态引用的资源放外面
├── scenes/
└── scripts/
```

**规则**:
- 仅放 **需要脚本动态加载** 的资源
- 不需要 `resources.load` 的资源不要放入
- 放入 resources 会增大 `config.json` 并阻止构建时的资源剔除

### 6.2 加载错误处理

```typescript
resources.load('prefabs/player', Prefab, (err, prefab) => {
    if (err) {
        console.error('Failed to load prefab:', err.message);
        return;
    }
    // 安全使用
});
```

### 6.3 加载进度回调

```typescript
resources.load('prefabs/level', Prefab,
    (completed, total) => {
        const progress = completed / total;
        console.log(`Loading: ${(progress * 100).toFixed(0)}%`);
    },
    (err, prefab) => {
        // 完成
    }
);
```

### 6.4 资源释放清单

| 场景 | 推荐方案 |
|------|---------|
| 场景切换 | 勾选场景自动释放 |
| 动态加载并长期持有 | `addRef` + `decRef` |
| 临时加载（一次性使用） | 用完后 `assetManager.releaseAsset()` |
| Bundle 不再需要 | `bundle.releaseAll()` + `removeBundle()` |
| 对象池资源 | 池销毁时统一 `decRef` |
