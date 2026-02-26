# 性能优化 — LayaAir 2.0

> LayaAir 2.0 性能优化核心：减少 DrawCall、使用对象池、启用 CacheAs、优化 onUpdate 逻辑。

---

## 1. CacheAs 缓存渲染

```typescript
// 静态 UI 容器（不动、子节点不变）
const panel = this.owner.getChildByName("panel") as Laya.Sprite;
panel.cacheAs = "bitmap";       // 将容器烘焙为位图，减少 DrawCall

// 动态更新 UI 后需刷新缓存
panel.cacheAs = "none";
// 修改子节点...
panel.cacheAs = "bitmap";

// 注意事项：
// - 子节点有动画时不要用 bitmap（每帧重建反而更慢）
// - 仅静态/低频更新内容适合 bitmap
// - "normal" 模式：合并子节点的渲染但不生成位图纹理
```

### CacheAs 模式选择

| 场景 | 推荐模式 |
|------|---------|
| 完全静态的背景/面板 | `"bitmap"` |
| 包含少量动态子节点 | `"normal"` |
| 频繁变化的容器 | `"none"`（关闭缓存） |

---

## 2. 对象池（Object Pool）

```typescript
// Laya.Pool 内置对象池
class Bullet extends Laya.Sprite {
    public reset(): void {
        this.alpha = 1;
        this.visible = true;
        this.removeSelf();
    }
}

// 获取（从池中复用或新建）
const bullet = Laya.Pool.getItemByClass("bullet", Bullet) as Bullet;
Laya.stage.addChild(bullet);
bullet.pos(shooter.x, shooter.y);

// 回收（归还到池中）
function recycleBullet(b: Bullet): void {
    b.removeSelf();
    Laya.Pool.recover("bullet", b);
}

// 在 Script 中的对象池模式
class BulletManagerScript extends Laya.Script {
    private static readonly POOL_KEY = "bullet";

    public fireBullet(x: number, y: number): void {
        const b = Laya.Pool.getItemByClass(BulletManagerScript.POOL_KEY, Bullet);
        this.owner.addChild(b);
        b.init(x, y);
    }

    public recycleBullet(b: Bullet): void {
        b.removeSelf();
        Laya.Pool.recover(BulletManagerScript.POOL_KEY, b);
    }
}
```

---

## 3. 减少 DrawCall

```typescript
// 1. 合并到图集（单一图集 DrawCall = 1）
//    - 相同图集内的 Sprite 渲染只产生 1 次 DrawCall
//    - 避免混用多个图集与纯色 Sprite

// 2. 合理使用 mouseEnabled / mouseThrough
sprite.mouseEnabled = false;     // 不响应鼠标/触摸的节点关掉，减少事件检测
parent.mouseThrough = true;      // 穿透父节点，直接检测子节点

// 3. visible vs alpha
node.visible = false;    // ✅ visible=false 不参与渲染（推荐隐藏）
node.alpha = 0;          // ⚠️ alpha=0 仍参与渲染管线

// 4. 只渲染视口内节点
//    通过 x/y 和 stage 尺寸判断，超出范围设 visible=false
```

---

## 4. onUpdate 性能优化

```typescript
class EnemyScript extends Laya.Script {
    private _speed: number = 200;
    private _target: Laya.Sprite | null = null;

    // 状态标志减少无效计算
    private _isAlive: boolean = true;

    // ❌ 性能差
    public onUpdate(): void {
        const children = Laya.stage.numChildren;  // 每帧读取
        const pos = new Laya.Point(this.owner.x, this.owner.y);  // 每帧创建
        this._target = this.owner.getChildByName("target") as Laya.Sprite; // 每帧搜索
    }

    // ✅ 正确优化
    public onStart(): void {
        // 缓存引用
        this._target = Laya.stage.getChildByName("hero") as Laya.Sprite;
    }

    // 临时变量复用
    private _dx: number = 0;
    private _dy: number = 0;

    public onUpdate(): void {
        if (!this._isAlive || !this._target) return;  // 早退出

        this._dx = this._target.x - (this.owner as Laya.Sprite).x;
        this._dy = this._target.y - (this.owner as Laya.Sprite).y;
        const len = Math.sqrt(this._dx * this._dx + this._dy * this._dy);
        if (len < 10) return;

        const dt = Laya.timer.delta / 1000;
        (this.owner as Laya.Sprite).x += (this._dx / len) * this._speed * dt;
        (this.owner as Laya.Sprite).y += (this._dy / len) * this._speed * dt;
    }
}
```

---

## 5. 帧率感知的时间步

```typescript
// ❌ 固定步长（帧率不同时速度不一致）
onUpdate(): void {
    this.owner.x += 5; // 30fps 和 60fps 速度差一倍
}

// ✅ 基于增量时间
onUpdate(): void {
    const dt = Laya.timer.delta / 1000;  // 上一帧耗时（秒）
    (this.owner as Laya.Sprite).x += this._speed * dt;
}
```

---

## 6. 内存优化

```typescript
// 1. 场景切换时释放不用的资源
Laya.Scene.open("res/scene/level2.scene");
// 在 level1 close 时清理资源

// 2. 避免大图，优先使用图集
// 单张大图（如背景）会占用大量 VRAM；多个小图拼图集

// 3. 音频格式选择
// Android/iOS 均支持：.mp3
// 背景音乐：.mp3（流式播放，Laya.SoundManager.playMusic 自动流式）
// 音效：预加载后播放，避免每次 load

// 4. 定时器/缓动清理（防止 Script 组件泄漏）
onDestroy(): void {
    Laya.timer.clearAll(this);
    Laya.Tween.clearAll(this.owner);
}
```

---

## 7. 图形渲染优化

```typescript
// 1. 减少 Graphics 重绘
// ❌ 每帧 clear + redraw（高开销）
onUpdate(): void {
    this.owner.graphics.clear();
    this.owner.graphics.drawRect(...);
}
// ✅ 使用 Sprite + Texture 代替 Graphics 绘制

// 2. 大背景使用 Image 而非 Sprite
const bg = new Laya.Image("res/img/bg.jpg");
bg.width = Laya.stage.width;
bg.height = Laya.stage.height;

// 3. 粒子系统：使用 Laya.ParticleSystem 而非手动创建大量 Sprite
```

---

## 8. 性能检测指引

| 指标 | 工具 | 目标 |
|------|------|------|
| DrawCall | LayaAir IDE 内置分析器 | < 30（移动端） |
| FPS | `Laya.Stat.show()` | 稳定 60fps |
| 内存（Texture） | Chrome Memory 面板 | 无增长趋势 |
| GC 频率 | Chrome Performance | 无频繁 GC |

```typescript
// 开发阶段显示性能统计（发布时关闭）
Laya.Stat.show(0, 0);
```

---

## 9. 可试玩广告特殊规范

- **包体 < 5MB**：图集压缩（.atlas 使用 TinyPNG 压缩输出图），删减无用资源
- **延迟加载**：先展示 Loading 界面，1-2 秒内开始展示内容
- **不使用 HTTP 请求**：所有资源打包进包体，`Laya.loader.load` 加载相对路径
- **帧率自适应**：`Laya.stage.frameRate = Laya.Stage.FRAME_FAST` 或 `FRAME_SLOW`（后者 30fps，省电）
