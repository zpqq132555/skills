# 代码质量审查清单 — LayaAir 1.0

> 提交 PR / 完成功能后，逐项确认代码质量符合 LayaAir 1.0 规范。

---

## 第一部分：Sprite 子类规范

### 构造函数与初始化
- [ ] 构造函数中设置纹理/图形，不调用 `Laya.loader.load()`（资源在外部预加载好）
- [ ] 帧循环在构造函数或专用 `init()` 方法中注册
- [ ] 引用到其他节点（如 `Laya.stage.getChildByName`）在初始化时缓存

### destroy 重写（强制）
- [ ] **每个 Sprite 子类都重写了 `destroy()`**
- [ ] `destroy()` 中先调用 `Laya.timer.clearAll(this)` 再调用 `super.destroy(destroyChild)`
- [ ] `destroy()` 中调用 `Laya.Tween.clearAll(this)` 清除缓动
- [ ] `destroy()` 中调用 `this.offAll()` 清除所有事件监听

---

## 第二部分：定时器规范

- [ ] 所有 `Laya.timer.frameLoop/loop/once` 登记的 `caller` 在 `destroy()` 中被 `clearAll` 释放
- [ ] 帧循环回调有早退出逻辑（对象已死亡/不活跃时立即 `return`）
- [ ] 帧循环回调中无对象创建（`new Array`, `new Laya.Point` 等）
- [ ] 不在回调外部取消定时器时直接调用 `timer.clear(this, fn)` 精准清除

---

## 第三部分：事件系统

- [ ] 所有自定义事件名已提取到 `GameEvent` 常量对象（无裸字符串）
- [ ] `on()` 始终使用命名方法（不使用匿名箭头函数）
- [ ] 每个 `on()` 有对应 `off()`（或 `destroy()` 中 `offAll()`）
- [ ] `Handler.create` 的 `once` 参数已合理设置
- [ ] 跨对象通信优先通过事件，不直接修改其他对象的私有属性

---

## 第四部分：资源管理

- [ ] 所有资源已在 Main 的加载阶段就绪（不在游戏运行中动态加载）
- [ ] `Laya.loader.getRes()` 返回值有 null 检查
- [ ] 骨骼动画的 3 个资源文件（.sk/.png/.atlas）全部加载后才创建 `Laya.Skeleton`
- [ ] 场景切换时调用 `Laya.loader.clearRes()` 释放旧资源
- [ ] 对象销毁时不调用 `Laya.loader.clearRes`（只在场景/关卡级别释放）

---

## 第五部分：性能检查

- [ ] 频繁创建/销毁的对象使用 `Laya.Pool` 对象池
- [ ] 静态/低频 UI 容器设置了 `cacheAs = "bitmap"`
- [ ] 节点隐藏使用 `visible = false`（不用 `alpha = 0`）
- [ ] `mouseEnabled = false` 设置在不需要交互的节点上
- [ ] 对象池回收时调用 `Laya.timer.clearAll`（停止帧循环）再 `Laya.Pool.recover`

---

## 第六部分：代码规范

- [ ] 无魔法数字（全部提取为 `static readonly` 常量）
- [ ] 无未使用的 `import` / 变量
- [ ] 无 `console.log` 遗留（或有明确用途标注）
- [ ] 私有方法/属性以 `_` 前缀命名
- [ ] 类只做一件事（不把渲染 + 逻辑 + 数据全堆在一个 Sprite 子类）

---

## 第七部分：架构合理性

- [ ] 游戏状态使用枚举（`GameState`），不用零散 boolean 标志
- [ ] 全局数据通过 `GameManager` 单例管理（分数、生命、关卡）
- [ ] 跨对象通信通过事件/Manager，不直接 `getChildByName` 操作其他对象
- [ ] 配置数据从 JSON 加载，不硬编码在类中

---

## 1.0 特殊检查项

- [ ] 无 `onAwake/onStart/onUpdate` 方法（1.0 没有 Script 组件，这些方法不会被调用）
- [ ] 所有更新逻辑在 `frameLoop` 或 `loop` 中（不依赖 Script 生命周期）
- [ ] 入口文件 `Main.ts` 中 `Laya.init()` 后立即进行资源加载（不绕过加载流程）

---

## 快速代码气味（Code Smell）检查

| 气味 | 示例 | 处理方式 |
|------|------|---------|
| `destroy()` 未重写 | `class EnemyView extends Laya.Sprite {}` 无 `destroy` | 必须重写，清理定时器 |
| 裸字符串事件名 | `node.on("hero-dead", ...)` | 提取 `GameEvent.HERO_DEAD` |
| `frameLoop` 中创建对象 | `const arr = []` 在每帧回调里 | 提前创建或用对象池 |
| 未检查 `getRes` | `const t = Laya.loader.getRes(url) as Laya.Texture; t.width` | 先判断 `t !== null` |
| 深嵌套 `Tween` 回调 | 4层 Tween 嵌套 | 提取为状态机 |
