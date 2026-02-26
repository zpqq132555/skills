---
name: theone-cocos-standards-cn
description: 执行 TheOne Studio Cocos Creator 开发规范，包括 TypeScript 编码模式、Cocos Creator 3.x 架构（组件系统、EventDispatcher）以及可试玩广告优化指南。在编写、审查或重构 Cocos TypeScript 代码、实现可试玩广告功能、优化性能/包体大小或审查代码变更时触发。
---

# TheOne Studio Cocos Creator 开发规范

⚠️ **Cocos Creator 3.x (TypeScript 4.1+)：** 所有模式和示例均兼容 Cocos Creator 3.x 可试玩广告开发。

## 技能用途

此技能执行 TheOne Studio 的 Cocos Creator 综合开发规范，**代码质量优先**：

**优先级 1：代码质量与规范**（最重要）

- TypeScript 严格模式、ESLint 配置、访问修饰符（public/private/protected）
- 抛出异常（绝不静默错误）
- console.log 仅用于开发，生产构建中移除
- 不可变字段使用 readonly，常量使用 const
- 不使用行内注释（使用描述性命名）
- 正确的错误处理和类型安全

**优先级 2：现代 TypeScript 模式**

- 数组方法（map/filter/reduce）替代循环
- 箭头函数、解构、展开运算符
- 可选链、空值合并
- 类型守卫、工具类型（Partial、Required、Readonly）
- 现代 TypeScript 特性

**优先级 3：Cocos Creator 架构**

- 基于组件的实体-组件（EC）系统
- 生命周期方法：onLoad→start→onEnable→update→onDisable→onDestroy
- EventDispatcher 自定义事件模式
- 节点事件系统（EventTouch、键盘事件）
- 可试玩广告的资源管理和对象池

**优先级 4：可试玩广告性能**

- DrawCall 合批（目标 <10 个 DrawCall）
- 精灵图集配置（启用自动图集）
- 骨骼动画的 GPU 蒙皮
- update() 循环中零内存分配
- 包体大小 <5MB（纹理压缩、代码压缩）

## 触发条件

- 编写或重构 Cocos Creator TypeScript 代码
- 实现可试玩广告功能
- 使用组件生命周期和事件
- 为可试玩广告优化性能
- 审查代码变更或拉取请求
- 搭建可试玩广告项目架构
- 减少包体大小或 DrawCall 数量

## 快速参考指南

### 你需要什么帮助？

| 优先级                              | 任务                                               | 参考文档                                                                |
| ----------------------------------- | -------------------------------------------------- | ----------------------------------------------------------------------- |
| **🔴 优先级 1：代码质量（首先检查）** |                                                    |                                                                         |
| 1                                   | TypeScript 严格模式、ESLint、访问修饰符             | [质量与规范](references/language/quality-hygiene.md) ⭐                  |
| 1                                   | 抛出异常、正确错误处理                              | [质量与规范](references/language/quality-hygiene.md) ⭐                  |
| 1                                   | console.log（仅开发使用）、生产环境移除             | [质量与规范](references/language/quality-hygiene.md) ⭐                  |
| 1                                   | readonly/const、不使用行内注释、描述性命名          | [质量与规范](references/language/quality-hygiene.md) ⭐                  |
| **🟡 优先级 2：现代 TypeScript 模式** |                                                    |                                                                         |
| 2                                   | 数组方法、箭头函数、解构                            | [现代 TypeScript](references/language/modern-typescript.md)             |
| 2                                   | 可选链、空值合并                                    | [现代 TypeScript](references/language/modern-typescript.md)             |
| 2                                   | 类型守卫、工具类型                                  | [现代 TypeScript](references/language/modern-typescript.md)             |
| **🟢 优先级 3：Cocos 架构**          |                                                    |                                                                         |
| 3                                   | 组件系统、@property 装饰器                          | [组件系统](references/framework/component-system.md)                    |
| 3                                   | 生命周期方法（onLoad→start→update→onDestroy）       | [组件系统](references/framework/component-system.md)                    |
| 3                                   | EventDispatcher、节点事件、清理                     | [事件模式](references/framework/event-patterns.md)                      |
| 3                                   | 资源加载、对象池、内存管理                          | [可试玩广告优化](references/framework/playable-optimization.md)         |
| **🔵 优先级 4：性能与审查**          |                                                    |                                                                         |
| 4                                   | DrawCall 合批、精灵图集、GPU 蒙皮                   | [可试玩广告优化](references/framework/playable-optimization.md)         |
| 4                                   | Update 循环优化、零内存分配                         | [性能优化](references/language/performance.md)                          |
| 4                                   | 包体大小缩减（<5MB 目标）                           | [包体优化](references/framework/size-optimization.md)                   |
| 4                                   | 架构审查（组件、生命周期、事件）                    | [架构审查](references/review/architecture-review.md)                    |
| 4                                   | TypeScript 质量审查                                 | [质量审查](references/review/quality-review.md)                         |
| 4                                   | 性能审查（DrawCall、内存分配）                      | [性能审查](references/review/performance-review.md)                     |

## 🔴 关键：代码质量规则（首先检查！）

### ⚠️ 强制质量标准

**在编写任何代码之前，始终执行以下规则：**

1. **启用 TypeScript 严格模式** - tsconfig.json 中设置 "strict": true
2. **使用 ESLint 配置** - 启用 @typescript-eslint 规则
3. **使用访问修饰符** - 所有成员使用 public/private/protected
4. **错误时抛出异常** - 绝不静默失败或返回 undefined
5. **console.log 仅用于开发** - 生产构建中移除所有 console 语句
6. **不可变字段使用 readonly** - 标记不会被重新赋值的字段
7. **常量使用 const** - 常量应使用 const，而非 let
8. **不使用行内注释** - 使用描述性命名；代码应自解释
9. **正确处理 null/undefined** - 使用可选链和空值合并
10. **类型安全** - 避免 `any` 类型，使用正确的类型和接口

**示例：质量优先**

```typescript
// ✅ 优秀：所有质量规则已执行
import { _decorator, Component, Node, EventTouch } from "cc";
const { ccclass, property } = _decorator;

@ccclass("PlayerController")
export class PlayerController extends Component {
  // 3. 访问修饰符，6. 不可变使用 readonly
  @property(Node)
  private readonly targetNode: Node | null = null;

  // 7. 常量使用 const
  private static readonly MAX_HEALTH: number = 100;
  private currentHealth: number = 100;

  // 生命周期：onLoad → start → onEnable
  protected onLoad(): void {
    // 4. 错误时抛出异常
    if (!this.targetNode) {
      throw new Error("PlayerController: targetNode 未赋值");
    }

    // 9. 正确的事件监听设置
    this.node.on(Node.EventType.TOUCH_START, this.onTouchStart, this);
  }

  protected onDestroy(): void {
    // 9. 始终清理事件监听
    this.node.off(Node.EventType.TOUCH_START, this.onTouchStart, this);
  }

  private onTouchStart(event: EventTouch): void {
    // 5. console.log 仅用于开发（生产环境移除）
    if (CC_DEBUG) {
      console.log("检测到触摸");
    }

    this.takeDamage(10);
  }

  // 8. 描述性方法名（无需行内注释）
  private takeDamage(amount: number): void {
    this.currentHealth -= amount;

    if (this.currentHealth <= 0) {
      this.handlePlayerDeath();
    }
  }

  private handlePlayerDeath(): void {
    // 死亡逻辑
  }
}
```

## ⚠️ Cocos Creator 架构规则（质量之后）

### 组件系统基础

**实体-组件（EC）系统：**

- 组件继承 `Component` 类
- 使用 `@ccclass` 和 `@property` 装饰器
- 生命周期：onLoad → start → onEnable → update → lateUpdate → onDisable → onDestroy

**执行顺序：**

1. **onLoad()** - 组件初始化，一次性设置
2. **start()** - 所有组件加载完成后，可引用其他组件
3. **onEnable()** - 组件/节点启用时（可多次调用）
4. **update(dt)** - 每帧调用（可试玩广告中谨慎使用）
5. **lateUpdate(dt)** - 所有 update() 调用之后
6. **onDisable()** - 组件/节点禁用时
7. **onDestroy()** - 清理、移除监听器、释放资源

**通用规则：**

- ✅ 在 onLoad() 中初始化，在 start() 中引用其他组件
- ✅ 在 onEnable() 中注册事件，在 onDisable() 中注销事件
- ✅ 始终在 onDestroy() 中清理监听器
- ✅ 避免在 update() 中执行繁重逻辑（可试玩广告性能关键）
- ✅ @property 字段不被重新赋值时使用 readonly
- ✅ 必要引用缺失时抛出异常

## 简要示例

### 🔴 代码质量优先

```typescript
// ✅ 优秀：质量规则已执行
import { _decorator, Component, Node } from "cc";
const { ccclass, property } = _decorator;

@ccclass("GameManager")
export class GameManager extends Component {
  @property(Node)
  private readonly playerNode: Node | null = null;

  private static readonly MAX_SCORE: number = 1000;
  private currentScore: number = 0;

  protected onLoad(): void {
    // 必要引用缺失时抛出异常
    if (!this.playerNode) {
      throw new Error("GameManager: playerNode 是必需的");
    }

    if (CC_DEBUG) {
      console.log("GameManager 已初始化"); // 仅开发使用
    }
  }

  public addScore(points: number): void {
    if (points <= 0) {
      throw new Error("GameManager.addScore: points 必须为正数");
    }

    this.currentScore = Math.min(
      this.currentScore + points,
      GameManager.MAX_SCORE,
    );
  }
}
```

### 🟡 现代 TypeScript 模式

```typescript
// ✅ 好：使用数组方法替代循环
const activeEnemies = allEnemies.filter((e) => e.isActive);
const enemyPositions = activeEnemies.map((e) => e.node.position);

// ✅ 好：可选链和空值合并
const playerName = player?.name ?? "未知";

// ✅ 好：解构
const { x, y } = this.node.position;

// ✅ 好：箭头函数
this.enemies.forEach((enemy) => enemy.takeDamage(10));

// ✅ 好：类型守卫
function isPlayer(node: Node): node is PlayerNode {
  return node.getComponent(PlayerController) !== null;
}
```

### 🟢 Cocos Creator 组件模式

```typescript
import { _decorator, Component, Node, EventTouch, Vec3 } from "cc";
const { ccclass, property } = _decorator;

@ccclass("TouchHandler")
export class TouchHandler extends Component {
  @property(Node)
  private readonly targetNode: Node | null = null;

  private readonly tempVec3: Vec3 = new Vec3(); // 可复用向量

  // 1. onLoad：初始化组件
  protected onLoad(): void {
    if (!this.targetNode) {
      throw new Error("TouchHandler: targetNode 是必需的");
    }
  }

  // 2. start：引用其他组件（如需要）
  protected start(): void {
    // 此处可安全访问其他组件
  }

  // 3. onEnable：注册事件监听
  protected onEnable(): void {
    this.node.on(Node.EventType.TOUCH_START, this.onTouchStart, this);
    this.node.on(Node.EventType.TOUCH_MOVE, this.onTouchMove, this);
  }

  // 4. onDisable：注销事件监听
  protected onDisable(): void {
    this.node.off(Node.EventType.TOUCH_START, this.onTouchStart, this);
    this.node.off(Node.EventType.TOUCH_MOVE, this.onTouchMove, this);
  }

  // 5. onDestroy：最终清理
  protected onDestroy(): void {
    // 释放其他资源
  }

  private onTouchStart(event: EventTouch): void {
    // 处理触摸
  }

  private onTouchMove(event: EventTouch): void {
    // 复用向量以避免内存分配
    this.targetNode!.getPosition(this.tempVec3);
    this.tempVec3.y += 10;
    this.targetNode!.setPosition(this.tempVec3);
  }
}
```

### 🟢 事件分发器模式

```typescript
import { _decorator, Component, EventTarget } from "cc";
const { ccclass } = _decorator;

// 自定义事件类型
export enum GameEvent {
  SCORE_CHANGED = "score_changed",
  LEVEL_COMPLETE = "level_complete",
  PLAYER_DIED = "player_died",
}

export interface ScoreChangedEvent {
  oldScore: number;
  newScore: number;
}

@ccclass("EventManager")
export class EventManager extends Component {
  private static instance: EventManager | null = null;
  private readonly eventTarget: EventTarget = new EventTarget();

  protected onLoad(): void {
    if (EventManager.instance) {
      throw new Error("EventManager: 实例已存在");
    }
    EventManager.instance = this;
  }

  public static emit(event: GameEvent, data?: any): void {
    if (!EventManager.instance) {
      throw new Error("EventManager: 实例未初始化");
    }
    EventManager.instance.eventTarget.emit(event, data);
  }

  public static on(event: GameEvent, callback: Function, target?: any): void {
    if (!EventManager.instance) {
      throw new Error("EventManager: 实例未初始化");
    }
    EventManager.instance.eventTarget.on(event, callback, target);
  }

  public static off(event: GameEvent, callback: Function, target?: any): void {
    if (!EventManager.instance) {
      throw new Error("EventManager: 实例未初始化");
    }
    EventManager.instance.eventTarget.off(event, callback, target);
  }
}

// 在组件中使用
@ccclass("ScoreDisplay")
export class ScoreDisplay extends Component {
  protected onEnable(): void {
    EventManager.on(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);
  }

  protected onDisable(): void {
    EventManager.off(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);
  }

  private onScoreChanged(data: ScoreChangedEvent): void {
    console.log(`分数: ${data.oldScore} → ${data.newScore}`);
  }
}
```

### 🔵 可试玩广告性能优化

```typescript
import { _decorator, Component, Node, Sprite, SpriteAtlas } from "cc";
const { ccclass, property } = _decorator;

@ccclass("OptimizedSpriteManager")
export class OptimizedSpriteManager extends Component {
  // 使用精灵图集进行 DrawCall 合批
  @property(SpriteAtlas)
  private readonly characterAtlas: SpriteAtlas | null = null;

  // 预分配数组以避免 update() 中的内存分配
  private readonly tempNodes: Node[] = [];
  private frameCount: number = 0;

  protected onLoad(): void {
    if (!this.characterAtlas) {
      throw new Error("OptimizedSpriteManager: characterAtlas 是必需的");
    }

    // 从图集预热精灵帧
    this.prewarmSpriteFrames();
  }

  private prewarmSpriteFrames(): void {
    // 从图集加载所有精灵（在同一个 DrawCall 中合批）
    const spriteFrame = this.characterAtlas!.getSpriteFrame("character_idle");
    if (!spriteFrame) {
      throw new Error("图集中未找到精灵帧");
    }
  }

  // 优化 update：避免内存分配，使用对象池
  protected update(dt: number): void {
    // 每 N 帧运行昂贵操作，而不是每帧
    this.frameCount++;
    if (this.frameCount % 10 === 0) {
      this.updateExpensiveOperation();
    }
  }

  private updateExpensiveOperation(): void {
    // 复用数组而不是创建新数组
    this.tempNodes.length = 0;

    // 批量操作以减少 DrawCall
  }
}
```

## 代码审查清单

### 快速验证（提交前）

**🔴 代码质量（首先检查）：**

- [ ] tsconfig.json 中启用了 TypeScript 严格模式
- [ ] ESLint 规则通过（无错误）
- [ ] 所有访问修饰符正确（public/private/protected）
- [ ] 错误时抛出异常（无静默失败）
- [ ] console.log 已移除或包装在 CC_DEBUG 中
- [ ] 不被重新赋值的字段使用了 readonly
- [ ] 常量使用了 const
- [ ] 无行内注释（代码自解释）
- [ ] 正确的 null/undefined 处理
- [ ] 无 `any` 类型（使用正确的类型）

**🟡 现代 TypeScript 模式：**

- [ ] 使用数组方法替代手动循环
- [ ] 回调使用箭头函数
- [ ] 使用可选链（?.）安全访问属性
- [ ] 使用空值合并（??）设置默认值
- [ ] 使用解构简化代码
- [ ] 使用类型守卫进行类型收窄

**🟢 Cocos Creator 架构：**

- [ ] 组件生命周期方法顺序正确
- [ ] onLoad() 用于初始化，start() 用于引用
- [ ] 事件监听在 onEnable() 中注册
- [ ] 事件监听在 onDisable() 中注销
- [ ] 资源在 onDestroy() 中释放
- [ ] @property 装饰器使用正确
- [ ] 必要引用已验证（为 null 时抛出异常）

**🔵 可试玩广告性能：**

- [ ] update() 循环中无内存分配
- [ ] 使用精灵图集进行 DrawCall 合批
- [ ] 骨骼动画启用了 GPU 蒙皮
- [ ] 昂贵操作已节流（不是每帧执行）
- [ ] 频繁创建的对象使用了对象池
- [ ] 启用了纹理压缩
- [ ] 包体大小 <5MB 目标
- [ ] DrawCall 数量 <10 目标

## 常见错误避免

### ❌ 不要：

1. **忽略 TypeScript 严格模式** → 启用 "strict": true
2. **静默错误处理** → 错误时抛出异常
3. **生产环境保留 console.log** → 移除或包装在 CC_DEBUG 中
4. **跳过访问修饰符** → 使用 public/private/protected
5. **使用 `any` 类型** → 定义正确的类型和接口
6. **添加行内注释** → 使用描述性命名替代
7. **跳过事件清理** → 始终在 onDisable/onDestroy 中注销
8. **在 update() 中分配内存** → 预分配并复用对象
9. **忘记精灵图集** → 使用图集进行 DrawCall 合批
10. **update() 中执行繁重逻辑** → 节流昂贵操作
11. **跳过 null 检查** → 在 onLoad 中验证必要引用
12. **@property 字段可变** → 适当使用 readonly
13. **手动循环遍历数组** → 使用 map/filter/reduce
14. **忽略包体大小** → 监控并优化（<5MB 目标）

### ✅ 要做：

1. **启用 TypeScript 严格模式**（"strict": true）
2. **错误时抛出异常**（绝不静默失败）
3. **console.log 仅用于开发**（生产环境移除）
4. **使用访问修饰符**（public/private/protected）
5. **定义正确的类型**（避免 `any`）
6. **使用描述性命名**（无行内注释）
7. **始终清理事件**（onDisable/onDestroy）
8. **预分配对象**（在 update() 中复用）
9. **使用精灵图集**（DrawCall 合批）
10. **节流昂贵操作**（不要每帧执行）
11. **验证必要引用**（onLoad 中为 null 时抛出异常）
12. **@property 使用 readonly**（适当时）
13. **使用数组方法**（map/filter/reduce）
14. **监控包体大小**（可试玩广告 <5MB 目标）

## 审查严重级别

### 🔴 严重（必须修复）

- **TypeScript 严格模式未启用** - 必须启用 "strict": true
- **静默错误处理** - 必须为错误抛出异常
- **生产代码中的 console.log** - 移除或包装在 CC_DEBUG 中
- **缺少访问修饰符** - 所有成员必须有修饰符
- **无理由使用 `any` 类型** - 定义正确的类型
- **行内注释替代描述性命名** - 重命名并移除注释
- **事件监听器未清理** - 内存泄漏，必须注销
- **缺少必要引用验证** - onLoad 中为 null 时必须抛出异常
- **update() 循环中有内存分配** - 性能关键，必须预分配
- **多个精灵未使用图集** - DrawCall 爆炸，必须使用图集
- **包体大小 >5MB** - 超出可试玩广告限制，必须优化

### 🟡 重要（应该修复）

- **@property 字段缺少 readonly** - 不被重新赋值时应使用 readonly
- **常量缺少 const** - 应使用 const 而非 let
- **手动循环替代数组方法** - 应使用 map/filter/reduce
- **缺少可选链** - 应使用 ?. 安全访问
- **缺少空值合并** - 应使用 ?? 设置默认值
- **update() 中执行繁重逻辑** - 应节流昂贵操作
- **频繁分配无对象池** - 应实现对象池
- **未启用纹理压缩** - 应启用以减小包体
- **DrawCall 数量 >10** - 应优化合批

### 🟢 建议（锦上添花）

- 可以使用箭头函数作为回调
- 可以使用解构简化代码
- 可以使用类型守卫确保类型安全
- 可以改进命名以提高清晰度
- 可以添加接口以改善类型定义
- 可以优化算法以提升性能

## 详细参考

### TypeScript 语言规范

- [质量与规范](references/language/quality-hygiene.md) - 严格模式、ESLint、访问修饰符、错误处理
- [现代 TypeScript](references/language/modern-typescript.md) - 数组方法、可选链、类型守卫、工具类型
- [性能优化](references/language/performance.md) - Update 循环优化、零内存分配、缓存

### Cocos Creator 框架

- [组件系统](references/framework/component-system.md) - EC 系统、生命周期方法、@property 装饰器
- [事件模式](references/framework/event-patterns.md) - EventDispatcher、节点事件、订阅清理
- [可试玩广告优化](references/framework/playable-optimization.md) - DrawCall 合批、精灵图集、GPU 蒙皮、资源池
- [包体优化](references/framework/size-optimization.md) - 包体大小缩减、纹理压缩、构建优化

### 代码审查

- [架构审查](references/review/architecture-review.md) - 组件违规、生命周期错误、事件泄漏
- [质量审查](references/review/quality-review.md) - TypeScript 质量问题、访问修饰符、错误处理
- [性能审查](references/review/performance-review.md) - 可试玩广告特定性能问题、DrawCall、内存分配

## 总结

此技能为 TheOne Studio 的可试玩广告团队提供全面的 Cocos Creator 开发规范：

- **TypeScript 卓越**：严格模式、现代模式、类型安全
- **Cocos 架构**：组件生命周期、事件模式、资源管理
- **可试玩广告性能**：DrawCall 合批、GPU 蒙皮、<5MB 包体
- **代码质量**：强制执行质量、规范和性能规则

使用上方的快速参考指南导航到你需要的具体模式。
