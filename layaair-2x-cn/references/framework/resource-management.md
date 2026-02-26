# 资源管理 — LayaAir 2.0

> 📖 LayaAir 2.0 使用 `Laya.loader` 统一管理所有资源加载，支持预加载、缓存和释放。

---

## 1. 加载类型常量

| 常量 | 说明 | 资源类型 |
|------|------|---------|
| `Laya.Loader.IMAGE` | 图片 | .png/.jpg |
| `Laya.Loader.ATLAS` | 图集 | .atlas/.json |
| `Laya.Loader.SOUND` | 音频 | .mp3/.ogg |
| `Laya.Loader.JSON` | JSON | .json |
| `Laya.Loader.TEXT` | 文本 | .txt |
| `Laya.Loader.XML` | XML | .xml |
| `Laya.Loader.BUFFER` | 二进制 | .bin/.sk |
| `Laya.Loader.BITMAP_FONT` | 位图字体 | .fnt |
| `Laya.Loader.PREFAB` | 场景预制体 | .lh/.scene |

---

## 2. 批量加载（推荐）

```typescript
class LoadingScene extends Laya.Scene {
    onStart(): void {
        const assets = [
            { url: "res/atlas/game.atlas",  type: Laya.Loader.ATLAS },
            { url: "res/atlas/ui.atlas",    type: Laya.Loader.ATLAS },
            { url: "res/config/hero.json",  type: Laya.Loader.JSON },
            { url: "res/sound/bgm.mp3",     type: Laya.Loader.SOUND },
        ];

        Laya.loader.load(
            assets,
            Laya.Handler.create(this, this.onAllLoaded),
            Laya.Handler.create(this, this.onProgress, null, false)
        );
    }

    private onProgress(progress: number): void {
        // progress: 0 ~ 1
        const pct = Math.floor(progress * 100);
        // 更新进度条
    }

    private onAllLoaded(): void {
        // 获取已缓存的资源
        const heroData = Laya.loader.getRes("res/config/hero.json");
        // 切换到游戏场景
        Laya.Scene.open("res/scene/game.scene");
    }
}
```

---

## 3. 单个资源加载

```typescript
// 加载图片
Laya.loader.load("res/img/reward.png", Laya.Handler.create(this, (tex: Laya.Texture) => {
    const img = new Laya.Image();
    img.texture = tex;
    Laya.stage.addChild(img);
}));

// 加载 JSON 配置
Laya.loader.load("res/config/levelConfig.json", Laya.Handler.create(this, (data: any) => {
    if (!data) {
        console.error("Failed to load level config!");
        return;
    }
    this.setupLevel(data);
}), null, Laya.Loader.JSON);

// 加载图集
Laya.loader.load("res/atlas/effects.atlas", Laya.Handler.create(this, () => {
    // 图集加载后，可以从中获取帧纹理
    const frameTex = Laya.loader.getRes("res/atlas/effects.atlas#explosion_01") as Laya.Texture;
}), null, Laya.Loader.ATLAS);
```

---

## 4. 从缓存获取资源

```typescript
// 获取图片 Texture
const texture = Laya.loader.getRes("res/img/hero.png") as Laya.Texture;

// 获取图集帧
const frameTex = Laya.loader.getRes("res/atlas/game.atlas#hero_run_0") as Laya.Texture;

// 获取 JSON 数据
const config = Laya.loader.getRes("res/config/data.json");

// 检查是否已加载（避免重复加载）
if (!Laya.loader.getRes("res/img/hero.png")) {
    Laya.loader.load("res/img/hero.png", Laya.Handler.create(this, callback));
}
```

---

## 5. 资源释放策略

```typescript
// 释放单个资源
Laya.loader.clearRes("res/img/hero.png");

// 释放图片（含 GPU 纹理）
Laya.loader.clearTextureRes("res/img/hero.png");

// 按场景释放（最佳实践）
class GameScene extends Laya.Scene {
    // 场景关闭时释放相关资源
    close(): void {
        // 释放该场景独有的资源
        const sceneAssets = [
            "res/atlas/game.atlas",
            "res/img/background.jpg",
        ];
        for (const url of sceneAssets) {
            Laya.loader.clearRes(url);
            Laya.loader.clearTextureRes(url);
        }
        super.close();
    }
}

// 进入主界面时释放游戏资源
private switchToMainMenu(): void {
    // 1. 先加载主界面资源
    Laya.loader.load(mainMenuAssets, Laya.Handler.create(this, () => {
        // 2. 再释放游戏资源（防止资源闪烁）
        for (const url of gameAssets) {
            Laya.loader.clearRes(url);
        }
        Laya.Scene.open("res/scene/mainMenu.scene");
    }));
}
```

---

## 6. 图集（Atlas）最佳实践

```typescript
// 图集路径格式：{atlasUrl}#{frameName}
const tex = Laya.loader.getRes("res/atlas/game.atlas#enemy_01") as Laya.Texture;

// 获取图集中所有帧（按前缀过滤）
const atlas = Laya.loader.getRes("res/atlas/game.atlas") as any;
// atlas.textures 包含所有子图片的 key → Texture 映射

// 使用图集做动画
const frames: Laya.Texture[] = [];
for (let i = 0; i < 8; i++) {
    frames.push(Laya.loader.getRes(`res/atlas/game.atlas#run_${i.toString().padStart(2,"0")}`) as Laya.Texture);
}
const anim = new Laya.Animation();
anim.loadImages(frames);
anim.interval = 50; // 每帧间隔（毫秒）
anim.play();
```

---

## 7. 位图字体（BitmapFont）

```typescript
// 1. 注册位图字体
Laya.BitmapFont.registerFont("myFont", Laya.loader.getRes("res/font/score.fnt"));

// 2. 在 Text 中使用
const txt = new Laya.Text();
txt.font = "myFont";
txt.fontSize = 32;
txt.text = "9999";
```

---

## 8. 分阶段加载策略（常见于可试玩广告）

```typescript
enum LoadStage { BOOT, GAME, UI }

class ResourceManager {
    // 启动资源（最小化，快速显示）
    private static BOOT_ASSETS = [
        { url: "res/atlas/loading.atlas", type: Laya.Loader.ATLAS },
        { url: "res/config/boot.json",    type: Laya.Loader.JSON },
    ];

    // 游戏资源
    private static GAME_ASSETS = [
        { url: "res/atlas/game.atlas",  type: Laya.Loader.ATLAS },
        { url: "res/config/game.json",  type: Laya.Loader.JSON },
        { url: "res/sound/bgm.mp3",     type: Laya.Loader.SOUND },
    ];

    public static loadStage(stage: LoadStage, onComplete: () => void): void {
        let assets: any[];
        switch (stage) {
            case LoadStage.BOOT: assets = this.BOOT_ASSETS; break;
            case LoadStage.GAME: assets = this.GAME_ASSETS; break;
            default: assets = []; break;
        }
        if (assets.length === 0) {
            onComplete();
            return;
        }
        Laya.loader.load(assets, Laya.Handler.create(null, onComplete));
    }
}
```

---

## 9. 开发常见问题

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| `getRes()` 返回 `null` | 资源未加载或路径错误 | 检查路径大小写，确认已加载 |
| 切换场景后内存未释放 | 未调用 `clearRes` | 场景关闭时主动释放 |
| 图集帧找不到 | 帧名与图集不符 | 检查 `.atlas` 文件中的帧名 |
| 重复加载同一资源 | 未检查缓存 | `getRes()` 先判断再 `load()` |
