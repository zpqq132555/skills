---
name: layaair-3x-cn
description: 提供 LayaAir 3.x 游戏引擎的全面开发指导，包括 ECS 组件系统（@regClass/@property 装饰器、Script 生命周期）、事件系统（EventDispatcher、鼠标/键盘/物理事件）、Promise 异步资源加载（Laya.loader.load）、全新 Tween 缓动系统（chain/parallel）、Timer 定时器、对象池（Laya.Pool）、2D/3D 显示对象、UI 组件系统、场景管理（Scene.open/close）、2D/3D 物理系统、屏幕适配及性能优化。当用户编写或重构 LayaAir 3.x TypeScript 代码、实现脚本组件、处理事件监听、资源加载、缓动动画、性能优化及可试玩广告项目时触发。也适用于提到 @regClass、@property、Laya.Script、Laya.loader.load（Promise）、Laya.Tween.create、Laya.Scene.open、Laya.Pool、Sprite3D、Camera 等 LayaAir 3.x API 时使用。即使用户只是提到 LayaAir、Laya 引擎或 .ls 场景文件也应触发此技能。
---

# LayaAir 3.x 开发规范

⚠️ **LayaAir 3.x（TypeScript）**：所有模式和示例均兼容 LayaAir 3.x 版本（3.0+），Tween 新 API 需 3.3+。

> 官方文档：https://www.layaair.com/3.x/doc/
> API 参考：https://layaair.com/3.x/api/
> GitHub 文档源码：https://github.com/layabox/LayaAir-Doc-ZH

---

## 技能用途

此技能为 LayaAir 3.x 项目提供全面的开发规范指导（**TypeScript 严格模式优先**）：

**优先级 1：代码质量与规范**
- TypeScript 严格类型、`@regClass()` 和 `@property()` 装饰器
- 异常处理（不静默错误）
- `console.log` 仅用于开发环境
- 正确的事件注册/注销配对（`onEnable`/`onDisable`）

**优先级 2：LayaAir 3.x 架构**
- ECS 组件系统：`@regClass` + `@property` 装饰器、`Script` 生命周期
- 事件系统：`EventDispatcher.on/off/event`、脚本内置事件方法
- 资源管理：`Laya.loader.load()` → Promise、`Laya.loader.fetch()`
- Tween 缓动（3.3+）：`Laya.Tween.create()` 链式 API、`chain()`/`parallel()`
- Timer 定时器：`Laya.timer.loop/once/frameLoop/callLater`
- 场景管理：`Laya.Scene.open/close/destroy`、`.ls` 场景文件
- 对象池：`Laya.Pool.getItemByClass/recover`
- 2D 显示对象：`Sprite`、`Text`、`Image`、动画节点
- 3D 系统：`Sprite3D`、`Camera`、`Light`、`Material`
- UI 系统：UI 组件基类、容器布局、Dialog 弹窗
- 物理系统：2D `RigidBody` + Box2D / 3D `Rigidbody3D` + Bullet/PhysX

**优先级 3：性能与可试玩广告优化**
- DrawCall 优化、`drawCallOptimize`、CacheAs 缓存
- 动态图集、对象池复用
- 屏幕适配模式（`fixedwidth`/`full`/`showall`）
- 包体 <5MB 策略

---

## 快速参考指南

| 任务 | 参考文档 |
|------|----------|
| 组件系统、生命周期、装饰器 | [组件系统](references/framework/component-system.md) |
| **装饰器完整参考**（@regClass/@property/@runInEditor/@classInfo 全部参数） | [装饰器参考](references/framework/decorators.md) |
| EventDispatcher、事件监听 | [事件模式](references/framework/event-patterns.md) |
| 资源加载、释放 | [资源管理](references/framework/resource-management.md) |
| Tween 缓动、Timer 定时器 | [缓动与动画](references/framework/tween-animation.md) |
| 场景管理、对象池 | [场景与对象池](references/framework/scene-pool.md) |
| 2D/3D 显示对象 | [显示系统](references/framework/display-system.md) |
| UI 组件系统 | [UI 系统](references/framework/ui-system.md) |
| 2D/3D 物理系统 | [物理系统](references/framework/physics.md) |
| TypeScript 代码规范 | [质量与规范](references/language/quality-hygiene.md) |
| 性能优化、屏幕适配 | [性能优化](references/language/performance.md) |
| 架构审查清单 | [架构审查](references/review/architecture-review.md) |
| 代码质量审查 | [质量审查](references/review/quality-review.md) |

---

## ⚡ 快速 API 速查

### 项目入口与引擎初始化
```typescript
// 方式一：启动脚本（Entry.ts）
export async function main() {
    Laya.Scene.open('Scene.ls');
}

// 方式二：组件脚本（推荐，挂载到场景根节点）
const { regClass, property } = Laya;

@regClass()
export class Main extends Laya.Script {
    public onStart(): void {
        console.log("Game start");
    }
}

// 引擎初始化回调
Laya.addBeforeInitCallback(() => {
    Laya.Config.useWebGL2 = true;
});
Laya.addAfterInitCallback(() => {
    console.log("引擎初始化完成");
});
```

### 组件脚本（3.x 核心特性）
```typescript
const { regClass, property } = Laya;

@regClass()
export class PlayerScript extends Laya.Script {
    @property({ type: Number, tips: "移动速度" })
    public speed: number = 5;

    @property({ type: Laya.Sprite3D })
    public target: Laya.Sprite3D;

    @property({ type: Laya.Prefab })
    public bulletPrefab: Laya.Prefab;

    public onAwake(): void {
        // 组件首次激活，只执行一次
    }

    public onEnable(): void {
        // 每次添加到舞台（含对象池取出），注册事件
    }

    public onStart(): void {
        // 第一次 onUpdate 之前，只执行一次
    }

    public onUpdate(): void {
        // 每帧调用
    }

    public onLateUpdate(): void {
        // 每帧 onUpdate 之后
    }

    public onDisable(): void {
        // 从舞台移除，注销事件
    }

    public onDestroy(): void {
        // 节点销毁
    }

    // 脚本内置鼠标事件
    public onMouseClick(evt: Laya.Event): void { }
    public onMouseDown(evt: Laya.Event): void { }
    public onMouseUp(evt: Laya.Event): void { }

    // 脚本内置键盘事件
    public onKeyDown(evt: Laya.Event): void { }
    public onKeyUp(evt: Laya.Event): void { }

    // 脚本内置物理事件
    public onTriggerEnter(other: any, self?: any, contact?: any): void { }
    public onTriggerStay(other: any, self?: any, contact?: any): void { }
    public onTriggerExit(other: any, self?: any, contact?: any): void { }
    public onCollisionEnter(other: any, self?: any, contact?: any): void { }
    public onCollisionStay(other: any, self?: any, contact?: any): void { }
    public onCollisionExit(other: any, self?: any, contact?: any): void { }
}
```

### 事件系统
```typescript
// 注册事件
node.on(Laya.Event.CLICK, this, this.onClick);
node.once(Laya.Event.CLICK, this, this.onClick);

// 注销事件
node.off(Laya.Event.CLICK, this, this.onClick);
node.offAll(Laya.Event.CLICK);
node.offAllCaller(this);  // 3.x 新增：注销 caller 所有事件

// 派发自定义事件
node.event("customEvent", data);
node.on("customEvent", this, (data) => { });

// 检查
node.hasListener(Laya.Event.CLICK);
```

### 资源加载（Promise 风格）
```typescript
// 单资源
Laya.loader.load("resources/image.png").then((res: Laya.Texture) => {
    let img = new Laya.Image();
    img.texture = res;
});

// 多资源
Laya.loader.load(["a.png", "b.json"]).then((res: any[]) => { });

// 带类型加载
Laya.loader.load(url, Laya.Loader.IMAGE).then((res) => { });

// fetch（不解析不缓存）
Laya.loader.fetch("data.json", "json").then((json) => { });

// 加载并使用缓存
Laya.loader.load("res.png").then(() => {
    let tex = Laya.loader.getRes("res.png") as Laya.Texture;
});

// 释放资源
Laya.loader.clearRes("res.png");
```

### 场景管理
```typescript
// 打开场景
Laya.Scene.open("path/Scene.ls", false, { score: 100 });

// 接收参数
public onOpened(param: any): void {
    console.log(param.score);
}

// 关闭场景
Laya.Scene.close("path/Scene.ls");
this.close();
Laya.Scene.closeAll();

// 销毁与 GC
Laya.Scene.destroy("scene.ls");
Laya.Scene.gc();
```

### Tween 缓动（3.3+ 新 API）
```typescript
// 基础缓动
Laya.Tween.create(sprite).duration(1000).to("x", 500);

// from（从指定值到当前值）
Laya.Tween.create(sprite).duration(1000).from("x", -100);

// go（指定起始和结束值）
Laya.Tween.create(sprite).duration(500).go("x", 0, 300);

// 缓动函数 + 回调
Laya.Tween.create(sprite).duration(1000)
    .to("x", 600).ease(Laya.Ease.cubicOut)
    .then(this.onComplete, this);

// 串行动画
Laya.Tween.create(sprite).duration(1000).to("x", 600)
    .chain().duration(2000).to("y", 400);

// 并行动画
Laya.Tween.create(sprite).duration(1000).to("x", 600)
    .parallel().duration(2000).to("y", 400);

// 终止
tween.kill();         // 保持当前状态
tween.kill(true);     // 跳到终态

// 震动效果
Laya.Tween.create(sprite).duration(1000)
    .to("x", 0).interp(Laya.Tween.shake, 10);

// 兼容旧 API（3.3 前）
Laya.Tween.to(sprite, { x: 500, y: 300 }, 1000, Laya.Ease.sineOut);
Laya.Tween.from(sprite, { x: 0 }, 500, Laya.Ease.backOut);
Laya.Tween.clearAll(sprite);
```

### Timer 定时器
```typescript
Laya.timer.once(1000, this, () => { });       // 延迟一次
Laya.timer.loop(1000, this, this.onTick);     // 循环执行
Laya.timer.frameOnce(60, this, () => { });    // 60 帧后
Laya.timer.frameLoop(1, this, this.onFrame);  // 每帧
Laya.timer.callLater(this, this.method);      // 当前帧延迟

Laya.timer.pause();
Laya.timer.resume();
Laya.timer.clear(this, this.onTick);
Laya.timer.clearAll(this);
```

### 对象池
```typescript
// 获取（无则创建）
let bullet = Laya.Pool.getItemByClass("bullet", Bullet);
let obj = Laya.Pool.getItemByCreateFun("enemy", () => new Enemy());

// 回收
Laya.Pool.recover("bullet", bullet);
Laya.Pool.recoverByClass(instance);

// 清理
Laya.Pool.clearBySign("bullet");
```

### 2D 显示对象
```typescript
// Sprite
let sp = new Laya.Sprite();
sp.loadImage("atlas/comp/image.png");
sp.pos(100, 200);
sp.anchorX = 0.5;
sp.anchorY = 0.5;
sp.zIndex = 10;
sp.cacheAs = "bitmap";
Laya.stage.addChild(sp);

// Text
let txt = new Laya.Text();
txt.text = "Hello LayaAir 3.x";
txt.fontSize = 50;
txt.color = "#ffffff";
txt.bold = true;
txt.overflow = "ellipsis"; // visible|hidden|scroll|shrink|ellipsis
txt.align = "center";
Laya.stage.addChild(txt);

// 模板变量
txt.text = "第{n=1}页";
txt.setVar("n", 2);

// 节点操作
parent.addChild(child);
parent.removeChild(child);
child.removeSelf();
node.destroy(true);
let c = parent.getChildByName("name");
```

### 3D 基础
```typescript
// 摄像机射线检测
let point = new Laya.Vector2(Laya.stage.mouseX, Laya.stage.mouseY);
let ray = new Laya.Ray(new Laya.Vector3(), new Laya.Vector3());
camera.viewportPointToRay(point, ray);
scene.physicsSimulation.rayCastAll(ray, outs);

// 灯光
let dirLight = new Laya.Sprite3D();
let dirCom = dirLight.addComponent(Laya.DirectionLightCom);
dirCom.color = new Laya.Color(1, 1, 1, 1);
dirCom.shadowMode = Laya.ShadowMode.SoftLow;

// 点光源
let pointLight = new Laya.Sprite3D();
let pointCom = pointLight.addComponent(Laya.PointLightCom);
pointCom.range = 3.0;
```

### 屏幕适配
```typescript
// 移动端推荐
Laya.stage.scaleMode = "fixedwidth";
Laya.stage.designWidth = 1080;
Laya.stage.designHeight = 1920;

// PC 端推荐
Laya.stage.scaleMode = "showall";

// 3D 游戏推荐
Laya.stage.scaleMode = "full";
```

### 3.x vs 2.x 关键区别

| 特性 | 3.x（本技能） | 2.x |
|------|-------------|-----|
| 装饰器 | `@regClass()` + `@property()` | `@prop` 注释注入 |
| 资源加载 | `Laya.loader.load()` → **Promise** | `Laya.loader.load()` → Handler 回调 |
| Tween（3.3+）| `Laya.Tween.create()` 链式 API | `Laya.Tween.to/from()` |
| 场景文件 | `.ls`（包含 Scene2D + Scene3D） | `.scene`（统一） |
| 场景管理 | `Laya.Scene.open()` | `Laya.Scene.open()` |
| 事件注销 | 新增 `offAllCaller(this)` | 无此 API |
| 组件分组 | `@classInfo({ menu, caption })` | 无 |
| IDE 运行 | `@runInEditor` | 不支持 |

---

## 目录结构建议
```
src/
├── Main.ts              # 入口组件脚本（@regClass）
├── config/              # 全局配置
│   └── GameConfig.ts
├── manager/             # 单例管理器
│   ├── GameManager.ts
│   ├── AudioManager.ts
│   └── DataManager.ts
├── scene/               # 场景运行时脚本
│   ├── GameScene.ts
│   └── UIScene.ts
├── script/              # 通用 Script 组件
│   ├── PlayerScript.ts
│   └── EnemyScript.ts
├── common/              # 公共工具
│   ├── ObjectPool.ts
│   └── EventBus.ts
└── ui/                  # UI 相关组件
    └── DialogScript.ts
assets/
├── Scene.ls             # 场景文件
├── resources/           # 动态加载资源
├── atlas/               # 图集配置
└── prefab/              # 预制体
```