# 性能优化 — LayaAir 3.x

> LayaAir 3.x 性能优化核心：减少 DrawCall、对象池复用、CacheAs 缓存、屏幕适配。

---

## 1. CacheAs 缓存渲染

```typescript
// 静态容器（不动、子节点不变）→ 减少 DrawCall
panel.cacheAs = "bitmap";

// CacheAs 模式选择
// "bitmap"  → 完全静态，烘焙为位图纹理（最优）
// "normal"  → 合并子节点渲染，但不生成纹理
// "none"    → 关闭缓存（默认）

// 子节点有动画 → 不要用 bitmap（每帧重建反而更慢）
// 低频更新内容 → 适合 bitmap
```

### ✅ CacheAs 最佳实践
```typescript
@regClass()
export class UIScript extends Laya.Script {
    @property({ type: Laya.Sprite })
    public staticBg: Laya.Sprite;

    onStart(): void {
        // 静态背景开启缓存
        this.staticBg.cacheAs = "bitmap";
    }

    // 需要更新时先关闭再重开
    refreshPanel(): void {
        this.staticBg.cacheAs = "none";
        // 修改子节点...
        this.staticBg.cacheAs = "bitmap";
    }
}
```

---

## 2. DrawCall 优化

### drawCallOptimize（3.3+ 动态合批）
```typescript
// 3.3+ 新增：动态合批，自动优化 DrawCall
sp.drawCallOptimize = true;
// 测试数据：65 DC → 5 DC
```

### 图集合并
- 同一图集内的 Sprite 渲染只产生 1 次 DrawCall
- 避免混用多个图集与纯色 Sprite
- 使用 IDE 的自动图集配置

### 节点可见性
```typescript
// ✅ visible=false 不参与渲染管线（推荐隐藏）
node.visible = false;

// ⚠️ alpha=0 仍参与渲染管线
node.alpha = 0; // 不推荐用于隐藏

// ✅ 视口裁剪：超出屏幕设置 visible=false
if (sp.x + sp.width < 0 || sp.x > Laya.stage.width) {
    sp.visible = false;
}
```

### 鼠标检测优化
```typescript
// 不需要交互的节点关闭鼠标检测
sp.mouseEnabled = false;

// 穿透父节点直接检测子节点
parent.mouseThrough = true;
```

---

## 3. 对象池复用

```typescript
// ✅ 使用 Laya.Pool 复用高频创建/销毁的对象
const bullet = Laya.Pool.getItemByClass("bullet", Bullet);
parent.addChild(bullet);

// 回收而非销毁
function recycleBullet(b: Laya.Sprite): void {
    b.removeSelf();
    Laya.Pool.recover("bullet", b);
}

// ❌ 频繁 new + destroy
function fire(): void {
    let b = new Bullet();     // ❌ 每次 new
    parent.addChild(b);
}
function remove(b: Bullet): void {
    b.destroy(true);          // ❌ 每次 destroy
}
```

---

## 4. onUpdate 性能优化

```typescript
@regClass()
export class OptimizedScript extends Laya.Script {
    // ✅ 预缓存引用
    private _sp: Laya.Sprite;
    private _transform: Laya.Transform3D;

    onAwake(): void {
        this._sp = this.owner as Laya.Sprite;
        this._transform = (this.owner as Laya.Sprite3D).transform;
    }

    onUpdate(): void {
        // ✅ 使用缓存引用
        this._sp.x += 1;

        // ❌ 每帧查找
        // (this.owner as Laya.Sprite).getChildByName("hero").x += 1;

        // ❌ 每帧创建对象
        // let pos = new Laya.Vector3(0, 0, 0); // 每帧 GC 压力
    }
}
```

### 减少 GC 压力
```typescript
@regClass()
export class NoGCScript extends Laya.Script {
    // ✅ 预分配复用对象
    private _tempVec3: Laya.Vector3 = new Laya.Vector3();
    private _tempVec2: Laya.Vector2 = new Laya.Vector2();

    onUpdate(): void {
        // 复用临时向量而非每帧 new
        this._tempVec3.x = 0;
        this._tempVec3.y = 1;
        this._tempVec3.z = 0;
        // 使用 this._tempVec3 ...
    }
}
```

---

## 5. 内存管理

```typescript
// 1. 及时销毁不用的节点
node.destroy(true);

// 2. 释放资源
Laya.loader.clearRes("res/img.png");

// 3. 场景级 GC
Laya.Scene.gc();

// 4. 定时器/事件清理
onDestroy(): void {
    Laya.timer.clearAll(this);
    Laya.stage.offAllCaller(this);
}
```

---

## 6. 屏幕适配

### 适配模式
| 模式 | 适用场景 |
|------|---------|
| `noscale` | 默认，不缩放 |
| `full` | 画布取物理分辨率，3D 游戏推荐 |
| `fixedwidth` | **移动端推荐**，保宽、高度自适应 |
| `fixedheight` | 保高、宽度自适应 |
| `fixedauto` | 自动选择保宽/保高 |
| `showall` | **PC 推荐**，设计尺寸全显示 |

```typescript
// 移动端推荐配置
Laya.stage.scaleMode = "fixedwidth";
Laya.stage.designWidth = 1080;
Laya.stage.designHeight = 1920;

// PC/Web 推荐
Laya.stage.scaleMode = "showall";
Laya.stage.designWidth = 1920;
Laya.stage.designHeight = 1080;

// 3D 游戏（需要精确分辨率）
Laya.stage.scaleMode = "full";
```

### 关键属性
```typescript
Laya.Browser.pixelRatio;                 // 设备像素比 DPR
Laya.Browser.clientWidth;                // 逻辑宽度
Laya.Browser.clientHeight;               // 逻辑高度
Laya.Browser.width;                      // 物理宽度
Laya.Browser.height;                     // 物理高度
Laya.stage.designWidth;                  // 设计宽度
Laya.stage.designHeight;                 // 设计高度
```

---

## 7. 帧率策略

```typescript
// 固定高帧率
Laya.stage.frameRate = Laya.Stage.FRAME_FAST;  // 60 FPS

// 固定低帧率（省电）
Laya.stage.frameRate = Laya.Stage.FRAME_SLOW;  // 30 FPS

// 智能帧率（推荐省电场景）
Laya.stage.frameRate = Laya.Stage.FRAME_MOUSE;
// 有交互 → 60 FPS，静止 2s → 30 FPS
```

---

## 8. 动态图集

```typescript
// 开启动态图集（自动将小图合并到大图集）
Laya.stage.dynamicAtlas = true;

// 适用于：大量动态加载的小图
// 不适用于：大图、纹理频繁变化
```

---

## 9. 可试玩广告优化要点

| 优化项 | 措施 |
|--------|------|
| 包体 <5MB | 压缩纹理、删除未用资源、代码剥离 |
| 首屏加载 <3s | 首屏精简资源、延迟加载 |
| DrawCall <30 | 图集合并、CacheAs、drawCallOptimize |
| 内存 <150MB | 对象池、及时释放、避免大纹理 |
| 帧率 ≥30 FPS | onUpdate 零分配、视口裁剪 |
