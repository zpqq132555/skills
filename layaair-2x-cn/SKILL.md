---
name: layaair-2x-cn
description: 提供 LayaAir 2.0 游戏引擎的全面开发指导，包括脚本组件系统（Script/Component 生命周期）、EventDispatcher 事件系统、Laya.loader 资源加载、Tween 缓动、Timer 定时器、显示对象（Sprite/Text/Image）、UI 系统以及可试玩广告优化。当用户编写或重构 LayaAir 2.0 TypeScript 代码、实现脚本组件、处理事件监听、资源加载、缓动动画、性能优化及可试玩广告项目时触发。也适用于提到 Laya.init、Laya.stage、Laya.loader、Laya.Tween、laya.display.Sprite、laya.utils.Handler、laya.events.EventDispatcher 等 LayaAir 2.x API 时使用。
---

# LayaAir 2.0 开发规范

⚠️ **LayaAir 2.0（TypeScript）**：所有模式和示例均兼容 LayaAir 2.x 版本（2.0+）。

> 官方文档：https://ldc2.layabox.com/doc/?nav=zh-ts-0-3-0
> API 参考：https://ldc2.layabox.com/api/

---

## 技能用途

此技能为 LayaAir 2.0 项目提供全面的开发规范指导（**TypeScript 严格模式优先**）：

**优先级 1：代码质量与规范**
- TypeScript 严格类型、访问修饰符（public/private/protected）
- 异常处理（不静默错误）
- `console.log` 仅用于开发环境
- 正确的事件注册/注销配对

**优先级 2：LayaAir 2.0 架构**
- 脚本/组件系统：`onAwake → onEnable → onStart → onUpdate → onLateUpdate → onDisable → onDestroy`
- 事件系统：`EventDispatcher.on/off/dispatch`、`Laya.stage` 全局事件
- 资源管理：`Laya.loader.load()`、`Laya.loader.getRes()`、资源释放
- Tween 缓动：`Laya.Tween.to/from/clearAll`
- Timer 定时器：`Laya.timer.loop/once/clearAll`
- UI 系统：IDE 生成的 UI 类、Scene 加载

**优先级 3：性能与可试玩广告优化**
- DrawCall 优化、图集合并、CacheAs 静态缓存
- `onUpdate` 零内存分配
- 包体 <5MB 策略

---

## 快速参考指南

| 任务 | 参考文档 |
|------|----------|
| 脚本组件、生命周期 | [显示与组件系统](references/framework/display-system.md) |
| EventDispatcher、事件监听 | [事件模式](references/framework/event-patterns.md) |
| 资源加载、释放 | [资源管理](references/framework/resource-management.md) |
| Tween 缓动、Timer 定时器 | [缓动与动画](references/framework/tween-animation.md) |
| TypeScript 代码规范 | [质量与规范](references/language/quality-hygiene.md) |
| DrawCall 优化、性能 | [性能优化](references/language/performance.md) |
| 架构审查清单 | [架构审查](references/review/architecture-review.md) |
| 代码质量审查 | [质量审查](references/review/quality-review.md) |

---

## ⚡ 快速 API 速查

### 引擎初始化
```typescript
// 标准初始化（WebGL 模式，可回退 Canvas）
Laya.init(750, 1334, Laya.WebGL);
Laya.stage.alignV = "top";
Laya.stage.alignH = "left";
Laya.stage.scaleMode = "showall";
Laya.stage.bgColor = "#000000";
```

### 脚本组件（2.0 核心特性）
```typescript
class PlayerScript extends Laya.Script {
    /** @prop {name: speed, tips:"移动速度", type: Number, default: 5} */
    public speed: number = 5;

    private _owner: Laya.Sprite;

    onAwake(): void {
        // 组件激活，owner 已就绪（等同 Awake）
        this._owner = this.owner as Laya.Sprite;
    }

    onStart(): void {
        // 第一帧 Update 执行前（等同 Start）
    }

    onEnable(): void {
        // 组件启用时（注册事件在此）
        Laya.stage.on(Laya.Event.CLICK, this, this.onClick);
    }

    onUpdate(): void {
        // 每帧调用（等同 Update）
        this.owner.x += this.speed;
    }

    onLateUpdate(): void {
        // 每帧 onUpdate 之后（等同 LateUpdate）
    }

    onDisable(): void {
        // 组件禁用时（注销事件在此）
        Laya.stage.off(Laya.Event.CLICK, this, this.onClick);
    }

    onDestroy(): void {
        // 组件销毁时（清理资源）
    }

    private onClick(e: Laya.Event): void {
        // 处理点击
    }
}
```

### 节点与显示对象
```typescript
// 创建 Sprite
const sp = new Laya.Sprite();
Laya.stage.addChild(sp);
sp.pos(100, 200);
sp.size(200, 100);

// 加载并显示图片
sp.loadImage("res/img/bg.png");

// 文本
const txt = new Laya.Text();
txt.text = "Hello LayaAir 2.0";
txt.color = "#ffffff";
txt.fontSize = 30;
Laya.stage.addChild(txt);

// 节点层级
parent.addChild(child);
parent.removeChild(child);
child.removeSelf();
sp.destroy(true); // true=递归销毁子节点
```

### 事件系统
```typescript
// 注册事件
node.on(Laya.Event.CLICK, this, this.onClick);
node.once(Laya.Event.CLICK, this, this.onClick); // 只触发一次
Laya.stage.on(Laya.Event.RESIZE, this, this.onResize);

// 注销事件
node.off(Laya.Event.CLICK, this, this.onClick);
node.offAll(Laya.Event.CLICK); // 注销该事件所有监听

// 派发自定义事件
node.event("custom-event", [data1, data2]);
node.on("custom-event", this, (d1, d2) => { });

// Laya.Event 常用常量
// CLICK, MOUSE_DOWN, MOUSE_UP, MOUSE_MOVE, MOUSE_OVER, MOUSE_OUT
// TOUCH_BEGIN, TOUCH_MOVE, TOUCH_END
// CHANGE, COMPLETE, PROGRESS, ERROR
// RESIZE, BLUR, FOCUS
```

### 资源加载
```typescript
// 批量加载
const assets = [
    { url: "res/img/hero.png", type: Laya.Loader.IMAGE },
    { url: "res/atlas/ui.atlas", type: Laya.Loader.ATLAS },
    { url: "res/config/data.json", type: Laya.Loader.JSON },
];
Laya.loader.load(assets, Laya.Handler.create(this, this.onLoaded),
    Laya.Handler.create(this, this.onProgress));

private onLoaded(): void {
    // 获取缓存资源
    const tex = Laya.loader.getRes("res/img/hero.png") as Laya.Texture;
}

private onProgress(progress: number): void {
    console.log(`加载进度: ${Math.floor(progress * 100)}%`);
}

// 单个加载
Laya.loader.load("res/scene/game.json", Laya.Handler.create(this, (res) => {
    Laya.stage.addChild(Laya.loader.getRes("res/scene/game.json") as Laya.Sprite);
}));

// 释放资源
Laya.loader.clearRes("res/img/hero.png");
Laya.loader.clearTextureRes("res/img/hero.png");
```

### Handler（回调封装）
```typescript
// 创建一次性 Handler（执行后自动销毁）
const handler = Laya.Handler.create(caller, callback, args, true);

// 创建持久 Handler（不自动销毁）
const handler = Laya.Handler.create(caller, callback, args, false);

// 手动回收
handler.recover();
```

### Tween 缓动
```typescript
// 基础缓动
Laya.Tween.to(sprite, { x: 500, y: 300, alpha: 1 }, 1000, Laya.Ease.sineOut,
    Laya.Handler.create(this, this.onComplete));

// 从某状态缓动至当前
Laya.Tween.from(sprite, { x: 0, y: 0 }, 500, Laya.Ease.backOut);

// 停止缓动
Laya.Tween.clearAll(sprite);       // 清除该目标所有缓动
Laya.Tween.clear(tweenInstance);   // 清除指定缓动实例
```

### Timer 定时器
```typescript
// 循环执行（毫秒）
Laya.timer.loop(1000, this, this.onTick);

// 延迟一次
Laya.timer.once(2000, this, this.onDelayed);

// 每帧执行
Laya.timer.frameLoop(1, this, this.onFrameTick);

// 清理
Laya.timer.clear(this, this.onTick);    // 清除特定定时器
Laya.timer.clearAll(this);              // 清除当前对象所有定时器
```

### UI 系统（IDE 生成）
```typescript
// 加载并显示 UI 场景
class GameUI extends ui.GameUIUI {
    constructor() {
        super();
        // IDE 生成的属性已绑定，直接使用
        this.btnStart.on(Laya.Event.CLICK, this, this.onBtnStart);
        this.lblScore.text = "0";
    }

    private onBtnStart(): void {
        // 处理按钮事件
    }
}
```

### 2.0 vs 1.0 关键区别

| 特性 | 2.0（本技能） | 1.0 |
|------|-------------|-----|
| 脚本组件 | 继承 `Laya.Script`，完整生命周期 | 无组件系统，使用普通 TypeScript 类 |
| IDE 属性注入 | `@prop {name,type}` 注释注入 | 不支持 |
| Scene 管理 | IDE 场景编辑器 + `Laya.Scene.open()` | 无场景管理 |
| 物理引擎 | 内置 Box2D | 无内置（需手动集成） |
| 3D | 内置 3D 支持 | 3D 独立模块 |
| 骨骼动画 | `Laya.Skeleton` | `laya.ani.bone.Skeleton` |

---

## 目录结构建议
```
src/
├── Main.ts              # 入口文件
├── gameConfig.ts        # 全局配置
├── manager/             # 单例管理器
│   ├── GameManager.ts
│   ├── AudioManager.ts
│   └── DataManager.ts
├── scene/               # 场景（对应 IDE 场景文件）
│   ├── GameScene.ts
│   └── UIScene.ts
├── script/              # Script 组件脚本
│   ├── PlayerScript.ts
│   └── EnemyScript.ts
├── common/              # 公共工具
│   ├── ObjectPool.ts
│   └── EventBus.ts
└── ui/                  # IDE 生成的 UI 基类（勿手动修改）
    └── GameUIUI.ts
```
