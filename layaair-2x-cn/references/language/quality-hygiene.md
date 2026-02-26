# 代码质量规范 — LayaAir 2.0

> LayaAir 2.0 + TypeScript 项目的代码规范与常见陷阱总结。

---

## 1. Script 组件规范

### 生命周期使用规范

```typescript
// ✅ 正确
class HeroScript extends Laya.Script {
    // 属性声明（readonly 推荐大写常量，普通用 camelCase + 下划线前缀）
    private static readonly SPEED = 300;
    private _hp: number = 100;
    private _onDead: Laya.Handler;

    // @prop 注释用于 LayaAir IDE 中显示属性面板
    /** @prop {name: speed, tips: "移动速度", type: number, default: 300} */
    public speed: number = 300;

    onAwake(): void {
        // 仅做初始化，不依赖其他节点
    }

    onStart(): void {
        // 获取其他组件/节点，注册回调
    }

    onUpdate(): void {
        // 只放高频逻辑，避免对象创建
    }

    onDisable(): void {
        Laya.timer.clearAll(this);
    }

    onDestroy(): void {
        Laya.timer.clearAll(this);
        Laya.Tween.clearAll(this.owner);
        if (this._onDead) {
            this._onDead.recover();
            this._onDead = null;
        }
    }
}
```

---

## 2. 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 类名 | PascalCase | `HeroScript`, `GameManager` |
| 私有属性 | `_camelCase` | `_hp`, `_speed` |
| 公有属性 | `camelCase` | `speed`, `name` |
| 常量 | `UPPER_CASE` | `MAX_HP`, `BULLET_SPEED` |
| 接口 | `I` + PascalCase | `IEnemy`, `IConfig` |
| 枚举 | PascalCase | `GameState`, `BulletType` |
| 枚举值 | PascalCase | `GameState.Playing` |
| 事件名 | `kebab-case` 或 常量 | `"hero-dead"` → `HeroEvent.DEAD` |

---

## 3. 事件命名常量化

```typescript
// ❌ 魔法字符串
sprite.event("hero-dead", this);
sprite.on("hero-dead", this, handler);

// ✅ 常量
export const HeroEvent = {
    DEAD: "hero:dead",
    HIT:  "hero:hit",
    WIN:  "hero:win",
} as const;

// 使用
this.owner.event(HeroEvent.DEAD);
this.owner.on(HeroEvent.HIT, this, this.onHit);
```

---

## 4. Handler 使用规范

```typescript
// ❌ 匿名函数（无法 off 清理）
node.on(Laya.Event.CLICK, this, () => {
    this.onClick();
});

// ✅ 命名方法
node.on(Laya.Event.CLICK, this, this.onClick);
// 清理
node.off(Laya.Event.CLICK, this, this.onClick);

// Handler.create：一次性回调优先使用 once=true
const h = Laya.Handler.create(this, this.onLoaded, null, true); // true=执行后自动recover
Laya.loader.load(url, h);

// 持久 Handler（once=false）：需手动 recover
const h2 = Laya.Handler.create(this, this.onProgress, null, false);
// 不需要时
h2.recover();
```

---

## 5. 节点获取规范

```typescript
// ✅ 推荐：onStart 中缓存引用
class HeroScript extends Laya.Script {
    private _hpBar: Laya.Sprite | null = null;

    onStart(): void {
        this._hpBar = this.owner.getChildByName("HpBar") as Laya.Sprite;
        if (!this._hpBar) {
            console.error("HeroScript: HpBar 节点未找到！");
        }
    }

    // ❌ 不要在 onUpdate 中每帧查找节点
    onUpdate(): void {
        // ❌ this.owner.getChildByName("HpBar")  每帧搜索
        // ✅ this._hpBar  使用已缓存的引用
    }
}
```

---

## 6. 资源与内存管理规范

```typescript
// 规则 1：配对加载/释放
// 只在确认不再需要时才 clearRes

// 规则 2：图集帧 Texture 无需单独释放（随图集一起释放）
Laya.loader.clearRes("res/atlas/game.atlas"); // 会释放整个图集

// 规则 3：动态创建的 Texture 需手动 destroy
const tex = new Laya.Texture(/*...*/);
// 用完后
tex.destroy();

// 规则 4：节点销毁时传 true 递归销毁子节点
node.destroy(true);

// 规则 5：使用对象池复用频繁创建/销毁的对象
Laya.Pool.getItemByClass("bullet", Bullet);
Laya.Pool.recover("bullet", bullet);
```

---

## 7. onUpdate 中禁止的操作

```typescript
// ❌ onUpdate 中禁止
onUpdate(): void {
    const arr = new Array();          // 创建对象 → GC 压力
    const child = this.owner.getChildAt(0); // 轻量但频繁调用累积成本
    Laya.loader.load("res/img/x.png", ...); // 重复加载
    console.log("update");           // 日志刷屏
}

// ✅ onUpdate 中应做
onUpdate(): void {
    this._x += this._speed * Laya.timer.delta / 1000; // 使用增量时间
    this._owner.x = this._x;                           // 直接操作属性
}
```

---

## 8. TypeScript 严格规范

```typescript
// 1. 避免 any（除非对接第三方）
// 2. 接口定义数据结构
interface HeroConfig {
    id: number;
    name: string;
    maxHp: number;
    speed: number;
}

// 3. null 检查
const node = this.owner.getChildByName("icon") as Laya.Sprite | null;
if (!node) {
    console.warn("icon not found");
    return;
}

// 4. 枚举优于字面量
enum GameState {
    Idle = 0,
    Playing = 1,
    Paused = 2,
    GameOver = 3,
}
```

---

## 9. 常见陷阱速查

| 陷阱 | 后果 | 解决 |
|------|------|------|
| `onDestroy` 忘记 `timer.clearAll` | 定时器访问已销毁对象崩溃 | 总是在 `onDestroy` 调用 |
| `onDestroy` 忘记 `Tween.clearAll` | 缓动访问已销毁节点属性 | 总是在 `onDestroy`/`onDisable` 调用 |
| `on()` 使用匿名函数 | 无法 `off()` 清理，内存泄漏 | 始终使用命名方法 |
| `onUpdate` 中查找节点 | 性能浪费 | `onStart` 缓存引用 |
| 使用魔法字符串事件名 | 易拼错，难维护 | 常量化事件名 |
| `Handler.create` 后未 `recover` | 轻微内存泄漏 | 用 `once=true` 或手动 `recover()` |
