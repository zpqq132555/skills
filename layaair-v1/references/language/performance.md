# 性能优化 — LayaAir 1.0

> LayaAir 1.0 性能优化核心：减少 DrawCall、使用对象池、启用 CacheAs、避免帧循环中的无效计算。

---

## 1. CacheAs 缓存渲染

```typescript
// 静态容器设置 bitmap 缓存，减少 DrawCall
const panel = new Laya.Sprite();
// ... 添加子节点
panel.cacheAs = "bitmap";     // 烘焙为位图，合并为 1 次 DrawCall

// 动态内容更新后需要重置
function updatePanel(): void {
    panel.cacheAs = "none";
    // 更新子节点...
    panel.cacheAs = "bitmap";
}

// 模式选择
// "bitmap"  → 完全静态的 UI 面板/背景（最优）
// "normal"  → 子节点少量动态（折中）
// "none"    → 频繁变化（默认，不缓存）
```

---

## 2. 对象池

```typescript
// 使用 Laya.Pool 复用频繁创建/销毁的对象
class BulletView extends Laya.Sprite {
    public speed: number = 8;

    public init(x: number, y: number): void {
        this.pos(x, y);
        this.visible = true;
        this.alpha = 1;
        // 重新启动帧循环
        Laya.timer.frameLoop(1, this, this._update);
    }

    private _update(): void {
        this.y -= this.speed;
        if (this.y < -50) {
            this._recycle();
        }
    }

    private _recycle(): void {
        Laya.timer.clearAll(this);       // 停止帧循环
        this.removeSelf();
        Laya.Pool.recover("bullet", this); // 归还到池中
    }

    // 注意：不调用 destroy，因为对象要被复用
}

class ShooterView extends Laya.Sprite {
    public fire(): void {
        // 从池中获取（或新建）
        const bullet = Laya.Pool.getItemByClass("bullet", BulletView) as BulletView;
        Laya.stage.addChild(bullet);
        bullet.init(this.x, this.y);
    }
}
```

---

## 3. 减少 DrawCall

```typescript
// 原则 1：合并同一图集内的 Sprite，一个图集 = 1 次 DrawCall
// 原则 2：关闭不需要鼠标事件的节点检测
sprite.mouseEnabled = false;
container.mouseThrough = true;

// 原则 3：隐藏节点用 visible 而非 alpha
node.visible = false;   // ✅ 不参与渲染
node.alpha = 0;         // ⚠️ 仍参与渲染管线

// 原则 4：避免同层多个 Graphics.drawRect 类操作（不进图集）
// 尽量将图形元素替换为图集中的纹理片
```

---

## 4. 帧循环性能优化

```typescript
// ❌ 低效写法
class EnemyView extends Laya.Sprite {
    constructor() {
        super();
        Laya.timer.frameLoop(1, this, this._update);
    }

    private _update(): void {
        // 每帧创建对象
        const arr = [this.x, this.y];  // ❌
        // 每帧查找节点
        const hero = Laya.stage.getChildByName("hero"); // ❌
        // 每帧做字符串拼接
        console.log("pos:" + this.x + "," + this.y);   // ❌
    }
}

// ✅ 高效写法
class EnemyView extends Laya.Sprite {
    private _heroRef: Laya.Sprite | null = null;
    private _speed: number = 4;
    private _isAlive: boolean = true;

    constructor() {
        super();
        // 预先缓存引用
        this._heroRef = Laya.stage.getChildByName("hero") as Laya.Sprite;
        Laya.timer.frameLoop(1, this, this._update);
    }

    private _update(): void {
        if (!this._isAlive || !this._heroRef) return; // 早退出
        const dx = this._heroRef.x - this.x;
        const dy = this._heroRef.y - this.y;
        const len = Math.sqrt(dx * dx + dy * dy);
        if (len < 5) return;
        this.x += (dx / len) * this._speed;
        this.y += (dy / len) * this._speed;
    }

    public destroy(destroyChild: boolean = true): void {
        Laya.timer.clearAll(this);
        Laya.Tween.clearAll(this);
        super.destroy(destroyChild);
    }
}
```

---

## 5. 内存管理

```typescript
// 原则 1：游戏场景切换时释放旧资源
function switchScene(newSceneCb: () => void): void {
    // 先加载新场景资源（防止闪屏）
    Laya.loader.load(newAssets, Laya.Handler.create(null, () => {
        // 再释放旧资源
        for (const url of oldAssets) {
            Laya.loader.clearRes(url);
        }
        newSceneCb();
    }));
}

// 原则 2：骨骼动画不使用时停止
sk.paused = true;  // 暂停而非销毁（如果之后还需要复用）

// 原则 3：Sprite 销毁时传 true 递归销毁
container.destroy(true);  // 递归销毁所有子节点

// 原则 4：大位图及时销毁
const largeTex = Laya.loader.getRes("res/img/bigBg.jpg") as Laya.Texture;
// 使用完毕
largeTex.destroy();
Laya.loader.clearRes("res/img/bigBg.jpg");
```

---

## 6. 图形质量 vs 性能

```typescript
// 引擎初始化时选择渲染模式
Laya.init(750, 1334, Laya.WebGL);   // WebGL（高性能，推荐）
Laya.init(750, 1334, Laya.Canvas);  // Canvas（兼容性好，性能较低）

// 帧率模式
Laya.stage.frameRate = Laya.Stage.FRAME_FAST;  // 60fps（默认）
Laya.stage.frameRate = Laya.Stage.FRAME_SLOW;  // 30fps（省电，低端机）

// 分辨率适配
Laya.stage.devicePixelRatio = false; // 关闭高分辨率缩放（低端机节省 VRAM）
```

---

## 7. 音频优化

```typescript
// 1. 背景音乐用流式播放（不全缓存到内存）
Laya.SoundManager.playMusic("res/sound/bgm.mp3", 0);

// 2. 音效预加载（避免首次播放延迟）
Laya.loader.load("res/sound/click.mp3", Laya.Handler.create(this, () => {
    // 此后 playSound 无延迟
}), null, Laya.Loader.SOUND);

// 3. 限制同时播放音效数量（防止音频爆栈）
Laya.SoundManager.soundChannelMax = 4; // 最多 4 个并发音效

// 4. 停止所有音效（切换场景时）
Laya.SoundManager.stopAllSound();
```

---

## 8. 性能调试

```typescript
// 显示性能统计（开发阶段）
Laya.Stat.show(0, 0);

// 关键指标说明：
// FPS    → 帧率，目标 60fps
// DrawCall → 绘制调用次数，移动端目标 < 30
// Sprite  → 当前场景中的 Sprite 数量
// Canvas  → 重绘区域数量（Canvas 模式）
```

---

## 9. 可试玩广告特殊规范

- **包体 < 5MB**：压缩所有图集，减少音频时长
- **不依赖网络**：所有资源打包，使用相对路径加载
- **避免 `console.log` 上线**：正式版本移除所有日志
- **快速首屏**：启动资源 < 200KB，1 秒内进入可交互状态
- **帧率限制**：`FRAME_SLOW`（30fps）节省移动端电量
- **禁止 `alert`/`confirm`**：使用 LayaAir UI 组件替代
