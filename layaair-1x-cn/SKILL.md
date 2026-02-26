---
name: layaair-1x-cn
description: 提供 LayaAir 1.0 游戏引擎的全面开发指导，包括 Sprite 显示对象、EventDispatcher 事件系统、Laya.loader 资源加载、Tween 缓动、Timer 定时器、文本与 UI 系统及性能优化。当用户编写或重构 LayaAir 1.0 TypeScript 代码、实现事件监听、资源加载、缓动动画或优化可试玩广告时触发。也适用于提到 Laya.init、Laya.stage、Laya.loader、Laya.Tween、laya.display.Sprite、laya.utils.Handler、laya.events.EventDispatcher 等 LayaAir 1.x API 时使用。
---

# LayaAir 1.0 开发规范

⚠️ **LayaAir 1.0（TypeScript）**：所有模式和示例均兼容 LayaAir 1.x 版本（1.0+）。

> 官方文档：https://ldc.layabox.com/doc/?nav=zh-ts-0-3-0
> API 参考：https://ldc.layabox.com/api/

---

## 技能用途

此技能为 LayaAir 1.0 项目提供全面的开发规范指导（**TypeScript 严格模式优先**）：

**优先级 1：代码质量与规范**
- TypeScript 严格类型、访问修饰符（public/private/protected）
- 异常处理（不静默错误）
- `console.log` 仅用于开发环境
- 事件注册/注销正确配对

**优先级 2：LayaAir 1.0 架构**（无组件系统，纯代码驱动）
- 显示对象树：`Laya.stage → Sprite → ...`
- 事件系统：`EventDispatcher.on/off/once/event/dispatch`
- 资源管理：`Laya.loader.load()`、多类型资源加载
- Tween 缓动：`Laya.Tween.to/from/clearAll`
- Timer 定时器：`Laya.timer.loop/once/clearAll`
- UI 组件：`Button/CheckBox/TextInput/Slider/List/ComboBox/Dialog`
- 骨骼动画：`laya.ani.bone.Skeleton`、`MovieClip`

**优先级 3：性能与可试玩广告优化**
- DrawCall 优化、图集合并、CacheAs 静态缓存
- 定时器逻辑替代 `onUpdate` 避免每帧计算
- 包体 <5MB 策略（1.0 模块化引入）

---

## ⚠️ LayaAir 1.0 核心特性
**LayaAir 1.0 没有脚本组件系统**，与 2.0 最大的区别：
- 无 `Laya.Script` 基类，无 `onAwake/onStart/onUpdate` 生命周期
- 所有逻辑写在普通 TypeScript 类中，通过 `Laya.timer.frameLoop` 驱动逻辑更新
- 引擎模块需手动引入（`laya.core.js`, `laya.ui.js`, `laya.ani.js` 等）
- 无内置物理引擎（需单独引入 `laya.physics.js`）

---

## 快速参考指南

| 任务 | 参考文档 |
|------|----------|
| 显示对象、Sprite 操作 | [显示系统](references/framework/display-system.md) |
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
// 标准初始化
Laya.init(750, 1334, Laya.WebGL);
Laya.stage.alignV = "top";
Laya.stage.alignH = "left";
Laya.stage.scaleMode = "showall";
Laya.stage.bgColor = "#000000";

// 预加载资源后启动
Laya.loader.load(["res/atlas/ui.atlas"], Laya.Handler.create(this, this.onAssetsLoaded));

private onAssetsLoaded(): void {
    const game = new GameMain();
    Laya.stage.addChild(game);
}
```

### 主循环驱动（替代组件 onUpdate）
```typescript
class GameMain extends Laya.Sprite {
    private _speed: number = 5;

    constructor() {
        super();
        // 注册帧循环函数（等同 2.0 的 onUpdate）
        Laya.timer.frameLoop(1, this, this.update);
    }

    private update(): void {
        this.x += this._speed;
    }

    // 销毁时清理定时器！
    public destroy(destroyChild: boolean = true): void {
        Laya.timer.clearAll(this);
        super.destroy(destroyChild);
    }
}
```

### 节点与显示对象
```typescript
// 创建 Sprite 并添加到舞台
const sp = new Laya.Sprite();
Laya.stage.addChild(sp);
sp.pos(100, 200);       // 设置位置
sp.size(200, 100);      // 设置尺寸
sp.pivot(100, 50);      // 设置轴心（左上角坐标）

// 加载并显示图片
sp.loadImage("res/img/bg.png");

// 精灵的变换属性
sp.x = 100;
sp.y = 200;
sp.width = 200;
sp.height = 100;
sp.alpha = 0.8;         // 透明度 0-1
sp.rotation = 45;       // 旋转角度
sp.scaleX = 1.5;        // X 缩放
sp.scaleY = 1.5;        // Y 缩放
sp.visible = false;     // 显隐

// 节点层级
parent.addChild(child);
parent.removeChild(child);
parent.addChildAt(child, 0); // 在指定层级插入
child.removeSelf();          // 从父节点移除
sp.destroy(true);            // 销毁（true=递归销毁子节点）

// 查找子节点
const node = parent.getChildByName("hero") as Laya.Sprite;
```

### 文本
```typescript
const txt = new Laya.Text();
Laya.stage.addChild(txt);
txt.text = "Hello LayaAir 1.0";
txt.color = "#ffffff";
txt.fontSize = 30;
txt.bold = true;
txt.align = "center";          // left / center / right
txt.valign = "middle";         // top / middle / bottom
txt.wordWrap = true;
txt.size(300, 0);               // 宽度限制（高度0=自动）
```

### 事件系统
```typescript
// 注册事件（on = 持续监听）
node.on(Laya.Event.CLICK, this, this.onClick);
node.once(Laya.Event.CLICK, this, this.onClick); // 仅触发一次
Laya.stage.on(Laya.Event.RESIZE, this, this.onResize);

// 注销事件
node.off(Laya.Event.CLICK, this, this.onClick);
node.offAll(Laya.Event.CLICK); // 注销指定事件的所有监听

// 触发自定义事件（传参方式）
node.event("game-over", [score]);
node.on("game-over", this, (score: number) => { });

// Laya.Event 常用常量
// CLICK, MOUSE_DOWN, MOUSE_UP, MOUSE_MOVE, MOUSE_OVER, MOUSE_OUT
// TOUCH_BEGIN, TOUCH_MOVE, TOUCH_END
// CHANGE, COMPLETE, PROGRESS, ERROR
// RESIZE, BLUR, FOCUS

// 鼠标/触摸交互开关
node.mouseEnabled = true;      // 开启交互（默认 false）
node.mouseThrough = false;     // false=点击背景有效
```

### 资源加载
```typescript
// 批量加载（常用类型）
const assets: any[] = [
    { url: "res/img/hero.png",   type: Laya.Loader.IMAGE },
    { url: "res/atlas/ui.atlas", type: Laya.Loader.ATLAS },
    { url: "res/config/data.json", type: Laya.Loader.JSON },
    { url: "res/sound/bgm.mp3",  type: Laya.Loader.SOUND },
    { url: "res/ani/role.sk",    type: Laya.Loader.BUFFER }, // 骨骼动画
];
Laya.loader.load(assets,
    Laya.Handler.create(this, this.onComplete),
    Laya.Handler.create(this, this.onProgress));

private onComplete(): void {
    const tex  = Laya.loader.getRes("res/img/hero.png") as Laya.Texture;
    const data = Laya.loader.getRes("res/config/data.json");
}

private onProgress(progress: number): void {
    // progress: 0 ~ 1
}

// Loader 类型常量
// Laya.Loader.IMAGE / ATLAS / SOUND / JSON / TEXT
// Laya.Loader.BUFFER / PREFAB / BITMAP_FONT
```

### Handler（回调封装）
```typescript
// 创建一次性 Handler（自动销毁，默认）
const h = Laya.Handler.create(this, this.onLoaded);

// 创建持久 Handler（false=不自动销毁）
const h = Laya.Handler.create(this, this.onProgress, null, false);

// 带预设参数
const h = Laya.Handler.create(this, this.onItem, [itemId], true);

// 手动回收到对象池
h.recover();
```

### Tween 缓动
```typescript
// to：从当前状态缓动到目标状态
Laya.Tween.to(sprite, { x: 500, alpha: 1 }, 800, Laya.Ease.quadOut,
    Laya.Handler.create(this, this.onTweenComplete));

// from：从初始状态缓动到当前状态
Laya.Tween.from(sprite, { x: 0, y: -100 }, 500, Laya.Ease.backOut);

// 停止缓动
Laya.Tween.clearAll(sprite);    // 清除该对象所有缓动
Laya.Tween.clear(tweenInst);    // 清除指定缓动

// 暂停 / 恢复
tweenInst.pause();
tweenInst.resume();
```

### Timer 定时器
```typescript
// 循环定时（毫秒）
Laya.timer.loop(1000, this, this.onTick);

// 延迟一次（毫秒）
Laya.timer.once(3000, this, this.onDelayed);

// 每 N 帧执行
Laya.timer.frameLoop(1, this, this.onEveryFrame);
Laya.timer.frameOnce(10, this, this.onAfter10Frames);

// 清理（必须在 destroy 前调用！）
Laya.timer.clear(this, this.onTick);   // 清除单个
Laya.timer.clearAll(this);             // 清除该 caller 的所有定时器
```

### 音频系统
```typescript
// 播放背景音乐（同时只播一首）
Laya.SoundManager.playMusic("res/sound/bgm.mp3", 0); // 0=循环

// 播放音效（支持多个同时播放）
Laya.SoundManager.playSound("res/sound/click.mp3");

// 停止
Laya.SoundManager.stopMusic();
Laya.SoundManager.stopAllSound();

// 音量控制
Laya.SoundManager.musicVolume = 0.8;  // 0~1
Laya.SoundManager.soundVolume = 0.5;

// 设备静音跟随
Laya.SoundManager.useAudioMusic = false; // false=跟随系统静音
```

### UI 系统（1.0 UI 组件）
```typescript
// Button
const btn = new Laya.Button("res/img/btn.png", "点击");
btn.on(Laya.Event.CLICK, this, this.onClick);
Laya.stage.addChild(btn);

// CheckBox
const cb = new Laya.CheckBox("res/img/check.png");
cb.selected = true;
cb.on(Laya.Event.CHANGE, this, () => { console.log(cb.selected); });

// TextInput
const input = new Laya.TextInput("请输入...");
input.size(200, 40);
input.fontSize = 20;

// Slider
const slider = new Laya.Slider(0, 100);
slider.value = 50;
slider.on(Laya.Event.CHANGE, this, () => { console.log(slider.value); });

// List
const list = new Laya.List();
list.itemRender = ItemRender;    // 渲染类
list.array = dataArray;          // 数据源
list.selectEnable = true;
```

### 1.0 vs 2.0 关键区别

| 特性 | 1.0（本技能） | 2.0 |
|------|-------------|-----|
| 脚本组件 | 无，使用普通 TypeScript 类 | 继承 `Laya.Script` |
| IDE 属性注入 | 不支持 | `@prop` 注释支持 |
| 生命周期 | 手动管理（`timer.frameLoop`）| `onAwake/onStart/onUpdate` 自动调用 |
| Scene 管理 | 手动切换场景 | IDE 场景编辑器 |
| 物理引擎 | 需手动引入 `laya.physics.js` | 内置 Box2D |
| 3D | 独立模块 `laya.d3.js` | 内置 3D 支持 |

---

## 目录结构建议
```
src/
├── Main.ts              # 入口文件
├── GameConfig.ts        # 全局配置与常量
├── manager/             # 管理器（单例模式）
│   ├── GameManager.ts
│   ├── AudioManager.ts
│   └── DataManager.ts
├── view/                # 视图类（继承 Laya.Sprite 或 UI 组件）
│   ├── GameView.ts
│   └── UIView.ts
├── model/               # 数据模型
│   └── GameModel.ts
└── common/              # 公共工具
    ├── ObjectPool.ts
    └── EventBus.ts
```
