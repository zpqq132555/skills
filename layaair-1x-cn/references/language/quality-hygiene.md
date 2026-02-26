# 代码质量规范 — LayaAir 1.0

> LayaAir 1.0 + TypeScript 项目的代码规范与常见陷阱总结。1.0 无 Script 组件，采用继承 `Laya.Sprite` 模式。

---

## 1. 类设计规范（1.0 核心模式）

```typescript
// ✅ 标准 Sprite 子类规范
class HeroView extends Laya.Sprite {
    private static readonly SPEED = 3;

    private _hp: number = 100;
    private _isAlive: boolean = true;

    constructor() {
        super();
        this._init();
    }

    private _init(): void {
        // 1. 绘制或设置纹理
        const tex = Laya.loader.getRes("res/atlas/game.atlas#hero_stand") as Laya.Texture;
        this.graphics.drawTexture(tex, -tex.width / 2, -tex.height / 2);

        // 2. 启动更新循环
        Laya.timer.frameLoop(1, this, this._update);
    }

    private _update(): void {
        // 每帧逻辑
    }

    // ✅ 必须重写 destroy，清理定时器和缓动
    public destroy(destroyChild: boolean = true): void {
        Laya.timer.clearAll(this);       // ← 关键
        Laya.Tween.clearAll(this);       // ← 关键
        super.destroy(destroyChild);
    }
}
```

---

## 2. 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 类名 | PascalCase | `HeroView`, `GameManager` |
| 私有方法/属性 | `_camelCase` | `_hp`, `_update()` |
| 公有属性 | `camelCase` | `speed`, `name` |
| 常量 | `UPPER_CASE` | `MAX_HP`, `SPEED` |
| 接口 | `I` + PascalCase | `IEnemy`, `IConfig` |
| 枚举 | PascalCase | `GameState` |
| 枚举值 | PascalCase | `GameState.Playing` |
| 事件名 | 常量对象 | `GameEvent.HERO_DEAD` |

---

## 3. 事件命名常量化

```typescript
// ❌ 魔法字符串
this.event("hero-dead");
this.on("hero-dead", this, this.onDead);

// ✅ 事件常量
export const GameEvent = {
    HERO_DEAD:   "game:hero:dead",
    HERO_HIT:    "game:hero:hit",
    SCORE_ADD:   "game:score:add",
    GAME_OVER:   "game:gameover",
} as const;

// 使用
this.event(GameEvent.HERO_DEAD);
this.on(GameEvent.HERO_HIT, this, this._onHit);

// 在 destroy 中清理事件
public destroy(destroyChild: boolean = true): void {
    this.offAll();                    // 清理所有监听
    Laya.timer.clearAll(this);
    Laya.Tween.clearAll(this);
    super.destroy(destroyChild);
}
```

---

## 4. Handler 使用规范

```typescript
// ❌ 匿名函数无法清理
node.on(Laya.Event.CLICK, this, () => this.onClick());

// ✅ 命名方法（可 off）
node.on(Laya.Event.CLICK, this, this._onClick);
// 清理
node.off(Laya.Event.CLICK, this, this._onClick);

// 一次性 Handler（执行后自动 recover）
Laya.loader.load(url,
    Laya.Handler.create(this, this._onLoaded, null, true)); // once=true

// 持久 Handler（需手动 recover）
const h = Laya.Handler.create(this, this._onProgress, null, false);
// ... 用完后
h.recover();
```

---

## 5. 定时器使用规范

```typescript
// ❌ 错误：忘记清理
class EnemyView extends Laya.Sprite {
    constructor() {
        super();
        Laya.timer.loop(1000, this, this._onTick);
    }
    // 销毁时没有清理 → 内存泄漏 + 崩溃
}

// ✅ 正确
class EnemyView extends Laya.Sprite {
    constructor() {
        super();
        Laya.timer.loop(1000, this, this._onTick);
    }

    private _onTick(): void { /* 逻辑 */ }

    public destroy(destroyChild: boolean = true): void {
        Laya.timer.clearAll(this);     // ← 必须
        Laya.Tween.clearAll(this);     // ← 必须
        super.destroy(destroyChild);
    }
}
```

---

## 6. 资源管理规范

```typescript
// 规则 1：使用前检查缓存
const tex = Laya.loader.getRes("res/img/hero.png") as Laya.Texture;
if (!tex) {
    console.error("hero.png 未加载，请检查加载流程");
    return;
}

// 规则 2：图集帧无需单独 clearRes（随图集一起释放）
Laya.loader.clearRes("res/atlas/game.atlas");

// 规则 3：骨骼动画需要 3 个资源一起释放
const skResUrls = ["res/ani/hero.sk", "res/ani/hero.png", "res/ani/hero.atlas"];
for (const url of skResUrls) {
    Laya.loader.clearRes(url);
}

// 规则 4：使用对象池减少 GC
Laya.Pool.getItemByClass("bullet", BulletView);
Laya.Pool.recover("bullet", bullet);
```

---

## 7. 每帧更新规范

```typescript
class PlayerView extends Laya.Sprite {
    private _speed: number = 5;
    private _inputX: number = 0;

    constructor() {
        super();
        Laya.timer.frameLoop(1, this, this._update);
    }

    private _update(): void {
        // ❌ 禁止
        // const child = this.getChildAt(0);   // 每帧搜索
        // new Array()                          // 每帧创建对象
        // console.log(...)                     // 每帧打印

        // ✅ 允许
        if (this._inputX !== 0) {
            this.x += this._inputX * this._speed;
        }
    }

    public destroy(destroyChild: boolean = true): void {
        Laya.timer.clearAll(this);
        super.destroy(destroyChild);
    }
}
```

---

## 8. TypeScript 规范

```typescript
// 数据结构使用接口
interface HeroConfig {
    id: number;
    name: string;
    maxHp: number;
    speed: number;
}

// 状态使用枚举
enum HeroState {
    Idle = 0,
    Moving = 1,
    Attacking = 2,
    Dead = 3,
}

// null/undefined 保护
const node = this.getChildByName("icon");
if (!node) {
    console.warn("icon 节点未找到");
    return;
}
```

---

## 9. 常见陷阱速查

| 陷阱 | 后果 | 解决 |
|------|------|------|
| `destroy()` 未清 `timer.clearAll` | 定时器访问已销毁对象崩溃 | 必须重写 `destroy()` 并清理 |
| `destroy()` 未清 `Tween.clearAll` | 缓动访问已销毁对象属性异常 | `destroy()` 中清理 |
| `on()` 使用匿名函数 | 无法 `off`，内存泄漏 | 始终使用命名方法 |
| 帧循环中创建对象 | GC 峰值，卡顿 | 预先创建或使用对象池 |
| 未检查 `getRes()` 返回值 | null 访问崩溃 | 每次获取资源后检查 null |
| 事件用魔法字符串 | 拼写错误无提示 | 常量对象 `GameEvent.*` |
