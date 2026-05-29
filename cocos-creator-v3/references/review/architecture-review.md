# 架构审查清单 — Cocos Creator 3.8

> 📖 本文件为 `cocos-creator-3x-cn` 技能参考文件，提供代码架构审查的标准清单。

---

## 审查优先级

| 级别 | 说明 | 要求 |
|------|------|------|
| 🔴 P0 - 阻断 | 必须修复才能合并 | 运行时崩溃、资源泄漏、事件泄漏 |
| 🟡 P1 - 重要 | 建议当前迭代修复 | 架构违规、性能隐患 |
| 🟢 P2 - 建议 | 下次迭代修复 | 代码风格、可读性 |

---

## 1. 模块导入审查

### 检查项

- [ ] 🔴 所有引擎 API 通过 `import { ... } from 'cc'` 导入，不使用 `cc.` 前缀
- [ ] 🔴 环境宏通过 `import { DEBUG } from 'cc/env'` 导入，不使用 `CC_DEBUG`
- [ ] 🟡 导入按规范顺序排列（引擎核心 → UI 组件 → 项目公共 → 当前模块）
- [ ] 🟡 没有未使用的导入
- [ ] 🟢 没有 `import * as` 风格的全量导入

### 示例

```typescript
// ✅ 正确
import { _decorator, Component, Node, Vec3, Sprite } from 'cc';
import { DEBUG } from 'cc/env';
import { GameManager } from '../manager/GameManager';

// ❌ 错误
const { ccclass } = cc._decorator; // 2.x 风格
if (CC_DEBUG) { }                  // 2.x 宏
```

---

## 2. 组件声明审查

### 检查项

- [ ] 🔴 `@ccclass('Name')` 参数与类名一致且全局唯一
- [ ] 🔴 属性 `@property` 正确声明类型
- [ ] 🟡 引用类型属性使用 `Type | null = null` 或 `Type = null!`（非空断言仅限确定编辑器赋值的场景）
- [ ] 🟡 不在构造函数中初始化逻辑（使用 `onLoad`/`start`）
- [ ] 🟢 组件遵循单一职责原则
- [ ] 🟢 使用 `@requireComponent` 声明依赖

### 示例

```typescript
// ✅
@ccclass('PlayerController')
export class PlayerController extends Component {
    @property(Node)
    private readonly target: Node | null = null;
    
    @property
    private readonly speed = 10;
}

// ❌ cc 类名与类名不一致
@ccclass('Player')
export class PlayerController extends Component { }

// ❌ 未声明类型的引用属性
@property
target = null; // 编辑器无法识别类型
```

---

## 3. 生命周期审查

### 检查项

- [ ] 🔴 `onEnable` 中注册的事件在 `onDisable` 中全部注销
- [ ] 🔴 `onDestroy` 中释放了所有动态加载的资源（`decRef` / `releaseAsset`）
- [ ] 🔴 `onDestroy` 中停止了所有缓动和定时器
- [ ] 🟡 `onLoad` 不依赖其他组件的 `start` 初始化结果
- [ ] 🟡 不在 `update` 中每帧调用 `find`/`getComponent`
- [ ] 🟢 `update` 中不创建临时对象（`new Vec3()` 等）

### 事件配对检查器

```
onEnable 调用的 on()   →   onDisable 必须有对应 off()
onLoad 调用的 on()     →   onDestroy 必须有对应 off()
```

---

## 4. 事件系统审查

### 检查项

- [ ] 🔴 使用枚举常量注册事件（`Node.EventType.TOUCH_START`），不使用字符串
- [ ] 🔴 事件回调使用named function/方法引用，不使用匿名函数（否则无法 off）
- [ ] 🔴 自定义事件类继承自 `Event`，不直接 `new Event()`（Event 是抽象类）
- [ ] 🟡 `EventTarget` 用于自定义事件，不通过 `Node` 做自定义事件
- [ ] 🟡 `emit` 参数不超过 5 个
- [ ] 🟢 触摸事件穿透使用 `event.preventSwallow`

---

## 5. 资源管理审查

### 检查项

- [ ] 🔴 动态加载的资源有明确的释放策略（`addRef`/`decRef` 或手动 `releaseAsset`）
- [ ] 🔴 `resources` 目录仅包含需要动态加载的资源
- [ ] 🔴 加载回调处理了 `err` 参数
- [ ] 🟡 使用预加载（`preload`）优化体验
- [ ] 🟡 大量资源使用 Asset Bundle 分模块
- [ ] 🟡 场景勾选自动释放（高频主场景除外）
- [ ] 🟢 加载路径使用常量/配置，不硬编码

---

## 6. 性能架构审查

### 检查项

- [ ] 🔴 频繁创建销毁的节点使用对象池
- [ ] 🟡 Draw Call 在合理范围（2D < 50）
- [ ] 🟡 使用图集合并碎图
- [ ] 🟡 低频逻辑使用 `schedule` 而非 `update`
- [ ] 🟢 使用 `Vec3.set/copy` 复用对象，避免 `new Vec3()`
- [ ] 🟢 使用距离平方比较替代距离比较

---

## 7. TypeScript 质量审查

### 检查项

- [ ] 🔴 没有 `any` 类型（必要时使用 `unknown` + 类型守卫）
- [ ] 🔴 没有未捕获的异步错误
- [ ] 🟡 使用可选链 `?.` 和空值合并 `??`
- [ ] 🟡 枚举在编辑器使用时调用了 `Enum()`
- [ ] 🟡 `const enum` 用于纯代码常量（编译内联）
- [ ] 🟢 调试代码用 `DEBUG` 宏包裹
- [ ] 🟢 没有 `console.log` 残留（或有 `DEBUG` 保护）

---

## 8. 项目结构审查

### 检查项

- [ ] 🟡 文件命名 PascalCase 与类名一致
- [ ] 🟡 目录结构清晰（common/manager/ui/game/config/data）
- [ ] 🟡 没有循环依赖
- [ ] 🟡 公共工具类提取到 common 目录
- [ ] 🟢 README 文档更新

---

## 审查报告模板

```markdown
## 架构审查报告

**文件**: `PlayerController.ts`
**审查日期**: YYYY-MM-DD
**审查人**: XXX

### P0 - 阻断
- [ ] `onEnable` 注册了 TOUCH_START 但 `onDisable` 未注销 (L42)
- [ ] 动态加载的 Prefab 未调用 `addRef`，可能被意外释放 (L78)

### P1 - 重要
- [ ] `update` 中每帧调用 `find('Canvas/Enemy')` (L55)
- [ ] 缺少加载错误处理 (L78)

### P2 - 建议
- [ ] 使用魔法数字 `0.5` 作为移动倍率 (L60)，建议提取常量
- [ ] 残留 `console.log` (L90)
```
