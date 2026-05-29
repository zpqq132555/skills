# 缓动与动画 — LayaAir 3.x

> 📖 LayaAir 3.3+ 全面重构了 Tween 系统，使用链式 API、支持 chain/parallel 组合。

---

## 1. Tween 缓动（3.3+ 新 API）

### 基础用法
```typescript
// to：缓动到目标值
Laya.Tween.create(sprite).duration(1000).to("x", 500);

// 多属性
Laya.Tween.create(sprite).duration(1000).to("x", 500).to("y", 300).to("alpha", 0);

// from：从指定值缓动到当前值
Laya.Tween.create(sprite).duration(1000).from("x", -100);

// go：指定起始和结束值
Laya.Tween.create(sprite).duration(500).go("x", 0, 300);
```

### 缓动函数
```typescript
Laya.Tween.create(sprite).duration(1000)
    .to("x", 600)
    .ease(Laya.Ease.cubicOut);

// 常用缓动函数：
// Laya.Ease.linearNone     - 线性
// Laya.Ease.sineIn/Out/InOut - 正弦
// Laya.Ease.cubicIn/Out/InOut - 三次方
// Laya.Ease.quartIn/Out/InOut - 四次方
// Laya.Ease.quintIn/Out/InOut - 五次方
// Laya.Ease.circIn/Out/InOut - 圆形
// Laya.Ease.bounceIn/Out/InOut - 弹跳
// Laya.Ease.backIn/Out/InOut - 回弹
// Laya.Ease.elasticIn/Out/InOut - 弹性
// Laya.Ease.expoIn/Out/InOut - 指数
```

### 回调
```typescript
let tween = Laya.Tween.create(sprite).duration(1000)
    .to("x", 500)
    .onStart((tweener) => { console.log("开始"); })
    .onUpdate((tweener) => { console.log("更新中"); })
    .then(this.onComplete, this);  // 完成回调
```

### 串行动画（chain）
```typescript
// 先移动 X，完成后再移动 Y
Laya.Tween.create(sprite)
    .duration(1000).to("x", 600)
    .chain()
    .duration(2000).to("y", 400);
```

### 并行动画（parallel）
```typescript
// X 和 Y 同时缓动，但时长不同
Laya.Tween.create(sprite)
    .duration(1000).to("x", 600)
    .parallel()
    .duration(2000).to("y", 400);
```

### 循环与延迟
```typescript
// 延迟 500ms 后开始
Laya.Tween.create(sprite).delay(500).duration(1000).to("x", 500);

// 循环
Laya.Tween.create(sprite).duration(1000).to("x", 500)
    .repeat(3);  // 重复 3 次

// 无限循环 + 反转
Laya.Tween.create(sprite).duration(1000).to("x", 500)
    .yoyo(true).repeat(-1);
```

### 终止缓动
```typescript
let tween = Laya.Tween.create(sprite).duration(1000).to("x", 500);

tween.kill();         // 立即停止，保持当前状态
tween.kill(true);     // 立即停止，跳到最终状态
```

### 特殊效果
```typescript
// 震动效果
Laya.Tween.create(sprite).duration(1000)
    .to("x", 0).interp(Laya.Tween.shake, 10);  // 幅度 10

// 支持 Vector2/3/4、Color、字符串颜色等类型
Laya.Tween.create(material).duration(1000)
    .to("albedoColor", new Laya.Color(1, 0, 0, 1));
```

---

## 2. 兼容旧 API（3.3 前版本或过渡期）

```typescript
// Tween.to — 从当前值到目标值
Laya.Tween.to(sprite, { x: 500, y: 300, alpha: 1 }, 1000,
    Laya.Ease.sineOut,
    Laya.Handler.create(this, this.onComplete));

// Tween.from — 从指定值到当前值
Laya.Tween.from(sprite, { x: 0, y: 0 }, 500,
    Laya.Ease.backOut);

// 停止
Laya.Tween.clearAll(sprite);       // 清除目标所有缓动
Laya.Tween.clear(tweenInstance);   // 清除指定实例
```

---

## 3. Timer 定时器

### 核心 API
```typescript
// 延迟执行一次（毫秒）
Laya.timer.once(1000, this, () => {
    console.log("1 秒后执行");
});

// 循环执行（毫秒）
Laya.timer.loop(1000, this, this.onTick);

// 帧延迟一次
Laya.timer.frameOnce(60, this, () => {
    console.log("60 帧后执行");
});

// 每帧执行
Laya.timer.frameLoop(1, this, this.onFrameLoop);

// 当前帧延迟执行（渲染前触发，避免重复计算）
Laya.timer.callLater(this, this.refresh);
```

### 暂停与恢复
```typescript
Laya.timer.pause();   // 暂停所有定时器
Laya.timer.resume();  // 恢复所有定时器
```

### 清理
```typescript
// 清除指定定时器
Laya.timer.clear(this, this.onTick);

// 清除当前对象的所有定时器
Laya.timer.clearAll(this);

// 立即执行并删除
Laya.timer.runCallLater(this, this.refresh);
Laya.timer.runTimer(this, this.onTick);
```

### 定时器最佳实践
```typescript
@regClass()
export class GameScript extends Laya.Script {
    onEnable(): void {
        // 启动时注册定时器
        Laya.timer.loop(1000, this, this.onSecondTick);
    }

    onDisable(): void {
        // 移除时清理定时器
        Laya.timer.clear(this, this.onSecondTick);
    }

    onDestroy(): void {
        // 销毁时兜底清理
        Laya.timer.clearAll(this);
    }

    private onSecondTick(): void {
        // 每秒执行
    }
}
```

---

## 4. 帧率控制

```typescript
// 固定帧率
Laya.stage.frameRate = Laya.Stage.FRAME_FAST;   // 60 FPS
Laya.stage.frameRate = Laya.Stage.FRAME_SLOW;   // 30 FPS

// 鼠标交互优化（推荐省电场景）
Laya.stage.frameRate = Laya.Stage.FRAME_MOUSE;
// 有鼠标活动 → 60 FPS，静止 2 秒 → 降为 30 FPS
```

---

## 5. 新旧 Tween 对比

| 特性 | 3.3+ 新 API | 旧 API |
|------|------------|--------|
| 创建方式 | `Laya.Tween.create(target)` | `Laya.Tween.to(target, props)` |
| 链式调用 | ✅ `.duration().to().ease()` | ❌ 参数式 |
| 串行动画 | `chain()` | 需手动在回调中串联 |
| 并行动画 | `parallel()` | 需同时创建多个 Tween |
| 回调 | `.then()`, `.onStart()`, `.onUpdate()` | `Handler.create()` |
| 终止 | `tween.kill()` / `tween.kill(true)` | `Tween.clear()` / `Tween.clearAll()` |
| 类型支持 | Number, Vector, Color, 字符串颜色 | 仅 Number |
| 震动 | `.interp(Laya.Tween.shake, amp)` | 无内置 |
