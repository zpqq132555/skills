---
name: cocos-creator-2x-cn
description: 提供 Cocos Creator 2.4 游戏引擎的全面开发指导，包括组件系统（cc.Class、cc._decorator）、生命周期回调、事件系统、Asset Manager 资源管理、缓动/动作系统、对象池、UI 系统、物理碰撞以及可试玩广告优化。在用户编写或重构 Cocos Creator 2.x TypeScript/JavaScript 代码、实现游戏功能、处理资源加载与释放、优化性能/包体大小、审查代码变更、搭建可试玩广告项目架构时触发。也适用于用户提到 cc.Class、cc.Component、cc.Node、cc.resources、cc.assetManager、cc.tween 等 2.x API 时使用。
---

# Cocos Creator 2.4 开发规范

⚠️ **Cocos Creator 2.4（TypeScript 3.x / JavaScript ES6+）**：所有模式和示例均兼容 Cocos Creator 2.4.x 版本。

> 官方文档：https://docs.cocos.com/creator/2.4/manual/zh/
> API 参考：https://docs.cocos.com/creator/2.4/api/zh/

## 技能用途

此技能为 Cocos Creator 2.4 项目提供全面的开发规范指导，**代码质量优先**：

**优先级 1：代码质量与规范**（最重要）

- TypeScript 严格模式、访问修饰符（public/private/protected）
- 抛出异常（绝不静默错误）
- console.log 仅用于开发，生产构建中移除
- 不可变字段使用 readonly，常量使用 const
- 正确的错误处理和类型安全

**优先级 2：Cocos Creator 2.4 架构**

- cc.Class / cc._decorator 组件声明方式
- 生命周期：onLoad → onEnable → start → update → lateUpdate → onDisable → onDestroy
- 事件系统：cc.Node 事件、cc.Event.EventCustom、cc.systemEvent
- Asset Manager（cc.assetManager / cc.resources）资源管理
- cc.tween 缓动系统 + cc.Action 动作系统
- 对象池（cc.NodePool）、计时器（schedule）

**优先级 3：可试玩广告性能**

- DrawCall 合批（自动图集、BMFont）
- update() 循环中零内存分配
- 预加载与资源释放策略
- 包体大小 <5MB（纹理压缩、代码压缩）

## 触发条件

- 编写或重构 Cocos Creator 2.x TypeScript/JavaScript 代码
- 使用 cc.Class、cc._decorator、cc.Component 等 2.x API
- 处理节点（cc.Node）、组件、场景管理
- 实现事件监听与分发（on/off/emit/dispatchEvent）
- 使用 cc.resources.load、cc.assetManager 加载资源
- 使用 cc.tween 或 cc.Action 创建动画
- 使用对象池（cc.NodePool）优化性能
- 为可试玩广告优化包体和性能
- 审查 Cocos Creator 2.x 代码变更

## 快速参考指南

### 你需要什么帮助？

| 优先级 | 任务 | 参考文档 |
|--------|------|----------|
| **🔴 优先级 1：代码质量** | | |
| 1 | TypeScript 严格模式、访问修饰符 | [质量与规范](references/language/quality-hygiene.md) ⭐ |
| 1 | 错误处理、异常抛出 | [质量与规范](references/language/quality-hygiene.md) ⭐ |
| **🟢 优先级 2：Cocos 架构** | | |
| 2 | 组件系统、cc.Class、cc._decorator | [组件系统](references/framework/component-system.md) |
| 2 | 生命周期方法 | [组件系统](references/framework/component-system.md) |
| 2 | 事件系统、EventDispatcher | [事件模式](references/framework/event-patterns.md) |
| 2 | Asset Manager、资源加载与释放 | [资源管理](references/framework/asset-management.md) |
| 2 | cc.tween 缓动、cc.Action 动作 | [组件系统](references/framework/component-system.md) |
| **🔵 优先级 3：性能与审查** | | |
| 3 | DrawCall 合批、性能优化 | [可试玩广告优化](references/framework/playable-optimization.md) |
| 3 | Update 循环优化、零内存分配 | [性能优化](references/language/performance.md) |
| 3 | 包体大小缩减 | [可试玩广告优化](references/framework/playable-optimization.md) |
| 3 | 架构审查 | [架构审查](references/review/architecture-review.md) |
| 3 | 质量审查 | [质量审查](references/review/quality-review.md) |

## ⚠️ Cocos Creator 2.4 vs 3.x 关键区别

| 特性 | 2.4 (本技能) | 3.x |
|------|-------------|-----|
| 类声明 | `cc.Class({})` 或 `cc._decorator` | `_decorator` from `'cc'` |
| 导入方式 | `const {ccclass, property} = cc._decorator` | `import { _decorator } from 'cc'` |
| 节点类型 | `cc.Node` | `Node` |
| 组件基类 | `cc.Component` | `Component` |
| 资源加载 | `cc.resources.load()` | `resources.load()` |
| 缓动系统 | `cc.tween()` | `tween()` |
| 向量 | `cc.v2()` / `cc.v3()` | `new Vec2()` / `new Vec3()` |
| 调试宏 | `CC_DEBUG` | `DEBUG` |

## 🔴 TypeScript 组件模式（推荐）

```typescript
const { ccclass, property } = cc._decorator;

@ccclass
export default class PlayerController extends cc.Component {
    @property(cc.Node)
    targetNode: cc.Node = null;

    @property
    moveSpeed: number = 100;

    private currentHealth: number = 100;
    private static readonly MAX_HEALTH: number = 100;

    onLoad(): void {
        if (!this.targetNode) {
            throw new Error("PlayerController: targetNode 未赋值");
        }
        this.node.on(cc.Node.EventType.TOUCH_START, this.onTouchStart, this);
    }

    start(): void {
        // 所有组件 onLoad 完成后，安全引用其他组件
    }

    onDestroy(): void {
        this.node.off(cc.Node.EventType.TOUCH_START, this.onTouchStart, this);
    }

    private onTouchStart(event: cc.Event.EventTouch): void {
        if (CC_DEBUG) {
            console.log("检测到触摸");
        }
        this.takeDamage(10);
    }

    private takeDamage(amount: number): void {
        this.currentHealth = Math.max(0, this.currentHealth - amount);
        if (this.currentHealth <= 0) {
            this.handlePlayerDeath();
        }
    }

    private handlePlayerDeath(): void {
        // 死亡逻辑
    }
}
```

## 🟢 JavaScript cc.Class 模式

```javascript
cc.Class({
    extends: cc.Component,

    properties: {
        targetNode: { default: null, type: cc.Node },
        moveSpeed: 100,
        playerName: { default: "Player", type: cc.String },
    },

    onLoad() {
        if (!this.targetNode) {
            cc.error("GameCtrl: targetNode 是必需的");
            return;
        }
        this.node.on(cc.Node.EventType.TOUCH_START, this.onTouchStart, this);
    },

    onDestroy() {
        this.node.off(cc.Node.EventType.TOUCH_START, this.onTouchStart, this);
    },

    onTouchStart(event) {
        cc.log("Touch detected at:", event.getLocation());
    },
});
```

## 🟢 事件系统模式

```typescript
// 自定义事件 - 使用 cc.EventTarget
const GameEvent = {
    SCORE_CHANGED: "score_changed",
    LEVEL_COMPLETE: "level_complete",
    PLAYER_DIED: "player_died",
};

// 全局事件管理器
const eventBus = new cc.EventTarget();

// 注册事件（在 onEnable 中）
eventBus.on(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);

// 注销事件（在 onDisable 中）
eventBus.off(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);

// 发射事件
eventBus.emit(GameEvent.SCORE_CHANGED, { oldScore: 0, newScore: 100 });

// 节点事件冒泡 - 使用 cc.Event.EventCustom
this.node.dispatchEvent(new cc.Event.EventCustom("my-event", true));
```

## 🟢 资源加载模式

```typescript
// cc.resources.load（v2.4+ 推荐）
cc.resources.load("prefabs/enemy", cc.Prefab, (err, prefab) => {
    if (err) { cc.error(err); return; }
    const node = cc.instantiate(prefab);
    this.node.addChild(node);
});

// 加载 SpriteFrame
cc.resources.load("textures/hero", cc.SpriteFrame, (err, spriteFrame) => {
    if (err) { cc.error(err); return; }
    this.getComponent(cc.Sprite).spriteFrame = spriteFrame;
});

// 场景加载
cc.director.loadScene("GameScene");

// 预加载
cc.director.preloadScene("GameScene", () => {
    cc.log("场景预加载完成");
});
```

## 🟢 cc.tween 缓动模式

```typescript
// cc.tween 链式调用
cc.tween(this.node)
    .to(1, { position: cc.v3(100, 200, 0) })
    .to(0.5, { scale: 2 })
    .call(() => { cc.log("动画完成"); })
    .start();

// 序列动画
cc.tween(this.node)
    .to(0.3, { opacity: 0 })
    .to(0.3, { opacity: 255 })
    .union()
    .repeatForever()
    .start();

// 停止缓动
cc.Tween.stopAllByTarget(this.node);
```

## 代码审查清单

### 快速验证

**🔴 代码质量：**
- [ ] TypeScript 严格模式已启用
- [ ] 所有成员有访问修饰符
- [ ] 错误时抛出异常或 cc.error
- [ ] console.log 已包装在 CC_DEBUG 中
- [ ] 无 `any` 类型

**🟢 Cocos 架构：**
- [ ] 组件生命周期顺序正确
- [ ] 事件监听在 onEnable/onLoad 中注册
- [ ] 事件监听在 onDisable/onDestroy 中注销
- [ ] 资源在不需要时正确释放
- [ ] cc.tween 在节点销毁前停止
- [ ] @property / properties 声明正确

**🔵 性能：**
- [ ] update() 中无内存分配
- [ ] 使用自动图集减少 DrawCall
- [ ] 对象池用于频繁创建/销毁
- [ ] 纹理压缩已启用

## 详细参考

### 框架

- [组件系统](references/framework/component-system.md) - cc.Class/cc._decorator、生命周期、@property、缓动/动作
- [事件模式](references/framework/event-patterns.md) - 节点事件、自定义事件、键盘事件、触摸事件
- [资源管理](references/framework/asset-management.md) - cc.resources、cc.assetManager、Asset Bundle、资源释放
- [可试玩广告优化](references/framework/playable-optimization.md) - DrawCall、对象池、包体优化

### 语言

- [质量与规范](references/language/quality-hygiene.md) - 严格模式、访问修饰符、错误处理
- [性能优化](references/language/performance.md) - Update 循环、内存分配、缓存策略

### 审查

- [架构审查](references/review/architecture-review.md) - 组件、生命周期、事件泄漏
- [质量审查](references/review/quality-review.md) - TypeScript 质量、最佳实践

## 关键词

cocos creator, cocos creator 2.4, cocos 2.x, cc.Class, cc.Component, cc.Node, cc._decorator, ccclass, property, 生命周期, onLoad, start, update, onDestroy, cc.resources, cc.assetManager, cc.tween, cc.Action, cc.NodePool, cc.EventTarget, 可试玩广告, playable ad, 游戏开发, 组件系统, 事件系统, 资源管理, 对象池, 缓动系统
