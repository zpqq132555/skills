# 代码质量审查清单（Cocos Creator 2.4）

## 目录

- [代码审查流程](#代码审查流程)
- [TypeScript 质量检查](#typescript-质量检查)
- [Cocos 2.4 特定检查](#cocos-24-特定检查)
- [性能检查](#性能检查)
- [安全与健壮性](#安全与健壮性)

---

## 代码审查流程

### 审查优先级

1. **🔴 P0 - 阻断**：崩溃、内存泄漏、资源泄漏 → 必须修复
2. **🟡 P1 - 重要**：性能问题、架构问题 → 应该修复
3. **🟢 P2 - 建议**：命名、风格、可读性 → 建议优化

### 审查输出格式

```markdown
## 审查结果

### 🔴 P0（必须修复）
- [文件名#行号] 描述问题 → 建议修复方案

### 🟡 P1（应该修复）
- [文件名#行号] 描述问题 → 建议修复方案

### 🟢 P2（建议优化）
- [文件名#行号] 描述问题 → 建议修复方案
```

---

## TypeScript 质量检查

| # | 检查项 | 标准 | 级别 |
|---|--------|------|------|
| T1 | 显式返回类型 | 所有公共方法有返回类型注解 | 🟡 |
| T2 | 访问修饰符 | 所有成员有 public/private/protected | 🟡 |
| T3 | 无 any | 不使用 any 类型（除非有充分理由并注释） | 🔴 |
| T4 | const 优先 | 不变的变量使用 const | 🟢 |
| T5 | readonly | 不变的成员属性使用 readonly | 🟢 |
| T6 | 枚举/常量 | 无魔法数字和魔法字符串 | 🟡 |
| T7 | null 安全 | 可能为 null 的值有显式检查 | 🔴 |
| T8 | 接口定义 | 复杂数据结构有接口定义 | 🟡 |

### 检查示例

```typescript
// ✅ T1-T8 全部合格
interface ScoreData {
    readonly playerName: string;     // T5: readonly
    readonly score: number;
    readonly timestamp: number;
}

enum Difficulty {                    // T6: 枚举替代魔法值
    EASY = "easy",
    NORMAL = "normal",
    HARD = "hard",
}

@ccclass
export default class ScoreManager extends cc.Component {
    private static readonly SAVE_KEY: string = "scores";  // T2, T5, T6

    private scores: ScoreData[] = [];                      // T2

    public addScore(data: ScoreData): void {               // T1, T2, T8
        if (!data) {                                       // T7
            throw new Error("ScoreManager: data 不能为 null");
        }
        this.scores.push(data);
    }

    public getTopScore(): number {                          // T1
        if (this.scores.length === 0) return 0;             // T7
        const sorted = [...this.scores].sort((a, b) => b.score - a.score);
        return sorted[0].score;
    }
}
```

---

## Cocos 2.4 特定检查

| # | 检查项 | 标准 | 级别 |
|---|--------|------|------|
| C1 | 生命周期顺序 | onLoad→start→update→onDestroy 逻辑正确 | 🔴 |
| C2 | 事件清理 | on/off 配对在 onEnable/onDisable | 🔴 |
| C3 | 定时器清理 | onDestroy 中 unscheduleAllCallbacks | 🔴 |
| C4 | Tween 清理 | 节点销毁前停止所有 tween | 🔴 |
| C5 | 资源释放 | 动态加载资源有 addRef/decRef | 🔴 |
| C6 | 日志清理 | 生产代码无 console.log，使用 CC_DEBUG 包裹 | 🟡 |
| C7 | @property 类型 | 所有 @property 有正确的类型参数 | 🟡 |
| C8 | onLoad 校验 | 必要的编辑器引用在 onLoad 中校验 | 🟡 |
| C9 | Schedule 替代 | 不使用 setTimeout/setInterval | 🔴 |
| C10 | 音频管理 | 使用 cc.audioEngine，销毁时停止 | 🟡 |

### 事件泄漏快速检测

```typescript
// 审查时重点检查：
// 1. 搜索所有 .on( 调用
// 2. 确认每个 .on( 都有对应的 .off(
// 3. 确认 on/off 成对出现在 onEnable/onDisable

// ✅ 合格
onEnable(): void {
    this.node.on(cc.Node.EventType.TOUCH_START, this.onTouch, this);
    cc.systemEvent.on(cc.SystemEvent.EventType.KEY_DOWN, this.onKey, this);
}

onDisable(): void {
    this.node.off(cc.Node.EventType.TOUCH_START, this.onTouch, this);
    cc.systemEvent.off(cc.SystemEvent.EventType.KEY_DOWN, this.onKey, this);
}

// ❌ 不合格：只有 on 没有 off
onLoad(): void {
    this.node.on(cc.Node.EventType.TOUCH_START, this.onTouch, this);
    // 哪里 off？→ 内存泄漏
}
```

### 资源泄漏快速检测

```typescript
// 审查时重点检查：
// 1. 搜索所有 cc.resources.load / cc.assetManager 调用
// 2. 确认加载的资源有 addRef()
// 3. 确认 onDestroy 中有对应的 decRef()

// ✅ 合格
private prefab: cc.Prefab = null;

onLoad(): void {
    cc.resources.load("prefabs/Item", cc.Prefab, (err, prefab) => {
        if (err) return;
        this.prefab = prefab;
        this.prefab.addRef();     // 增加引用
    });
}

onDestroy(): void {
    if (this.prefab) {
        this.prefab.decRef();     // 减少引用
        this.prefab = null;
    }
}

// ❌ 不合格：加载无管理
onLoad(): void {
    cc.resources.load("prefabs/Item", cc.Prefab, (err, prefab) => {
        this.prefab = prefab;
        // 没有 addRef → 可能被引擎自动释放
        // 没有 decRef → 永远不会被释放
    });
}
```

---

## 性能检查

| # | 检查项 | 标准 | 级别 |
|---|--------|------|------|
| P1 | update 零分配 | update() 中无 new、无 cc.v2()、无 cc.v3() | 🔴 |
| P2 | 缓存组件 | getComponent 不在 update/循环中 | 🔴 |
| P3 | 避免 find | cc.find 不在 update/循环中 | 🔴 |
| P4 | 对象池 | 频繁创建/销毁的节点使用 cc.NodePool | 🟡 |
| P5 | DrawCall | 合批策略正确（同图集、同材质、连续渲染顺序） | 🟡 |
| P6 | 纹理大小 | 单张纹理不超过 1024x1024（可试玩广告不超过 512） | 🟡 |
| P7 | 数组循环 | 热路径使用 for 循环，不用 forEach/filter/map | 🟡 |
| P8 | 字符串操作 | 热路径不使用字符串拼接和比较 | 🟢 |

### update 性能审计模板

```typescript
// 对每个 update() 方法执行以下检查：

update(dt: number): void {
    // [P1] 检查：是否有 new 或工厂调用？
    // → ❌ cc.v2(1, 0) → 应使用预分配向量
    // → ❌ new cc.Color() → 应使用预分配颜色

    // [P2] 检查：是否有 getComponent()？
    // → ❌ this.getComponent(cc.Sprite) → 应在 onLoad 缓存

    // [P3] 检查：是否有 find / getChildByName？
    // → ❌ cc.find("Canvas/UI") → 应在 onLoad 缓存

    // [P7] 检查：是否有数组高阶函数？
    // → ❌ this.enemies.filter(e => e.alive) → 应用 for 循环

    // [P8] 检查：是否有字符串操作？
    // → ❌ "enemy_" + i → 应使用数值索引

    // ✅ 理想的 update：
    if (!this.isActive) return;  // 早退

    // 使用预分配变量
    this.tempPos.x = this.node.x + this.direction.x * this.speed * dt;
    this.tempPos.y = this.node.y + this.direction.y * this.speed * dt;
    this.node.setPosition(this.tempPos);

    // 使用缓存引用
    this.cachedSprite.fillRange = this.health / this.maxHealth;
}
```

---

## 安全与健壮性

| # | 检查项 | 标准 | 级别 |
|---|--------|------|------|
| S1 | 空值保护 | 可能为 null 的节点/组件引用有检查 | 🔴 |
| S2 | 数组边界 | 数组访问有长度检查 | 🟡 |
| S3 | 除零保护 | 除法运算检查分母不为零 | 🟡 |
| S4 | 异步安全 | 回调中检查 this.node 是否有效 | 🔴 |
| S5 | 平台兼容 | 使用 cc.sys 检查平台能力 | 🟡 |
| S6 | 存储安全 | localStorage 操作有 try-catch | 🟡 |

### 异步安全模式

```typescript
// ✅ 回调中检查节点有效性
cc.resources.load("prefabs/Item", cc.Prefab, (err, prefab) => {
    // 加载期间节点可能已被销毁
    if (!cc.isValid(this.node)) return;
    if (err) {
        cc.error("加载失败:", err.message);
        return;
    }
    this.itemPrefab = prefab;
    this.itemPrefab.addRef();
});

// ✅ 延迟回调中的安全检查
this.scheduleOnce(() => {
    if (!cc.isValid(this.node)) return;
    this.startGame();
}, 1.0);

// ✅ localStorage 安全读写
private saveData(key: string, data: object): boolean {
    try {
        cc.sys.localStorage.setItem(key, JSON.stringify(data));
        return true;
    } catch (e) {
        cc.error("保存数据失败:", e);
        return false;
    }
}

private loadData<T>(key: string): T | null {
    try {
        const json = cc.sys.localStorage.getItem(key);
        if (!json) return null;
        return JSON.parse(json) as T;
    } catch (e) {
        cc.error("读取数据失败:", e);
        return null;
    }
}
```

---

## 审查总结模板

```markdown
## 代码审查总结

**文件**：XXX.ts
**审查人**：AI Assistant
**日期**：YYYY-MM-DD

### 统计
- 🔴 P0（必须修复）：X 项
- 🟡 P1（应该修复）：X 项
- 🟢 P2（建议优化）：X 项

### 详细结果

#### 🔴 P0
1. [C2] 第 45 行：事件 TOUCH_START 在 onLoad 中注册但无对应 off
   → 移到 onEnable/onDisable 配对

#### 🟡 P1
1. [P2] 第 78 行：update 中调用 getComponent
   → 在 onLoad 中缓存到成员变量

#### 🟢 P2
1. [T4] 第 12 行：`let score = 0` 可改为 `const`
   → 该变量未被重新赋值
```
