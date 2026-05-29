# 缓动与动画 — LayaAir 1.0

> 📖 LayaAir 1.0 提供 `Laya.Tween`（缓动）、`Laya.timer`（定时器）和 `Laya.Animation`/`Laya.Skeleton`（帧动画/骨骼动画）。

---

## 1. Tween 缓动系统

### 基础用法

```typescript
// to：从当前状态缓动到目标状态
Laya.Tween.to(
    target,      // 缓动目标（任意对象）
    props,       // 目标属性 { x: 500, alpha: 1 }
    duration,    // 时长（毫秒）
    ease?,       // 缓动函数（可选）
    complete?,   // 完成回调 Handler（可选）
    delay?       // 延迟（毫秒，可选）
);

// from：从指定状态缓动到当前状态
Laya.Tween.from(sprite, { x: 0, y: -150 }, 500, Laya.Ease.backOut);
```

### 常用动画场景

```typescript
// UI 弹出
sprite.scaleX = 0;
sprite.scaleY = 0;
Laya.Tween.to(sprite, { scaleX: 1, scaleY: 1 }, 400, Laya.Ease.backOut);

// 淡入
sprite.alpha = 0;
Laya.Tween.to(sprite, { alpha: 1 }, 300, Laya.Ease.sineOut);

// 飞行动画（带延迟完成回调）
Laya.Tween.to(coin, { x: 100, y: 50 }, 600, Laya.Ease.sineIn,
    Laya.Handler.create(this, () => {
        coin.removeSelf();
        // 更新 UI
    }));

// 序列动画（链式）
Laya.Tween.to(sprite, { x: 300 }, 400, Laya.Ease.sineOut,
    Laya.Handler.create(this, () => {
        Laya.Tween.to(sprite, { y: 500 }, 500, Laya.Ease.bounceOut);
    }));
```

### 控制缓动

```typescript
// 获取缓动实例
const t = Laya.Tween.to(sprite, { x: 500 }, 1000);

// 暂停/恢复
t.pause();
t.resume();

// 停止（清除）
Laya.Tween.clear(t);              // 停止单个缓动实例
Laya.Tween.clearAll(sprite);      // 停止该对象所有缓动
```

---

## 2. Ease 缓动函数

| 函数 | 效果描述 |
|------|---------|
| `Laya.Ease.linearNone` | 匀速线性 |
| `Laya.Ease.sineIn/Out/InOut` | 正弦平滑 |
| `Laya.Ease.quadIn/Out/InOut` | 二次方加速 |
| `Laya.Ease.cubicIn/Out/InOut` | 三次方更强加速 |
| `Laya.Ease.elasticIn/Out/InOut` | 弹性伸缩 |
| `Laya.Ease.backIn/Out/InOut` | 超调后回弹 |
| `Laya.Ease.bounceIn/Out/InOut` | 弹球反弹 |

```typescript
// 常见场景选择
Laya.Ease.backOut      // → UI 弹出动画（推荐）
Laya.Ease.sineOut      // → 平滑减速到目标
Laya.Ease.elasticOut   // → 弹性到达目标
Laya.Ease.bounceOut    // → 像球落地弹跳
Laya.Ease.cubicIn      // → 加速离开（退场动画）
```

---

## 3. Timer 定时器

```typescript
// 每隔 duration 毫秒循环执行
Laya.timer.loop(1000, this, this.onSecondTick);

// 延迟 delay 毫秒后执行一次
Laya.timer.once(3000, this, this.onDelayedAction);

// 每帧执行（60fps 则每秒调用60次）
Laya.timer.frameLoop(1, this, this.onUpdate);

// 每 N 帧后执行一次
Laya.timer.frameOnce(30, this, this.onAfter30Frames);

// 停止单个定时器
Laya.timer.clear(this, this.onSecondTick);

// 停止该 caller 的所有定时器（销毁时必须调用！）
Laya.timer.clearAll(this);
```

### 定时器 vs 帧循环

| 场景 | 推荐方法 |
|------|---------|
| 高频游戏逻辑（移动、碰撞） | `frameLoop(1, ...)` |
| 低频逻辑（血量回复、计时） | `loop(1000, ...)` |
| 延迟执行一次 | `once(delay, ...)` |
| UI 动画 | 优先使用 `Tween`，不用 timer |

### 与 Sprite 结合的完整模板

```typescript
class EnemyView extends Laya.Sprite {
    private _speed: number = 3;
    private _hp: number = 100;
    private _regenTimer: number = 2000; // 每 2 秒回血

    constructor() {
        super();
        // 帧循环驱动主逻辑
        Laya.timer.frameLoop(1, this, this.onUpdate);
        // 低频定时器
        Laya.timer.loop(this._regenTimer, this, this.onHpRegen);
    }

    private onUpdate(): void {
        this.x -= this._speed;
        if (this.x < -100) {
            this.destroy();
        }
    }

    private onHpRegen(): void {
        this._hp = Math.min(this._hp + 5, 100);
    }

    // 必须重写 destroy 清理定时器！
    public destroy(destroyChild: boolean = true): void {
        Laya.timer.clearAll(this);          // ← 关键
        Laya.Tween.clearAll(this);          // ← 关键
        super.destroy(destroyChild);
    }
}
```

---

## 4. Laya.Animation（帧动画）

```typescript
// 方式 A：从图集帧加载
const frames: Laya.Texture[] = [];
for (let i = 0; i < 6; i++) {
    const tex = Laya.loader.getRes(`res/atlas/game.atlas#explode_${i}`) as Laya.Texture;
    frames.push(tex);
}

const anim = new Laya.Animation();
anim.loadImages(frames, 80);    // 每帧 80ms
anim.play(0, false);             // 从第0帧开始，不循环

// 完成后销毁
anim.on(Laya.Event.COMPLETE, this, () => {
    anim.removeSelf();
    anim.destroy(true);
});

Laya.stage.addChild(anim);

// 方式 B：从 .ani 文件
const anim2 = new Laya.Animation();
anim2.loadAnimation("res/ani/effect.ani");
anim2.play(0, true, "fire");     // animationName 指定播放哪组
```

---

## 5. 骨骼动画（Skeleton）

```typescript
// 骨骼文件加载（需要 3 个资源）
const skFiles = [
    "res/ani/hero.sk",
    "res/ani/hero.png",
    "res/ani/hero.atlas"
];

Laya.loader.load(skFiles, Laya.Handler.create(this, () => {
    const sk = new Laya.Skeleton();
    Laya.stage.addChild(sk);
    sk.pos(300, 600);
    sk.load("res/ani/hero.sk");   // 加载 .sk 文件

    // 播放动画
    sk.play("idle", true);        // true=循环

    // 播放完成回调（仅非循环动画触发）
    sk.on(Laya.Event.COMPLETE, this, () => {
        sk.play("idle", true);
    });

    // 暂停/恢复
    sk.paused = true;
    sk.paused = false;
}));
```

---

## 6. 缓动与定时器清理模板

```typescript
class EffectView extends Laya.Sprite {
    private _sk: Laya.Skeleton = null;
    private _isActive: boolean = false;

    constructor() {
        super();
        Laya.timer.frameLoop(1, this, this.update);
    }

    private update(): void {
        if (!this._isActive) return;
        // 每帧逻辑
    }

    public playEffect(): void {
        this._isActive = true;
        // 缓动入场
        this.alpha = 0;
        Laya.Tween.to(this, { alpha: 1 }, 300, Laya.Ease.sineOut);
    }

    // 关键：必须重写 destroy
    public destroy(destroyChild: boolean = true): void {
        // 1. 清除所有缓动
        Laya.Tween.clearAll(this);

        // 2. 清除所有定时器
        Laya.timer.clearAll(this);

        // 3. 停止骨骼动画
        if (this._sk) {
            this._sk.stop();
            this._sk = null;
        }

        // 4. 调用父类销毁
        super.destroy(destroyChild);
    }
}
```
