# 资源管理 — LayaAir 3.x

> 📖 LayaAir 3.x 资源加载基于 **Promise** 异步模式，替代 2.x 的 Handler 回调模式。

---

## 1. 基础加载 API

### 单资源加载
```typescript
// Promise 风格（推荐）
Laya.loader.load("resources/image.png").then((res: Laya.Texture) => {
    let img = new Laya.Image();
    img.texture = res;
    this.owner.addChild(img);
});

// async/await 风格
async onStart(): Promise<void> {
    const tex = await Laya.loader.load("resources/image.png");
    let sp = new Laya.Sprite();
    sp.texture = tex;
    this.owner.addChild(sp);
}
```

### 带类型加载
```typescript
Laya.loader.load(url, Laya.Loader.IMAGE).then((res) => { });
Laya.loader.load(url, Laya.Loader.JSON).then((json) => { });
Laya.loader.load(url, Laya.Loader.ATLAS).then(() => { });
```

### 多资源加载
```typescript
Laya.loader.load(["a.png", "b.json"]).then((results: any[]) => {
    // results 数组顺序对应传入的 url 数组
});

// 混合类型
Laya.loader.load([
    "image.jpg",
    { url: "config.json", type: Laya.Loader.JSON },
    { url: "ui.atlas", type: Laya.Loader.ATLAS },
]).then((results) => { });
```

### fetch（不解析不缓存）
```typescript
// 获取原始数据，不走引擎缓存
Laya.loader.fetch("data.json", "json").then((json: any) => {
    console.log(json);
});

Laya.loader.fetch("bin.dat", "arraybuffer").then((buf: ArrayBuffer) => { });
```

---

## 2. 常用资源类型

| 常量 | 类型 | 说明 |
|------|------|------|
| `Laya.Loader.IMAGE` | image | 图片/纹理 |
| `Laya.Loader.JSON` | json | JSON 数据 |
| `Laya.Loader.ATLAS` | atlas | 图集文件 |
| `Laya.Loader.HIERARCHY` | hierarchy | 场景/预制体（.ls/.lh） |
| `Laya.Loader.MATERIAL` | material | 材质文件 |
| `Laya.Loader.MESH` | mesh | 网格模型 |
| `Laya.Loader.TEXTURE2D` | texture2d | 2D 纹理 |
| `Laya.Loader.TEXTURECUBE` | texturecube | 立方体纹理 |
| `Laya.Loader.SPINE` | spine | Spine 骨骼动画 |
| `Laya.Loader.FONT` | font | 字体 |
| `Laya.Loader.SOUND` | sound | 音频 |

---

## 3. 获取缓存资源

```typescript
// load 后从缓存获取
Laya.loader.load("res/img.png").then(() => {
    let tex = Laya.loader.getRes("res/img.png") as Laya.Texture;
});

// 检查资源是否已加载
if (Laya.loader.getRes("res.png")) {
    // 已加载，直接使用
}
```

---

## 4. 资源释放

```typescript
// 释放单个资源
Laya.loader.clearRes("res/img.png");

// 清除纹理资源
Laya.loader.clearTextureRes("res/img.png");

// 场景级释放
Laya.Scene.destroy("scene.ls");  // 销毁场景并释放关联资源
Laya.Scene.gc();                 // GC 未被引用的资源
```

### 资源释放最佳实践
```typescript
@regClass()
export class SceneScript extends Laya.Script {
    private _loadedUrls: string[] = [];

    async onStart(): Promise<void> {
        const urls = ["a.png", "b.json", "c.atlas"];
        this._loadedUrls = urls;
        await Laya.loader.load(urls);
    }

    onDestroy(): void {
        // 场景销毁时释放资源
        for (const url of this._loadedUrls) {
            Laya.loader.clearRes(url);
        }
        this._loadedUrls.length = 0;
    }
}
```

---

## 5. 预制体加载与实例化

```typescript
@regClass()
export class SpawnerScript extends Laya.Script {
    @property({ type: Laya.Prefab })
    public bulletPrefab: Laya.Prefab;

    // 方式一：通过 IDE 绑定 Prefab（推荐）
    fire(): void {
        if (this.bulletPrefab) {
            let bullet = this.bulletPrefab.create() as Laya.Sprite3D;
            this.owner.addChild(bullet);
        }
    }

    // 方式二：代码加载
    async loadAndSpawn(): Promise<void> {
        const prefab = await Laya.loader.load("prefab/Bullet.lh", Laya.Loader.HIERARCHY);
        let bullet = prefab.create() as Laya.Sprite3D;
        this.owner.addChild(bullet);
    }
}
```

---

## 6. 加载进度监听

```typescript
async loadWithProgress(): Promise<void> {
    const urls = ["a.png", "b.atlas", "c.json"];

    // 使用 Laya.loader.load 的第三个参数监听进度
    await Laya.loader.load(urls, null,
        Laya.Handler.create(this, (progress: number) => {
            console.log(`加载进度: ${Math.floor(progress * 100)}%`);
        }, null, false)
    );
}
```

---

## 7. 与 2.x 的对比

| 特性 | 3.x | 2.x |
|------|-----|-----|
| 返回值 | **Promise** | Handler 回调 |
| async/await | ✅ 支持 | ❌ 需要回调 |
| fetch | `Laya.loader.fetch()` | 无 |
| 场景格式 | `.ls` / `.lh` | `.scene` |
| 加载 API | `Laya.loader.load()` | `Laya.loader.load()` |
| 类型常量 | `Laya.Loader.IMAGE` 等 | `Laya.Loader.IMAGE` 等 |
