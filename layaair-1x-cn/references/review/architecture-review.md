# 架构审查清单 — LayaAir 1.0

> 代码 / 功能实现完成后，按此清单检查架构是否符合 LayaAir 1.0 最佳实践。

---

## P0 — 必须修复（阻断上线）

### 内存与生命周期
- [ ] **每个 Sprite 子类都重写了 `destroy()`**，其中调用 `Laya.timer.clearAll(this)` + `Laya.Tween.clearAll(this)` + `super.destroy(destroyChild)`
- [ ] **事件监听配对清理**：所有 `on()` 在 `destroy()` 中有对应 `off()` 或调用 `offAll()`
- [ ] **`on()` 不使用匿名函数**（必须命名方法才能被 `off()` 清除）
- [ ] **`frameLoop/loop` 在 `destroy()` 前清除**（`timer.clearAll(this)` 要在 `super.destroy()` 之前）
- [ ] **加载 Handler 一次性 (`once=true`)** 或完成后手动 `recover()`

### 崩溃风险
- [ ] `Laya.loader.getRes()` 返回值做 null 检查
- [ ] 骨骼动画 3 个资源（.sk / .png / .atlas）全部加载后才创建 `Laya.Skeleton`
- [ ] 所有 `getChildByName` / `getChildAt` 结果有 null 守卫

---

## P1 — 应该修复（影响质量/性能）

### 性能
- [ ] **高频节点引用提前缓存**（构造函数或初始化时），不在 `frameLoop` 回调中每帧查找
- [ ] **`frameLoop` 回调中不创建临时对象**（`new Array`, `new Laya.Point` 等）
- [ ] **静态 UI 使用 `cacheAs = "bitmap"`**（减少 DrawCall）
- [ ] **使用对象池** (`Laya.Pool`) 复用子弹、特效等频繁对象
- [ ] **隐藏节点用 `visible = false`** 而非 `alpha = 0`
- [ ] **帧循环速度与帧率无关** — 参考 `Laya.timer.delta` 或使用固定物理步长

### 架构
- [ ] **单例 GameManager 模式** — 全局状态统一管理（分数、关卡、生命）
- [ ] **事件名常量化** — 不允许裸字符串，统一使用 `GameEvent.XXX` 常量
- [ ] **游戏状态机明确** — 通过枚举管理状态（`GameState.Idle/Playing/GameOver`），不用零散 boolean
- [ ] **资源加载阶段前置** — 游戏资源在 Main 的加载阶段全部就绪，进入游戏后不再加载

---

## P2 — 建议改善（代码可维护性）

### 代码规范
- [ ] 私有方法/属性统一 `_` 前缀
- [ ] 魔法数字提取为 `private static readonly` 常量
- [ ] 时间参数单位注释（毫秒 / 帧 / 秒）

### 目录结构

```
assets/
└── scripts/
    ├── core/       # GameManager, SoundManager 等单例
    ├── game/       # HeroView, EnemyView, BulletView 等游戏对象
    ├── ui/         # HudView, PopupView 等 UI 组件
    ├── data/       # 接口定义、枚举、GameEvent 常量
    └── utils/      # MathUtil, PoolUtil 等工具
```

- [ ] 不在 Sprite 子类中放数据定义或工具函数
- [ ] JSON 配置与代码分离（通过 `Laya.loader` 加载 JSON 获取配置）

---

## 启动流程检查

```
new Main() → Laya.init → Laya.loader.load(bootAssets) → 显示 Loading 界面
    → Laya.loader.load(gameAssets, complete, progress) → 更新进度条
    → 加载完成 → 释放 Loading 界面 → 创建 GameView → addChild(Laya.stage)
```

- [ ] 是否有 Loading 界面防止启动黑屏？
- [ ] 批量加载使用了 `progressHandler` (once=false)？
- [ ] 加载失败是否有 error 处理？

---

## 1.0 专项检查

- [ ] **不使用 Script 组件** — 1.0 没有 `Laya.Script`，所有组件继承 `Laya.Sprite`
- [ ] **没有 `onAwake/onStart/onUpdate`** — 改用 `frameLoop/loop`（若使用则代码会静默失效）
- [ ] **模块按需引入** — 只 `import` 实际用到的 `laya.*.js` 模块减少包体
- [ ] **骨骼动画模块** — 使用 `Laya.Skeleton` 需要引入 `laya.ani.js`
- [ ] **物理模块** — 使用碰撞需要引入 `laya.physics.js`（1.0 无内置 Box2D）
