# 场景与对象池 — LayaAir 3.x

> 📖 LayaAir 3.x 场景管理使用 `.ls` 文件格式（统一包含 Scene2D + Scene3D），对象池通过 `Laya.Pool` 管理。

---

## 1. 场景管理

### 场景文件格式
- **3.x**：`.ls`（场景文件，包含 2D 和 3D 内容）、`.lh`（预制体文件）
- **2.x**：`.scene`（已废弃）

### 打开场景
```typescript
// 打开场景
Laya.Scene.open("path/Scene.ls");

// 带参数打开
Laya.Scene.open("path/GameScene.ls", false, { level: 5, score: 1000 });

// 第二个参数 closeOther：是否关闭其他场景
Laya.Scene.open("path/GameScene.ls", true);  // 关闭其他场景后打开
```

### 接收场景参数
```typescript
const { regClass } = Laya;

@regClass()
export class GameScene extends Laya.Script {
    // 在场景运行时脚本中接收参数
    onOpened(param: any): void {
        if (param) {
            console.log(`关卡: ${param.level}, 分数: ${param.score}`);
        }
    }
}
```

### 关闭场景
```typescript
// 按路径关闭
Laya.Scene.close("path/Scene.ls");

// 关闭当前场景（在场景的 Runtime 脚本中）
this.close();

// 关闭所有场景
Laya.Scene.closeAll();
```

### 销毁与 GC
```typescript
// 销毁场景并释放关联资源
Laya.Scene.destroy("scene.ls");

// GC 未使用的资源
Laya.Scene.gc();
```

### Loading 页面
```typescript
// 设置 Loading 页面
const loadingSprite = new Laya.Sprite();
// ... 构建 loading UI
Laya.Scene.setLoadingPage(loadingSprite);

// 显示/隐藏
Laya.Scene.showLoadingPage();
Laya.Scene.hideLoadingPage();
```

---

## 2. 对象池（Laya.Pool）

### 基础 API
```typescript
// 按类名获取（推荐）—— 无则自动实例化
let bullet = Laya.Pool.getItemByClass("bullet", Bullet);

// 按工厂函数获取 —— 无则通过工厂创建
let enemy = Laya.Pool.getItemByCreateFun("enemy", () => {
    let sp = new Laya.Sprite();
    sp.loadImage("res/enemy.png");
    return sp;
});

// 直接从池中获取（无则返回 null）
let item = Laya.Pool.getItem("bullet");

// 获取对象池数组
let pool = Laya.Pool.getPoolBySign("bullet");
console.log("池中数量:", pool.length);
```

### 回收
```typescript
// 按标识回收
Laya.Pool.recover("bullet", bullet);

// 按类回收
Laya.Pool.recoverByClass(instance);
```

### 清理
```typescript
// 清理指定池
Laya.Pool.clearBySign("bullet");
```

---

## 3. 对象池 + 组件生命周期最佳实践

```typescript
const { regClass, property } = Laya;

@regClass()
export class BulletScript extends Laya.Script {
    @property({ type: Number })
    public speed: number = 10;

    private static readonly POOL_KEY = "bullet";

    onEnable(): void {
        // ✅ 每次从对象池取出时都会触发
        // 在此重置状态
        this.speed = 10;
    }

    onUpdate(): void {
        (this.owner as Laya.Sprite).y -= this.speed;

        // 超出屏幕回收
        if ((this.owner as Laya.Sprite).y < -50) {
            this.recycle();
        }
    }

    onDisable(): void {
        // 从舞台移除时触发（回收到池之前）
    }

    /** 实现 onReset 则自动支持对象池回收 */
    onReset(): void {
        this.speed = 10;
        (this.owner as Laya.Sprite).pos(0, 0);
        (this.owner as Laya.Sprite).alpha = 1;
    }

    public recycle(): void {
        this.owner.removeSelf();
        Laya.Pool.recover(BulletScript.POOL_KEY, this.owner);
    }

    // 管理器调用
    public static spawn(parent: Laya.Sprite, x: number, y: number): Laya.Sprite {
        let bullet = Laya.Pool.getItemByClass(
            BulletScript.POOL_KEY, Laya.Sprite
        ) as Laya.Sprite;
        bullet.pos(x, y);
        parent.addChild(bullet);
        return bullet;
    }
}
```

### 关键生命周期与对象池的关系

| 生命周期 | 首次创建 | 从池取出 | 回收入池 | 销毁 |
|---------|--------|---------|---------|------|
| `onAwake` | ✅ | ❌ | - | - |
| `onEnable` | ✅ | ✅ | - | - |
| `onStart` | ✅ | ❌ | - | - |
| `onDisable` | - | - | ✅ | ✅ |
| `onReset` | - | - | ✅ | - |
| `onDestroy` | - | - | - | ✅ |

- **`onEnable`**：对象池取出后一定会执行 → 适合做状态重置
- **`onAwake`**：只执行一次 → 适合做一次性初始化
- **`onReset`**：回收时触发 → 实现此方法可自动支持对象池

---

## 4. 场景切换模式

### 叠加场景（多场景共存）
```typescript
// UI 场景叠加在游戏场景上
Laya.Scene.open("scene/Game.ls");           // 游戏场景
Laya.Scene.open("scene/GameUI.ls", false);  // UI 叠加（closeOther=false）
```

### 替换场景
```typescript
// 关闭当前再打开新场景
Laya.Scene.open("scene/Result.ls", true);   // closeOther=true
```

### 场景间通信
```typescript
// 通过全局事件总线
const EventBus = new Laya.EventDispatcher();

// 场景 A 发送
EventBus.event("gameOver", { score: 1000 });

// 场景 B 接收
EventBus.on("gameOver", this, (data) => {
    console.log(data.score);
});
```
