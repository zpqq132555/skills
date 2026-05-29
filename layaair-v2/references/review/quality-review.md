# 代码质量审查清单 — LayaAir 2.0

> 提交 PR / 完成功能后，逐项确认代码质量符合 LayaAir 2.0 规范。

---

## 第一部分：Script 组件规范

### 生命周期
- [ ] `onStart` 中获取并缓存子节点/组件引用（不在 `onUpdate` 中查找）
- [ ] `onUpdate` 仅包含每帧必要逻辑，不包含 DOM 查找或对象创建
- [ ] `onDisable` 清理定时器（`Laya.timer.clearAll(this)`）
- [ ] `onDestroy` 清理定时器、缓动、Handler（`timer.clearAll` + `Tween.clearAll`）
- [ ] `onEnable` / `onDisable` 配对事件注册/注销

### 属性注解
- [ ] IDE 可配置属性有 `@prop` 注解，格式正确
- [ ] 公有属性有 TypeScript 类型标注
- [ ] 私有属性使用 `_` 前缀

---

## 第二部分：事件系统

- [ ] 所有自定义事件名已提取到常量对象（`GameEvent.XXX`）
- [ ] `on()` 始终使用命名方法（不使用匿名箭头函数）
- [ ] 每个 `on()` 有对应 `off()`（或在 `onDestroy` 中 `offAll()`）
- [ ] `Handler.create` 的 `once` 参数已合理设置
- [ ] 跨节点通信通过事件（不直接操作其他节点的私有属性）

---

## 第三部分：资源管理

- [ ] 所有资源在使用前已通过 `Laya.loader.load()` 加载
- [ ] `Laya.loader.getRes()` 结果在使用前有 null 检查
- [ ] 图集帧名与 `.atlas` 文件对齐（无拼写错误）
- [ ] 场景关闭时调用 `Laya.loader.clearRes()` 释放专属资源
- [ ] `Handler.create(..., true)` 一次性 Handler 不需要手动 `recover`；持久 Handler 有 `recover()` 调用

---

## 第四部分：性能检查

- [ ] `onUpdate` 中无临时对象创建（`new Array`, `new Point` 等）
- [ ] 频繁创建/销毁的对象使用 `Laya.Pool` 对象池
- [ ] 静态/低频 UI 容器设置了 `cacheAs = "bitmap"`
- [ ] 节点隐藏使用 `visible = false`（不用 `alpha = 0`）
- [ ] 位移/速度计算使用 `Laya.timer.delta` 进行帧率无关处理
- [ ] 无用的 `mouseEnabled = true`（不需要交互的节点设为 `false`）

---

## 第五部分：代码规范

- [ ] 无魔法数字（全部提取为 `static readonly` 常量）
- [ ] 无未使用的 `import` / 变量
- [ ] 无 `console.log` 遗留（或已注释说明用途）
- [ ] 复杂逻辑有注释说明意图
- [ ] `any` 类型仅在对接外部 JSON 数据时使用，其余场景有明确类型

---

## 第六部分：架构合理性

- [ ] 单一职责：一个 Script 只做一件事（不把 UI + 游戏逻辑 + 数据全堆在一起）
- [ ] 游戏状态使用枚举管理（`GameState.Playing`），不用零散 boolean 标志
- [ ] 跨系统通信通过 EventBus / Manager，不直接引用其他系统的私有状态
- [ ] 配置数据从 JSON 文件加载，不硬编码在 Script 中

---

## 快速代码气味（Code Smell）检查

| 气味 | 示例 | 处理方式 |
|------|------|---------|
| 超长 `onUpdate` | 超过 30 行的 `onUpdate` | 拆分为多个私有方法 |
| 深嵌套缓动回调 | 3层以上 `Tween.to` 嵌套 | 提取为状态机 / 序列队列 |
| 裸字符串事件 | `node.on("hero-dead", ...)` | 提取 `HeroEvent.DEAD` 常量 |
| 大量 `getChildByName` | 散落各处的节点查找 | `onStart` 统一缓存引用 |
| ScriptA 直接读 ScriptB | `(node.getComponent(EnemyScript) as any)._hp` | 通过事件或公共方法通信 |
