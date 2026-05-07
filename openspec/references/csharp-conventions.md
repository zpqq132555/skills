# C# / Unity 参考规范

> 本文件由 `code-guard-review-cn` 技能按需加载。
> 规则分为三层：
> - Core：通用 C# 规则
> - Unity Runtime：Unity 运行时代码的条件规则
> - Project Profile：项目特定约束，仅在仓库明确采用对应架构时启用

---

## 目录

1. [Core：通用 C# 规则](#1-core通用-c-规则)
2. [Unity Runtime：运行时代码建议](#2-unity-runtime运行时代码建议)
3. [Project Profile：项目特定约束](#3-project-profile项目特定约束)
4. [注释规范落地](#4-注释规范落地)

---

## 1. Core：通用 C# 规则

本节面向大多数 C# 代码，默认可以作为通用建议或条件硬规则使用。

### 1.1 类型安全与动态能力边界

- 避免无说明地使用 `System.Dynamic`。
- 优先使用静态类型约束、泛型和显式建模，而不是运行时绕过类型系统。
- 对应通用规则 R5。

### 1.2 集合与查找

使用 `TryGetValue` 一步完成存在性检查和取值，避免两次哈希查找。

```csharp
// ❌ 差：两次哈希查找
if (dict.ContainsKey(id))
{
    return dict[id];
}

// ✅ 好：一次哈希查找
if (dict.TryGetValue(id, out var value))
{
    return value;
}
```

### 1.3 泛型集合与装箱拆箱

- 非必要不使用装箱拆箱，优先使用泛型集合。
- 避免非泛型集合导致的运行时装箱拆箱和类型风险。

```csharp
// ❌ 禁止非泛型集合
ArrayList numbers = new ArrayList();
numbers.Add(123);            // 装箱
int number = (int)numbers[0]; // 拆箱

// ✅ 使用泛型集合
List<int> numbers = new List<int>();
numbers.Add(123);            // 无装箱
int number = numbers[0];     // 无拆箱
```

### 1.4 接口与封装

- 对外暴露能力时优先通过接口收窄访问面。
- 显式接口实现是可选手段，用于进一步减少公共暴露，而不是所有场景的强制要求。
- 对应通用规则 R14。

```csharp
// ✅ 接口显式实现
public class Student : IAge
{
    int IAge.GetAge()
    {
        return 11;
    }
}
```

---

## 2. Unity Runtime：运行时代码建议

本节仅在 Unity 运行时代码中重点适用。
默认作为“条件硬规则”或“强建议”，不作为无条件禁令。

### 2.1 LINQ 使用边界

- 高频运行时路径默认避免 `System.Linq`，因为可能引入额外分配和可见的帧开销。
- 非热点逻辑、工具脚本或 Editor 代码可结合可读性权衡。

### 2.2 Reflection 使用边界

- 运行时谨慎使用 `System.Reflection`。
- 当涉及性能、AOT/裁剪、混淆、热更兼容或移动端敏感路径时，优先寻找静态替代方案。

### 2.3 热点循环优化

- 在热点循环中关注重复属性访问、临时分配和空判断成本。
- 必要时缓存集合引用和 `Count`，但不要为了机械套模板而牺牲可读性。

```csharp
// ✅ 在热点路径中可考虑缓存引用和计数
var disableList = player.curDisable;
int count = disableList.Count;
for (int i = 0; i < count; ++i)
{
    var item = disableList[i];
    if (item != null && !item.activeSelf)
    {
        item.SetActive(true);
    }
}
```

### 2.4 数据访问与结构选择

- 已有字典结构时优先 `TryGetValue`，不要退化为 `ContainsKey + 索引` 或不必要的线性查找。
- 若某段逻辑频繁依赖线性查找，应审视是否选错了数据结构。

---

## 3. Project Profile：项目特定约束

本节不是通用 Unity 规则。
只有当仓库明确采用对应架构、热更方案或基础设施时才启用。

### 3.1 集中式静态入口约束

- 若项目采用统一管理器入口架构，则限制新增 `static`。
- 指定入口类可以作为例外；该入口由项目自身约定，例如 `MgrUtil`。
- 该规则属于项目约束，不可提升为通用 C# / Unity 规则。

```csharp
// ✅ 在项目约定入口中统一访问
MgrUtil.XXX.DoSomething();
```

### 3.2 Inject 热更兼容约束

若项目采用 Inject 热更方案，则运行时代码需额外关注以下限制：

#### 3.2.1 Delegate / Event 的 `+=` 合并

- 若项目热更框架无法处理合并后的委托，则避免在运行时主逻辑中依赖 `+=` 聚合。
- 可改为使用集合组合，或遵循项目约定的事件系统。

```csharp
// ❌ 仅在对应热更方案受限时避免
Action testAction = null;
testAction += Load;

// ✅ 方案 A：使用集合组合
List<Action> testActionList = new List<Action>();
testActionList.Add(Load);
```

#### 3.2.2 构造函数内的业务逻辑

- 若热更机制无法替换构造函数逻辑，则业务初始化应移动到 `Init`、`Setup` 或生命周期方法中。

```csharp
// ✅ 将可变业务初始化移到 Init 方法
public CustomData(int dataId)
{
    Init(dataId);
}

private void Init(int dataId)
{
    this.dataId = dataId;
    // ... 其他初始化逻辑
}
```

### 3.3 项目专用事件系统约束

- 若项目采用自定义事件系统，则优先遵循该系统约定。
- 这类约束仅对采用该系统的仓库有效，不应写成通用 C# / Unity 规则。

---

## 4. 注释规范落地

### 4.1 C# 文档注释形式

- 公开类型和公开方法优先使用 `///` XML 文档注释承接通用规则 R12。
- 参数与返回值说明应保持中文、准确、可帮助维护者理解真实意图。

```csharp
/// <summary>
/// 控制角色移动与状态切换。
/// </summary>
public class PlayerController
{
    /// <summary>
    /// 处理伤害结算并返回剩余生命值。
    /// </summary>
    /// <param name="damage">本次受到的伤害值。</param>
    /// <returns>结算后的剩余生命值。</returns>
    public int TakeDamage(int damage)
    {
        return 0;
    }
}
```

### 4.2 复杂内部逻辑注释

- 复杂私有/内部方法使用中文行注释说明关键意图、边界与限制。
- 注释优先解释“为什么这样做”，避免机械复述代码动作。
