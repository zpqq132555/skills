# 代码质量审查清单 — Cocos Creator 3.8

> 📖 本文件为 `cocos-creator-3x-cn` 技能参考文件，提供代码质量审查的详细清单。

---

## 1. 代码正确性

### 1.1 类型安全

| 检查项 | 严重级 | 说明 |
|--------|--------|------|
| 无 `as any` 类型断言 | 🔴 | 使用正确类型或 `unknown` + 类型守卫 |
| 属性正确声明可空性 | 🔴 | `Node \| null = null` 或 `Node = null!` |
| 无隐式 `any` | 🟡 | tsconfig 开启 `strict` / `noImplicitAny` |
| 回调参数类型正确 | 🟡 | `(event: EventTouch)` 而非 `(event: any)` |
| 泛型类型明确 | 🟢 | `assetManager.loadRemote<ImageAsset>(...)` |

### 1.2 空值安全

```typescript
// ✅ 审查通过模式
const sprite = this.node.getComponent(Sprite);
if (!sprite) {
    console.error('Sprite component not found');
    return;
}
sprite.spriteFrame = newFrame;

// ✅ 可选链 + 提前返回
private onTouchStart(event: EventTouch): void {
    const target = this.targetNode;
    if (!target) return;
    // 安全使用 target
}

// ❌ 审查不通过
const sprite = this.node.getComponent(Sprite)!; // 危险的非空断言（除非确定一定存在）
sprite.spriteFrame = newFrame;
```

---

## 2. 资源生命周期

### 2.1 加载-释放配对

```
每个 resources.load / bundle.load → 必须有对应的释放策略
每个 addRef()                     → 必须有对应的 decRef()
每个 instantiate()                → 必须有对应的 destroy()
```

### 2.2 审查清单

| 检查项 | 严重级 |
|--------|--------|
| load 回调处理了 err 参数 | 🔴 |
| 动态加载并长期持有的资源调用了 addRef | 🔴 |
| onDestroy 中为持有资源调用了 decRef | 🔴 |
| 对象池 clear 时释放资源引用 | 🔴 |
| instantiate 的节点在不需要时 destroy | 🟡 |
| 场景勾选自动释放（除主场景外） | 🟡 |
| 不在 resources 目录放不需要动态加载的资源 | 🟡 |

---

## 3. 事件生命周期

### 3.1 事件配对表

审查时构建以下配对表，确认每个 `on` 都有对应的 `off`：

```
┌─────────────┬──────────────────────┬───────────────────────┐
│ 注册位置     │ on() 调用            │ off() 对应位置         │
├─────────────┼──────────────────────┼───────────────────────┤
│ onEnable    │ input.on(TOUCH,...)  │ onDisable: input.off  │
│ onEnable    │ node.on(TOUCH,...)   │ onDisable: node.off   │
│ onLoad      │ eventBus.on(...)     │ onDestroy: eventBus.off│
└─────────────┴──────────────────────┴───────────────────────┘
```

### 3.2 常见问题

```typescript
// ❌ 匿名函数无法取消监听
onEnable() {
    input.on(Input.EventType.TOUCH_START, (e) => this.handleTouch(e), this);
    // onDisable 中无法 off 这个匿名函数！
}

// ✅ 使用方法引用
protected onEnable(): void {
    input.on(Input.EventType.TOUCH_START, this.handleTouch, this);
}
protected onDisable(): void {
    input.off(Input.EventType.TOUCH_START, this.handleTouch, this);
}
private handleTouch(event: EventTouch): void: void { /* ... */ }
```

---

## 4. 缓动与定时器

### 审查清单

| 检查项 | 严重级 |
|--------|--------|
| onDestroy 中调用了 `Tween.stopAllByTarget(this.node)` | 🔴 |
| onDestroy 中调用了 `this.unscheduleAllCallbacks()` | 🔴 |
| 缓动目标节点仍然有效（未被销毁） | 🟡 |
| 长时间运行的缓动有停止条件 | 🟡 |

```typescript
// ✅ 标准清理模式
protected onDestroy(): void {
    Tween.stopAllByTarget(this.node);
    this.unscheduleAllCallbacks();
}
```

---

## 5. update 循环质量

### 审查清单

| 检查项 | 严重级 | 说明 |
|--------|--------|------|
| 无 `new Vec3/Vec2/Color` 等对象创建 | 🟡 | 使用类成员缓存 |
| 无 `find()` / `getComponent()` 调用 | 🟡 | 提前缓存引用 |
| 无字符串拼接 | 🟢 | 缓存或使用模板 |
| 有提前返回跳过不必要逻辑 | 🟢 | `if (!this._active) return;` |
| 低频逻辑移到 schedule | 🟢 | AI/碰撞检测等 |

```typescript
// ✅ 审查通过的 update
private _tempVec = new Vec3();
private _isPlaying = false;

protected update(dt: number): void {
    if (!this._isPlaying) return;
    
    Vec3.set(this._tempVec, this.speed * dt, 0, 0);
    const pos = this.node.position;
    this.node.setPosition(pos.x + this._tempVec.x, pos.y, pos.z);
}
```

---

## 6. 编码风格

### 6.1 命名审查

| 检查项 | 严重级 |
|--------|--------|
| 类名 PascalCase | 🟡 |
| @ccclass 参数与类名一致 | 🟡 |
| 方法/属性 camelCase | 🟢 |
| 私有成员 `_` 前缀 | 🟢 |
| 常量 UPPER_SNAKE_CASE | 🟢 |
| 事件名 kebab-case | 🟢 |

### 6.2 代码组织

| 检查项 | 严重级 |
|--------|--------|
| 文件不超过 300 行 | 🟢 |
| 函数不超过 50 行 | 🟢 |
| 嵌套不超过 3 层 | 🟢 |
| Import 排列有序 | 🟢 |
| 无重复代码块 (>10行) | 🟡 |

---

## 7. 调试与日志

| 检查项 | 严重级 |
|--------|--------|
| 无裸露的 `console.log`（需 `DEBUG` 保护） | 🟡 |
| 错误日志使用 `console.error` | 🟢 |
| 无 `debugger` 语句 | 🔴 |
| 调试工具代码在 BUILD 模式下排除 | 🟡 |

```typescript
// ✅ 正确的日志模式
import { DEBUG } from 'cc/env';

if (DEBUG) {
    console.log('Debug info:', data);
}

// 错误始终记录
console.error('Critical error:', err);
```

---

## 8. 3.8 特定检查

### 从 2.x 升级相关

| 检查项 | 严重级 | 说明 |
|--------|--------|------|
| 不使用 `cc.` 前缀 | 🔴 | 3.x 使用 ES Module 导入 |
| 不使用 `CC_DEBUG` / `CC_EDITOR` | 🔴 | 使用 `import { DEBUG, EDITOR } from 'cc/env'` |
| 不使用 `cc.systemEvent` | 🟡 | 使用 `input` 对象 |
| 不使用 `Event.EventCustom` | 🟡 | 自定义类继承 `Event` |
| 不使用 `cc.Class({})` 声明 | 🔴 | 使用 `@ccclass` 装饰器 |
| 不使用 `cc.tween()` | 🟡 | 使用 `import { tween } from 'cc'` |

### 3.8 新特性检查

| 检查项 | 严重级 | 说明 |
|--------|--------|------|
| 正确使用 `@property` 声明类型 | 🟡 | 引用类型必须显式声明 |
| 使用 `input` 替代废弃的 `systemEvent` | 🟡 | v3.4+ 推荐 |
| Bundle 配置在项目设置中正确配置 | 🟡 | v3.8 移到项目设置 |

---

## 审查流程

```
1. 打开变更文件列表
2. 按优先级顺序检查：
   a. P0 阻断项 → 必须全部通过
   b. P1 重要项 → 确认修复计划
   c. P2 建议项 → 记录到改进清单
3. 输出审查报告
4. 跟踪修复状态
```

### 快速审查命令

```bash
# 搜索 2.x 风格代码
grep -rn "cc\.\|CC_DEBUG\|CC_EDITOR\|systemEvent" --include="*.ts" assets/scripts/

# 搜索裸露的 console.log
grep -rn "console\.log" --include="*.ts" assets/scripts/ | grep -v "DEBUG"

# 搜索 any 类型
grep -rn ": any\|as any" --include="*.ts" assets/scripts/

# 搜索未处理的 err
grep -rn "err," --include="*.ts" assets/scripts/ | grep -v "if.*err"
```
