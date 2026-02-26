# 资源管理 — LayaAir 1.0

> 📖 LayaAir 1.0 使用 `Laya.loader` 统一管理资源加载。与 2.0 加载 API 基本一致，但 1.0 需要手动引入各模块（`laya.core.js`、`laya.ui.js` 等）。

---

## 1. 加载类型常量

| 常量 | 说明 |
|------|------|
| `Laya.Loader.IMAGE` | 图片 |
| `Laya.Loader.ATLAS` | 图集 |
| `Laya.Loader.SOUND` | 音频 |
| `Laya.Loader.JSON` | JSON |
| `Laya.Loader.TEXT` | 文本 |
| `Laya.Loader.XML` | XML |
| `Laya.Loader.BUFFER` | 二进制（骨骼动画等） |
| `Laya.Loader.BITMAP_FONT` | 位图字体 |

---

## 2. 批量加载

```typescript
class Main {
    constructor() {
        // 初始化引擎
        Laya.init(750, 1334, Laya.WebGL);
        Laya.stage.scaleMode = "showall";

        // 批量加载资源
        const assets = [
            { url: "res/atlas/game.atlas",  type: Laya.Loader.ATLAS },
            { url: "res/atlas/ui.atlas",    type: Laya.Loader.ATLAS },
            { url: "res/config/data.json",  type: Laya.Loader.JSON },
            { url: "res/sound/bgm.mp3",     type: Laya.Loader.SOUND },
        ];

        Laya.loader.load(
            assets,
            Laya.Handler.create(this, this.onLoaded),
            Laya.Handler.create(this, this.onProgress, null, false)  // false=持久 Handler
        );
    }

    private onProgress(progress: number): void {
        // 0.0 ~ 1.0
    }

    private onLoaded(): void {
        // 所有资源就绪，启动游戏
        const game = new GameView();
        Laya.stage.addChild(game);
    }
}

new Main();
```

---

## 3. 获取缓存资源

```typescript
// 获取 Texture
const tex = Laya.loader.getRes("res/img/hero.png") as Laya.Texture;

// 获取图集帧 Texture（格式：atlasUrl + '#' + frameName）
const frameTex = Laya.loader.getRes("res/atlas/game.atlas#hero_stand") as Laya.Texture;

// 获取 JSON 数据
const config = Laya.loader.getRes("res/config/data.json") as any;

// 获取二进制数据（骨骼动画）
const skData = Laya.loader.getRes("res/ani/role.sk");
```

---

## 4. 单个资源加载

```typescript
// 动态加载单个图片
Laya.loader.load("res/img/reward.png", Laya.Handler.create(this, (tex: Laya.Texture) => {
    if (!tex) {
        console.error("Failed to load reward.png");
        return;
    }
    const sp = new Laya.Sprite();
    sp.graphics.drawTexture(tex, 0, 0);
    Laya.stage.addChild(sp);
}));

// 动态加载 JSON
Laya.loader.load("res/config/level2.json",
    Laya.Handler.create(this, (data: any) => {
        this.setupLevel(data);
    }), null, Laya.Loader.JSON);
```

---

## 5. 骨骼动画资源

```typescript
// 骨骼动画需要加载 3 个文件
const skAssets = [
    { url: "res/ani/hero.sk",    type: Laya.Loader.BUFFER },
    { url: "res/ani/hero.png",   type: Laya.Loader.IMAGE },
    { url: "res/ani/hero.atlas", type: Laya.Loader.TEXT },
];

Laya.loader.load(skAssets, Laya.Handler.create(this, () => {
    // 创建骨骼动画
    const sk = new Laya.Skeleton();
    Laya.stage.addChild(sk);

    // 通过 sk 加载数据
    sk.load("res/ani/hero.sk");
}));
```

---

## 6. 特殊资源类型

### 位图字体

```typescript
// 加载并注册
Laya.loader.load(
    [
        { url: "res/font/score.fnt",  type: Laya.Loader.BITMAP_FONT },
        { url: "res/font/score.png",  type: Laya.Loader.IMAGE },
    ],
    Laya.Handler.create(this, () => {
        const bitmapFont = Laya.loader.getRes("res/font/score.fnt") as Laya.BitmapFont;
        Laya.Text.registerBitmapFont("ScoreFont", bitmapFont);

        const txt = new Laya.Text();
        txt.font = "ScoreFont";
        txt.fontSize = 40;
        txt.text = "99999";
    })
);
```

### 声音资源

```typescript
// 预加载到缓存（推荐：避免播放延迟）
Laya.loader.load(
    [
        { url: "res/sound/click.mp3", type: Laya.Loader.SOUND },
        { url: "res/sound/bgm.mp3",   type: Laya.Loader.SOUND },
    ],
    Laya.Handler.create(this, () => {
        // 资源就绪后播放无延迟
        Laya.SoundManager.playMusic("res/sound/bgm.mp3", 0);
    })
);
```

---

## 7. 资源释放

```typescript
// 释放特定资源
Laya.loader.clearRes("res/img/hero.png");

// 释放图集及所有帧
Laya.loader.clearRes("res/atlas/game.atlas");

// 注意：1.0 没有 clearTextureRes，需手动管理纹理
// 纹理对象释放
const tex = Laya.loader.getRes("res/img/bigBg.png") as Laya.Texture;
if (tex) {
    tex.destroy();
    Laya.loader.clearRes("res/img/bigBg.png");
}
```

---

## 8. 分阶段加载（可试玩广告适用）

```typescript
class GameLoader {
    // 第一阶段：启动资源（尽量小，< 200KB）
    private static readonly BOOT = [
        { url: "res/atlas/ui.atlas",  type: Laya.Loader.ATLAS },
    ];

    // 第二阶段：游戏资源
    private static readonly GAME = [
        { url: "res/atlas/game.atlas", type: Laya.Loader.ATLAS },
        { url: "res/config/game.json", type: Laya.Loader.JSON },
    ];

    public static loadBoot(onComplete: () => void): void {
        Laya.loader.load(GameLoader.BOOT, Laya.Handler.create(null, onComplete));
    }

    public static loadGame(onComplete: () => void, onProgress?: (p: number) => void): void {
        Laya.loader.load(
            GameLoader.GAME,
            Laya.Handler.create(null, onComplete),
            onProgress ? Laya.Handler.create(null, onProgress, null, false) : null
        );
    }
}

// 使用
GameLoader.loadBoot(() => {
    showLoadingUI();
    GameLoader.loadGame(
        () => { startGame(); },
        (p) => { updateProgress(p); }
    );
});
```

---

## 9. 常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| `getRes()` 返回 `null` | 未加载 / 路径错误 | 检查路径，确保已调用 `load()` |
| 骨骼动画不显示 | 3 个文件未全部加载 | 确保 .sk/.png/.atlas 都已加载 |
| 音频播放延迟 | 未预加载 | 提前 `load()` 音频资源 |
| 图集帧 `null` | 帧名错误 | 检查 .atlas 文件中的实际帧名 |
| 内存溢出 | 资源未释放 | 场景切换时调用 `clearRes()` |
