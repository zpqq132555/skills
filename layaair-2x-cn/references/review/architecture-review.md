# 架构审查清单 — LayaAir 2.0

> 代码 / 功能实现完成后，按此清单检查架构是否符合 LayaAir 2.0 最佳实践。

---

## P0 — 必须修复（阻断上线）

### 内存与生命周期
- [ ] **每个 Script 的 `onDestroy()` 均调用** `Laya.timer.clearAll(this)` 和 `Laya.Tween.clearAll(this.owner)`
- [ ] **事件监听配对**：`onEnable/onStart` 中注册的 `on()` 在 `onDisable/onDestroy` 中有对应 `off()` 或 `offAll()`
- [ ] **`on()` 不使用匿名函数**（必须是命名方法才能被 `off()` 清除）
- [ ] **资源加载 Handler 正确还原**：一次性 `Handler.create(..., null, true)`；持久 Handler 最终调用 `recover()`
- [ ] **场景切换时释放旧场景资源**：`Laya.loader.clearRes()` 在切换后调用

### 崩溃风险
- [ ] `Laya.loader.getRes()` 结果做 null 检查后再使用
- [ ] 所有 `getChildByName` / `getChildAt` 结果有 null 守卫
- [ ] 图集帧名称与 `.atlas` 文件中的 key 一致（避免运行时 null）

---

## P1 — 应该修复（影响质量/性能）

### 性能
- [ ] **节点引用在 `onStart` 中缓存**，不在 `onUpdate` 中每帧调用 `getChildByName/getComponent`
- [ ] **`onUpdate` 中不创建临时对象**（`new Array`, `new Laya.Point` 等）
- [ ] **静态 UI 容器设置 `cacheAs = "bitmap"`**（减少 DrawCall）
- [ ] **使用对象池** (`Laya.Pool`) 复用频繁创建/销毁的节点（如子弹、特效）
- [ ] **隐藏节点使用 `visible = false`** 而非 `alpha = 0`（前者不参与渲染）
- [ ] **使用帧增量时间** `Laya.timer.delta / 1000` 而非固定步长（确保帧率无关移动速度）

### 架构
- [ ] **Manager 类用单例模式** (`static instance: XXX`)，不要重复创建
- [ ] **事件名常量化** — 不允许出现裸字符串事件名，使用 `GameEvent.XXX` 常量
- [ ] **游戏状态机明确** — 状态枚举定义，不用 boolean 堆砌状态
- [ ] **不在 Script 中持有其他 Script 强引用** — 使用事件解耦，或通过公共 Manager 通信
- [ ] **资源加载阶段前置** — 游戏用到的资源在进入游戏前全部加载完毕

---

## P2 — 建议改善（代码可维护性）

### 代码规范
- [ ] 私有属性统一 `_` 前缀
- [ ] 时间/速度/长度等数值有明确的单位注释（像素、毫秒、帧）
- [ ] 魔法数字提取为 `private static readonly` 常量
- [ ] 复杂逻辑有注释说明意图

### 目录结构
```
assets/scripts/
├── core/           # 基础框架（GameManager, EventBus 等单例）
├── game/           # 游戏逻辑（HeroScript, EnemyScript 等）
├── ui/             # UI 逻辑（HudScript, PopupScript 等）
├── data/           # 数据定义（config 接口，枚举，常量）
└── utils/          # 工具类（MathUtil, PoolUtil 等）
```

- [ ] Script 只放 **行为逻辑**（不放数据定义，不放纯工具函数）
- [ ] 数据配置文件（JSON）与代码分离，不把数值写死在 Script 中

---

## 启动流程检查

```
Laya.init → 加载启动资源 → 显示 Loading 界面
    → 批量加载游戏资源（进度回调更新 UI）
    → 所有资源就绪 → 进入游戏
```

- [ ] 是否有 Loading 界面防止黑屏？
- [ ] 批量加载是否使用了 `progressHandler`？
- [ ] 是否有加载失败处理（error 兜底）？

---

## 2.0 专项检查

- [ ] `Laya.Scene.open/close` 正确使用（不手动 `addChild` 场景文件）
- [ ] `@prop` 属性注解格式正确（用于 IDE 属性面板绑定）
- [ ] 物理碰撞（Box2D）使用 Script 回调 `onTriggerEnter` 而非手动检测
