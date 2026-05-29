# Cocos Creator 2.4 资源管理

> 官方文档：https://docs.cocos.com/creator/2.4/manual/zh/asset-manager/

## 目录

- [cc.resources 动态加载](#cc-resources-动态加载)
- [cc.assetManager 资源管理器](#cc-assetManager)
- [Asset Bundle](#asset-bundle)
- [预加载](#预加载)
- [资源释放](#资源释放)
- [远程资源加载](#远程资源加载)
- [场景管理](#场景管理)
- [最佳实践](#最佳实践)

---

## cc.resources 动态加载

> **注意**：从 v2.4 开始，`cc.loader` 不再推荐使用，请统一使用 `cc.resources` 和 `cc.assetManager`。

### 加载单个资源

```typescript
// 加载 Prefab
cc.resources.load("prefabs/enemy", cc.Prefab, (err, prefab) => {
    if (err) {
        cc.error("加载 Prefab 失败:", err);
        return;
    }
    const node = cc.instantiate(prefab);
    node.parent = this.node;
});

// 加载 SpriteFrame（注意：必须指定类型为 cc.SpriteFrame）
cc.resources.load("textures/hero", cc.SpriteFrame, (err, spriteFrame) => {
    if (err) { cc.error(err); return; }
    this.getComponent(cc.Sprite).spriteFrame = spriteFrame;
});

// 加载 AudioClip
cc.resources.load("audio/bgm", cc.AudioClip, (err, clip) => {
    if (err) { cc.error(err); return; }
    cc.audioEngine.playMusic(clip, true);
});

// 加载 JsonAsset
cc.resources.load("data/config", cc.JsonAsset, (err, jsonAsset) => {
    if (err) { cc.error(err); return; }
    const data = jsonAsset.json;
});

// 加载 AnimationClip
cc.resources.load("animations/run", cc.AnimationClip, (err, clip) => {
    if (err) { cc.error(err); return; }
    this.getComponent(cc.Animation).addClip(clip, "run");
});
```

### 加载图集中的 SpriteFrame

```typescript
// 加载 SpriteAtlas，再获取其中的 SpriteFrame
cc.resources.load("atlas/ui", cc.SpriteAtlas, (err, atlas) => {
    if (err) { cc.error(err); return; }
    const frame = atlas.getSpriteFrame("btn_normal");
    this.getComponent(cc.Sprite).spriteFrame = frame;
});
```

### 批量加载

```typescript
// 加载目录下所有资源
cc.resources.loadDir("prefabs/enemies", cc.Prefab, (err, prefabs) => {
    if (err) { cc.error(err); return; }
    prefabs.forEach((prefab) => {
        cc.log("已加载:", prefab.name);
    });
});

// 加载目录下特定类型
cc.resources.loadDir("textures/icons", cc.SpriteFrame, (err, frames) => {
    if (err) { cc.error(err); return; }
    // frames 数组包含所有 SpriteFrame
});

// 带进度回调
cc.resources.loadDir(
    "prefabs",
    cc.Prefab,
    (completedCount, totalCount, item) => {
        const progress = completedCount / totalCount;
        this.progressBar.progress = progress;
    },
    (err, prefabs) => {
        if (err) { cc.error(err); return; }
        cc.log("全部加载完成");
    }
);
```

### ⚠️ 重要规则

1. 所有动态加载的资源**必须**放在 `resources` 文件夹下
2. 路径**不包含**文件扩展名
3. 路径相对于 `resources` 目录
4. 资源加载是**异步**的，必须在回调中获取

---

## cc.assetManager

```typescript
// cc.assetManager 是全局资源管理器，提供更底层的 API

// 通过 UUID 加载
cc.assetManager.loadAny({ uuid: "xxxxx-xxxxx" }, (err, asset) => {
    // ...
});

// 加载远程资源
cc.assetManager.loadRemote("http://example.com/image.png", (err, texture) => {
    if (err) { cc.error(err); return; }
    const spriteFrame = new cc.SpriteFrame(texture);
    this.getComponent(cc.Sprite).spriteFrame = spriteFrame;
});

// 释放资源
cc.assetManager.releaseAsset(asset);
```

---

## Asset Bundle

> Asset Bundle 是 v2.4 新增的资源模块化方案

```typescript
// 加载内置 Bundle
cc.assetManager.loadBundle("testBundle", (err, bundle) => {
    if (err) { cc.error(err); return; }

    // 从 Bundle 中加载资源
    bundle.load("textures/background", cc.SpriteFrame, (err, frame) => {
        if (err) { cc.error(err); return; }
        this.getComponent(cc.Sprite).spriteFrame = frame;
    });

    // 从 Bundle 中加载场景
    bundle.loadScene("BundleScene", (err, scene) => {
        cc.director.runScene(scene);
    });
});

// 加载远程 Bundle
cc.assetManager.loadBundle(
    "https://example.com/remote-bundle",
    { version: "1.0.0" },
    (err, bundle) => {
        // 使用 bundle
    }
);

// 释放 Bundle
const bundle = cc.assetManager.getBundle("testBundle");
if (bundle) {
    bundle.releaseAll();
    cc.assetManager.removeBundle(bundle);
}
```

---

## 预加载

```typescript
// 预加载资源（只下载，不反序列化，性能消耗小）
cc.resources.preload("textures/hero", cc.SpriteFrame);

// 之后正常加载时会复用已下载的内容
cc.resources.load("textures/hero", cc.SpriteFrame, (err, frame) => {
    // 加载更快，因为已经预加载
});

// 预加载目录
cc.resources.preloadDir("prefabs/enemies", cc.Prefab);

// 预加载场景
cc.director.preloadScene("GameScene", (err) => {
    if (err) { cc.error(err); return; }
    cc.log("场景预加载完成");
    // 之后加载场景会更快
    cc.director.loadScene("GameScene");
});
```

---

## 资源释放

### 基于引用计数的释放（v2.4 推荐）

```typescript
// 释放单个资源
cc.resources.release("textures/hero", cc.SpriteFrame);

// 通过 Asset 实例释放
cc.assetManager.releaseAsset(spriteFrame);

// 动态加载的资源需要手动管理引用计数
cc.resources.load("textures/armor", cc.SpriteFrame, (err, spriteFrame) => {
    if (err) { cc.error(err); return; }

    // ✅ 增加引用（防止被其他地方误释放）
    spriteFrame.addRef();
    this._armorFrame = spriteFrame;
});

// 不再需要时
onDestroy(): void {
    if (this._armorFrame) {
        // ✅ 减少引用（引用计数为 0 时自动释放）
        this._armorFrame.decRef();
        this._armorFrame = null;
    }
}
```

### 批量释放

```typescript
// 释放 resources 中某路径的所有资源
cc.resources.releaseDir("textures/enemies");

// 释放未使用的资源
cc.assetManager.releaseUnusedAssets();
```

---

## 远程资源加载

```typescript
// 加载远程图片（带后缀名）
cc.assetManager.loadRemote(
    "http://example.com/avatar.png",
    (err, texture: cc.Texture2D) => {
        if (err) { cc.error(err); return; }
        const frame = new cc.SpriteFrame(texture);
        this.getComponent(cc.Sprite).spriteFrame = frame;
    }
);

// 不带后缀名时必须指定类型
cc.assetManager.loadRemote(
    "http://example.com/avatar?id=123",
    { ext: ".png" },
    (err, texture) => {
        // ...
    }
);

// 加载远程音频
cc.assetManager.loadRemote(
    "http://example.com/bgm.mp3",
    (err, clip: cc.AudioClip) => {
        cc.audioEngine.playMusic(clip, true);
    }
);

// ⚠️ 限制：
// 1. 只支持原生资源（图片、音频、文本），不支持 SpriteFrame、Prefab 等
// 2. Web 端受 CORS 跨域策略限制
// 3. 如需加载所有类型，使用 Asset Bundle
```

---

## 场景管理

```typescript
// 加载并切换场景
cc.director.loadScene("GameScene");

// 带回调的场景加载
cc.director.loadScene("GameScene", (err, scene) => {
    if (err) { cc.error(err); return; }
    cc.log("场景加载完成");
});

// 预加载场景
cc.director.preloadScene("GameScene", () => {
    // 预加载完成，可在需要时快速切换
});

// 获取当前场景
const scene = cc.director.getScene();

// 跨场景节点保留（不随场景切换销毁）
cc.game.addPersistRootNode(this.node);

// 取消跨场景保留
cc.game.removePersistRootNode(this.node);
```

---

## 最佳实践

### ✅ 要做

1. **使用 cc.resources / cc.assetManager** → 不再使用 cc.loader
2. **动态资源使用 addRef/decRef** → 避免被意外释放
3. **预加载下一关资源** → 减少加载等待时间
4. **onDestroy 释放动态资源** → 防止内存泄漏
5. **只把必需资源放 resources** → 减少包体大小
6. **使用 Asset Bundle** → 实现资源模块化和远程加载
7. **错误处理** → 所有加载回调检查 err 参数

### ❌ 不要

1. **使用 cc.loader（已废弃）** → 使用 cc.resources/cc.assetManager
2. **resources 放过多资源** → 会增大 config.json，影响构建
3. **忘记释放动态加载的资源** → 内存不断增长
4. **同步方式思考异步加载** → 必须在回调中使用资源
5. **频繁加载/释放同一资源** → 使用缓存或 addRef 保持引用
