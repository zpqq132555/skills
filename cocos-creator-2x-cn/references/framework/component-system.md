# Cocos Creator 2.4 组件系统

> 官方文档：https://docs.cocos.com/creator/2.4/manual/zh/scripting/

## 目录

- [声明组件：cc.Class vs cc._decorator](#声明组件)
- [@property / properties 属性声明](#属性声明)
- [生命周期回调](#生命周期回调)
- [访问节点和组件](#访问节点和组件)
- [创建和销毁节点](#创建和销毁节点)
- [cc.tween 缓动系统](#缓动系统)
- [cc.Action 动作系统（旧版）](#动作系统)
- [计时器 schedule](#计时器)
- [常见错误](#常见错误)

---

## 声明组件

### TypeScript 方式（推荐）

使用 `cc._decorator` 装饰器声明组件，这是 2.4 TypeScript 项目的推荐方式：

```typescript
const { ccclass, property } = cc._decorator;

// ✅ 优秀：TypeScript 装饰器声明
@ccclass
export default class PlayerController extends cc.Component {
    @property(cc.Node)
    targetNode: cc.Node = null;

    @property
    moveSpeed: number = 100;

    @property(cc.Label)
    scoreLabel: cc.Label = null;

    onLoad(): void {
        // 初始化逻辑
    }
}
```

### JavaScript 方式

使用 `cc.Class({})` 声明组件，适用于 JavaScript 项目：

```javascript
// ✅ 优秀：cc.Class 声明
cc.Class({
    extends: cc.Component,

    properties: {
        targetNode: {
            default: null,
            type: cc.Node,
        },
        moveSpeed: 100,
        scoreLabel: {
            default: null,
            type: cc.Label,
        },
    },

    onLoad() {
        // 初始化逻辑
    },
});
```

### 声明方式对比

| 特性 | TypeScript (cc._decorator) | JavaScript (cc.Class) |
|------|---------------------------|----------------------|
| 装饰器 | `@ccclass` / `@property` | `cc.Class({})` |
| 属性 | `@property(Type)` | `properties: {}` |
| 导出 | `export default class` | 文件名即类名 |
| 继承 | `extends cc.Component` | `extends: cc.Component` |
| 类型检查 | 编译时类型安全 | 运行时检查 |

---

## 属性声明

### TypeScript @property 装饰器

```typescript
const { ccclass, property } = cc._decorator;

@ccclass
export default class PropertyExamples extends cc.Component {
    // ✅ 基本类型
    @property
    integerValue: number = 0;

    @property
    floatValue: number = 0.0;

    @property
    stringValue: string = "";

    @property
    boolValue: boolean = false;

    // ✅ 节点引用
    @property(cc.Node)
    playerNode: cc.Node = null;

    // ✅ 组件引用
    @property(cc.Sprite)
    spriteComp: cc.Sprite = null;

    @property(cc.Label)
    labelComp: cc.Label = null;

    @property(cc.Animation)
    animComp: cc.Animation = null;

    // ✅ 资源引用
    @property(cc.SpriteFrame)
    iconFrame: cc.SpriteFrame = null;

    @property(cc.Prefab)
    bulletPrefab: cc.Prefab = null;

    @property(cc.AudioClip)
    bgmClip: cc.AudioClip = null;

    @property(cc.SpriteAtlas)
    uiAtlas: cc.SpriteAtlas = null;

    // ✅ 数组
    @property([cc.Node])
    enemyNodes: cc.Node[] = [];

    @property([cc.SpriteFrame])
    frames: cc.SpriteFrame[] = [];

    // ✅ 枚举
    @property({ type: cc.Enum(Direction) })
    direction: Direction = Direction.UP;

    // ✅ 显示名称和提示
    @property({ displayName: "移动速度", tooltip: "角色移动速度" })
    moveSpeed: number = 100;

    // ✅ 范围限制
    @property({ type: cc.Float, range: [0, 1, 0.01] })
    volume: number = 1.0;

    // ✅ 只读（在属性检查器中不可编辑）
    @property({ readonly: true })
    version: string = "1.0.0";
}
```

### JavaScript properties 属性

```javascript
cc.Class({
    extends: cc.Component,

    properties: {
        // ✅ 简写形式：直接赋默认值
        moveSpeed: 100,
        playerName: "Player",
        isActive: true,

        // ✅ 完整形式：指定类型
        targetNode: {
            default: null,
            type: cc.Node,
        },

        // ✅ 组件引用
        spriteComp: {
            default: null,
            type: cc.Sprite,
        },

        // ✅ 资源引用
        bulletPrefab: {
            default: null,
            type: cc.Prefab,
        },

        // ✅ 数组
        enemyNodes: {
            default: [],
            type: [cc.Node],
        },

        // ✅ 带属性参数
        volume: {
            default: 1.0,
            range: [0, 1, 0.01],
            slide: true,
            tooltip: "音量大小",
        },

        // ✅ 不序列化的属性
        _tempData: {
            default: null,
            serializable: false,
        },
    },
});
```

---

## 生命周期回调

完整调用顺序：`onLoad` → `onEnable` → `start` → `update` → `lateUpdate` → `onDisable` → `onDestroy`

```typescript
const { ccclass, property } = cc._decorator;

@ccclass
export default class LifecycleDemo extends cc.Component {
    /**
     * 1. onLoad - 组件初始化（节点首次激活时触发）
     * - 初始化内部数据
     * - 获取子节点引用
     * - 注册事件监听（如果不需要 onEnable/onDisable 配对）
     * - 总是在 start 之前执行
     * - 只调用一次
     */
    onLoad(): void {
        // 验证必要引用
        if (!this.targetNode) {
            throw new Error("LifecycleDemo: targetNode 未赋值");
        }

        // 初始化内部数据
        this._bulletRect = this.bulletSprite.getRect();

        // 查找子节点
        this.gun = cc.find("hand/weapon", this.node);
    }

    /**
     * 2. onEnable - 组件/节点启用时
     * - 注册事件（与 onDisable 配对）
     * - 可多次调用
     */
    onEnable(): void {
        this.node.on(cc.Node.EventType.TOUCH_START, this.onTouchStart, this);
        cc.systemEvent.on(cc.SystemEvent.EventType.KEY_DOWN, this.onKeyDown, this);
    }

    /**
     * 3. start - 第一次 update 之前（所有组件 onLoad 后）
     * - 安全引用其他组件
     * - 初始化需要经常修改的数据
     * - 只调用一次
     */
    start(): void {
        const otherComp = this.node.getComponent("OtherScript");
        this._timer = 0;
    }

    /**
     * 4. update - 每帧调用
     * - 游戏逻辑更新
     * - 注意：避免在此处分配内存
     */
    update(dt: number): void {
        this._timer += dt;
        this.node.x += this.moveSpeed * dt;
    }

    /**
     * 5. lateUpdate - 所有 update 之后
     * - 用于需要在动画/物理更新后执行的逻辑
     * - 如相机跟随
     */
    lateUpdate(dt: number): void {
        // 相机跟随逻辑
    }

    /**
     * 6. onDisable - 组件/节点禁用时
     * - 注销事件（与 onEnable 配对）
     * - 可多次调用
     */
    onDisable(): void {
        this.node.off(cc.Node.EventType.TOUCH_START, this.onTouchStart, this);
        cc.systemEvent.off(cc.SystemEvent.EventType.KEY_DOWN, this.onKeyDown, this);
    }

    /**
     * 7. onDestroy - 组件销毁
     * - 清理所有资源引用
     * - 停止缓动动画
     * - 释放动态加载的资源
     */
    onDestroy(): void {
        cc.Tween.stopAllByTarget(this.node);
        // 释放动态加载的资源
        if (this._dynamicTexture) {
            this._dynamicTexture.decRef();
            this._dynamicTexture = null;
        }
    }
}
```

### onLoad vs start 区别

| | onLoad | start |
|---|--------|-------|
| 调用时机 | 节点首次激活时立即 | 第一次 update 之前（延迟） |
| 能否访问其他组件 | 不保证其他组件已 onLoad | 是（所有组件已 onLoad） |
| 用途 | 自身初始化、查找子节点 | 引用其他组件、交叉初始化 |
| 调用次数 | 一次 | 一次 |

---

## 访问节点和组件

### 获取节点引用

```typescript
// 通过 @property 在检查器中拖拽设置（推荐）
@property(cc.Node)
targetNode: cc.Node = null;

// 获取当前节点
const myNode = this.node;

// 获取子节点
const child = this.node.getChildByName("ChildName");
const allChildren = this.node.children;

// 通过路径查找（相对于当前节点）
const deepChild = cc.find("path/to/child", this.node);

// 全局查找（从场景根节点）
const canvas = cc.find("Canvas");
const uiNode = cc.find("Canvas/UI/ScoreLabel");
```

### 获取组件引用

```typescript
// 获取同节点上的组件
const sprite = this.getComponent(cc.Sprite);
const label = this.node.getComponent(cc.Label);

// 获取自定义脚本组件（通过类名字符串）
const ctrl = this.getComponent("PlayerController");

// 获取自定义脚本组件（TypeScript 通过类引用）
import PlayerController from "./PlayerController";
const ctrl = this.getComponent(PlayerController);

// 获取子节点上的组件
const childSprite = this.node.getChildByName("Icon").getComponent(cc.Sprite);

// 获取所有指定类型组件
const allSprites = this.getComponentsInChildren(cc.Sprite);

// ⚠️ 安全检查
const label = this.getComponent(cc.Label);
if (label) {
    label.string = "Hello";
} else {
    cc.error("Label 组件未找到");
}
```

### 通过模块化交叉引用（JavaScript）

```javascript
// Global.js
module.exports = {
    backNode: null,
    backLabel: null,
};

// Back.js
var Global = require("Global");
cc.Class({
    extends: cc.Component,
    onLoad() {
        Global.backNode = this.node;
        Global.backLabel = this.getComponent(cc.Label);
    },
});

// AnyScript.js
var Global = require("Global");
cc.Class({
    extends: cc.Component,
    start() {
        Global.backLabel.string = "Back";
    },
});
```

---

## 创建和销毁节点

```typescript
// 动态创建节点
const newNode = new cc.Node("NewSprite");
const sprite = newNode.addComponent(cc.Sprite);
newNode.parent = this.node;

// 从预制体实例化
cc.resources.load("prefabs/enemy", cc.Prefab, (err, prefab) => {
    if (err) { cc.error(err); return; }
    const enemy = cc.instantiate(prefab);
    enemy.parent = this.node;
    enemy.setPosition(cc.v2(100, 200));
});

// 克隆节点
const clone = cc.instantiate(this.targetNode);
clone.parent = this.node;

// 销毁节点（在当帧结束时回收）
this.targetNode.destroy();

// 移除所有子节点
this.node.removeAllChildren();

// 激活/停用节点
this.node.active = false; // 停用（不渲染、不更新）
this.node.active = true;  // 激活
```

---

## 缓动系统

> cc.tween 是 2.4 推荐的动画方式，替代旧版 cc.Action 系统

```typescript
// 基本缓动
cc.tween(this.node)
    .to(1, { position: cc.v3(100, 200, 0) })   // 移动
    .to(0.5, { scale: 2 })                     // 缩放
    .to(0.3, { opacity: 128 })                 // 透明度
    .to(0.3, { angle: 90 })                    // 旋转
    .start();

// 缓动函数
cc.tween(this.node)
    .to(1, { position: cc.v3(200, 0, 0) }, { easing: "sineOut" })
    .start();

// 常用缓动函数：
// linear, sineIn, sineOut, sineInOut
// quadIn, quadOut, quadInOut
// cubicIn, cubicOut, cubicInOut
// backIn, backOut, backInOut
// bounceIn, bounceOut, bounceInOut
// elasticIn, elasticOut, elasticInOut

// 序列动画
cc.tween(this.node)
    .to(0.5, { position: cc.v3(100, 0, 0) })
    .to(0.5, { position: cc.v3(100, 100, 0) })
    .to(0.5, { position: cc.v3(0, 100, 0) })
    .to(0.5, { position: cc.v3(0, 0, 0) })
    .union()       // 将上面的动作合并为一个
    .repeatForever() // 无限循环
    .start();

// 并行动画
cc.tween(this.node)
    .parallel(
        cc.tween().to(1, { position: cc.v3(100, 100, 0) }),
        cc.tween().to(1, { scale: 2 }),
        cc.tween().to(1, { opacity: 128 }),
    )
    .start();

// 回调
cc.tween(this.node)
    .to(1, { position: cc.v3(100, 0, 0) })
    .call(() => {
        cc.log("移动完成");
    })
    .delay(1)
    .to(1, { position: cc.v3(0, 0, 0) })
    .start();

// 停止缓动
cc.Tween.stopAllByTarget(this.node);  // 停止节点上所有缓动

// 在 onDestroy 中务必停止
onDestroy(): void {
    cc.Tween.stopAllByTarget(this.node);
}
```

---

## 动作系统

> cc.Action 是旧版动画系统，2.4 仍支持但推荐使用 cc.tween

```typescript
// 移动
const moveAction = cc.moveTo(1, cc.v2(100, 200));

// 缩放
const scaleAction = cc.scaleTo(0.5, 2);

// 旋转
const rotateAction = cc.rotateTo(1, 90);

// 淡入淡出
const fadeIn = cc.fadeIn(0.5);
const fadeOut = cc.fadeOut(0.5);

// 序列
const seq = cc.sequence(moveAction, scaleAction, rotateAction);

// 同时执行
const spawn = cc.spawn(moveAction, scaleAction);

// 重复
const repeat = cc.repeat(seq, 3);
const forever = cc.repeatForever(seq);

// 执行
this.node.runAction(seq);

// 停止
this.node.stopAllActions();
```

---

## 计时器

```typescript
// 延迟执行
this.scheduleOnce(() => {
    cc.log("1秒后执行");
}, 1);

// 重复执行（间隔, 重复次数, 延迟开始）
this.schedule(() => {
    cc.log("每秒执行一次");
}, 1, cc.macro.REPEAT_FOREVER, 0);

// 指定次数
this.schedule(this.spawnEnemy, 2, 10, 0); // 每2秒，共10次

// 取消计时器
this.unschedule(this.spawnEnemy);
this.unscheduleAllCallbacks();
```

---

## 常见错误

### ❌ 不要

1. **在 onLoad 中引用其他组件** → 使用 start()，因为其他组件可能尚未 onLoad
2. **忘记注销事件** → 在 onDisable/onDestroy 中配对 off
3. **destroy 后立即访问节点** → destroy 是延迟的，在当帧结束才执行
4. **在 update 中创建新对象** → 预分配并复用
5. **cc.find 过度使用** → 性能差，用 @property 替代
6. **忘记停止 cc.tween** → 在 onDestroy 中调用 cc.Tween.stopAllByTarget
7. **混淆 2.4 和 3.x API** → 2.4 用 `cc.` 前缀，3.x 直接 import

### ✅ 要做

1. **@property 获取引用** → 比 cc.find 性能更好
2. **onLoad 做自身初始化** → start 做交叉引用初始化
3. **onEnable/onDisable 配对事件** → 确保启用/禁用时正确注册/注销
4. **onDestroy 清理所有资源** → 停止缓动、释放资源、清除引用
5. **CC_DEBUG 包裹日志** → 生产环境自动移除
6. **使用 cc.tween 替代 cc.Action** → 更现代、更灵活
