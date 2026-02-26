# 缓动与动画 — LayaAir 2.0

> 📖 LayaAir 2.0 提供 `Laya.Tween`（缓动）、`Laya.timer`（定时器）和 `Laya.Animation`（帧动画）三大动画系统。

---

## 1. Tween 缓动系统

### 基础用法

```typescript
// to：从当前状态缓动到目标状态
const tweenInst = Laya.Tween.to(
    target,          // 缓动对象（Sprite 或任意对象属性）
    props,           // 目标属性值 { x: 500, y: 300, alpha: 1 }
    duration,        // 持续时间（毫秒）
    ease?,           // 缓动函数（可选）
    complete?,       // 完成回调（Handler，可选）
    delay?,          // 延迟（毫秒，可选）
    coverBefore?     // 是否覆盖之前的缓动（可选，默认 false）
);

// from：从目标状态缓动到当前状态
Laya.Tween.from(sprite, { x: 0, y: -100 }, 600, Laya.Ease.backOut);
```

### 常用示例

```typescript
class UIAnimScript extends Laya.Script {
    onEnable(): void {
        // 从初始状态淡入
        this.owner.alpha = 0;
        Laya.Tween.to(this.owner, { alpha: 1 }, 300);

        // 弹出动画（先缩小再弹出）
        this.owner.scaleX = 0;
        this.owner.scaleY = 0;
        Laya.Tween.to(this.owner, { scaleX: 1, scaleY: 1 }, 400, Laya.Ease.backOut);
    }

    // 关闭动画
    public closeWithAnim(onClosed: () => void): void {
        Laya.Tween.to(this.owner, { scaleX: 0, scaleY: 0, alpha: 0 }, 250,
            Laya.Ease.backIn, Laya.Handler.create(this, onClosed));
    }

    onDisable(): void {
        // 停止对象上所有缓动（必须！）
        Laya.Tween.clearAll(this.owner);
    }
}
```

### 链式缓动（Sequential）

```typescript
// 手动链式：第一段缓动完成后执行第二段
Laya.Tween.to(sprite, { x: 300 }, 500, Laya.Ease.sineOut,
    Laya.Handler.create(this, () => {
        Laya.Tween.to(sprite, { y: 500 }, 400, Laya.Ease.bounceOut,
            Laya.Handler.create(this, () => {
                console.log("全部完成");
            }));
    }));
```

### 控制缓动实例

```typescript
const t = Laya.Tween.to(sprite, { x: 500 }, 1000);

t.pause();      // 暂停
t.resume();     // 恢复

// 停止（清除）
Laya.Tween.clear(t);            // 停止单个
Laya.Tween.clearAll(sprite);    // 停止该对象所有缓动
```

---

## 2. Ease 缓动函数

| 分类 | 函数 | 效果 |
|------|------|------|
| 线性 | `Laya.Ease.linearNone` | 匀速 |
| 正弦 | `Laya.Ease.sineIn/Out/InOut` | 平滑 |
| 二次 | `Laya.Ease.quadIn/Out/InOut` | 加速/减速 |
| 三次 | `Laya.Ease.cubicIn/Out/InOut` | 更强加速 |
| 弹性 | `Laya.Ease.elasticIn/Out/InOut` | 弹性效果 |
| 回弹 | `Laya.Ease.backIn/Out/InOut` | 超调后回弹 |
| 反弹 | `Laya.Ease.bounceIn/Out/InOut` | 像球弹跳 |

```typescript
// 常用组合
Laya.Tween.to(dial,  { rotation: 90 },  500, Laya.Ease.backOut);     // UI 弹出
Laya.Tween.to(coin,  { y: -200 },       400, Laya.Ease.sineOut);      // 金币飞起
Laya.Tween.to(enemy, { alpha: 0 },      200, Laya.Ease.linearNone);   // 淡出消失
Laya.Tween.to(digit, { y: targetY },    600, Laya.Ease.bounceOut);    // 数字下落弹跳
```

---

## 3. Timer 定时器

### 基础用法

```typescript
// 循环执行（毫秒）
Laya.timer.loop(1000, this, this.onSecondTick);

// 延迟一次执行
Laya.timer.once(3000, this, this.onDelayed);

// 每帧执行（等同旧 Laya.timer.frameLoop(1, ...)）
Laya.timer.frameLoop(1, this, this.onEveryFrame);

// 延迟 N 帧执行
Laya.timer.frameOnce(5, this, this.onAfter5Frames);

// 清除单个定时器
Laya.timer.clear(this, this.onSecondTick);

// 清除对象所有定时器（在 onDestroy 中必须调用）
Laya.timer.clearAll(this);
```

### 在 Script 中的使用模式

```typescript
class CountdownScript extends Laya.Script {
    private _timeLeft: number = 60;

    onEnable(): void {
        this._timeLeft = 60;
        Laya.timer.loop(1000, this, this.onTick);
    }

    private onTick(): void {
        this._timeLeft--;
        if (this._timeLeft <= 0) {
            Laya.timer.clear(this, this.onTick);
            this.owner.event("countdown-done");
        }
    }

    onDisable(): void {
        Laya.timer.clear(this, this.onTick);
    }

    onDestroy(): void {
        Laya.timer.clearAll(this);
    }
}
```

### Timer 常见问题

```typescript
// ❌ 忘记在 onDestroy 清除
onDestroy(): void {
    // 忘了 clearAll → 定时器继续调用已销毁对象
}

// ✅ 总是在 onDestroy 中清除
onDestroy(): void {
    Laya.timer.clearAll(this);    // ← 必须
    Laya.Tween.clearAll(this.owner); // ← 必须
}
```

---

## 4. Laya.Animation（帧动画）

```typescript
// 方式 A：从图集帧加载
const frames: Laya.Texture[] = [];
for (let i = 0; i < 8; i++) {
    frames.push(Laya.loader.getRes(`res/atlas/game.atlas#run_${String(i).padStart(2, "0")}`) as Laya.Texture);
}
const anim = new Laya.Animation();
anim.loadImages(frames, 50); // 第二参数：每帧间隔(ms)
anim.play(0, true);
Laya.stage.addChild(anim);

// 方式 B：从 .ani 文件加载
const anim2 = new Laya.Animation();
anim2.loadAnimation("res/ani/explode.ani");
anim2.play(0, false, "explode"); // (startFrame, loop, animationName)

// 事件监听
anim2.on(Laya.Event.COMPLETE, this, () => {
    anim2.stop();
    anim2.removeSelf();
});

// 停止
anim2.stop();
```

---

## 5. 骨骼动画（Skeleton）

```typescript
// 加载资源（3 个文件）
const skRes = [
    { url: "res/ani/hero.sk",    type: Laya.Loader.BUFFER },
    { url: "res/ani/hero.png",   type: Laya.Loader.IMAGE  },
    { url: "res/ani/hero.atlas", type: Laya.Loader.TEXT   },
];

Laya.loader.load(skRes, Laya.Handler.create(this, () => {
    const sk = new Laya.Skeleton();
    Laya.stage.addChild(sk);
    sk.pos(300, 500);
    sk.load("res/ani/hero.sk");

    // 播放动画
    sk.play("idle", true);     // 循环播放

    // 切换动画
    sk.play("run", true);

    // 完成事件（非循环动画）
    sk.on(Laya.Event.COMPLETE, this, () => {
        sk.play("idle", true);
    });
}));
```

---

## 6. 完整动画清理模板

```typescript
class AnimatedScript extends Laya.Script {
    private _sk: Laya.Skeleton | null = null;
    private _anim: Laya.Animation | null = null;

    onStart(): void {
        // 初始化动画...
    }

    onDisable(): void {
        // 暂停缓动
        Laya.Tween.clearAll(this.owner);
        Laya.timer.clearAll(this);
    }

    onDestroy(): void {
        // 清理所有动画资源
        Laya.Tween.clearAll(this.owner);
        Laya.timer.clearAll(this);

        if (this._sk) {
            this._sk.stop();
            this._sk.destroy(true);
            this._sk = null;
        }

        if (this._anim) {
            this._anim.stop();
            this._anim.destroy(true);
            this._anim = null;
        }
    }
}
```
