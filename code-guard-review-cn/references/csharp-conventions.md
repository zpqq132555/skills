# C# / Unity 编码规范参考

> 本文件由 `code-guard-review-cn` 技能按需加载。
> 当项目为 C# / Unity 时读取此文件，获取语言专项约束和性能优化建议。

---

## 目录

1. [禁用命名空间](#1-禁用命名空间运行时)
2. [静态修饰符限制](#2-静态修饰符限制)
3. [热更新兼容约束](#3-热更新兼容约束)
4. [接口与显式实现](#4-接口与显式实现)
5. [字典取值优化](#5-字典取值优化)
6. [列表循环优化](#6-列表循环优化)
7. [装箱拆箱优化](#7-装箱拆箱优化)
8. [注释格式](#8-注释格式)

---

## 1. 禁用命名空间（运行时）

运行时脚本中禁止使用以下命名空间，Editor 环境下可用。

| 命名空间 | 用途 | 禁用原因 |
|---------|------|---------|
| `System.Linq` | LINQ 查询 | 产生大量 GC，导致卡顿 |
| `System.Reflection` | 反射操作 | 性能差，且代码混淆加密后无法正常工作 |
| `System.Dynamic` | 动态类型 | 绕过静态类型检查（对应通用规则 R5） |

---

## 2. 静态修饰符限制

整个游戏中，只有 `MgrUtil` 作为管理器入口可使用 `static` 修饰符。
其他游戏内代码禁止出现静态类、静态属性、静态函数。扩展方法改用配套辅助类调用。

```csharp
// ❌ 禁止
public class TestAB : MonoBehaviour
{
    public static TestAB Instance;
    public static int TotalNumber;
}

// ✅ 通过 MgrUtil 统一入口访问
MgrUtil.XXX.DoSomething();
```

---

## 3. 热更新兼容约束

受 Inject 热更方案限制，以下模式在运行时需要避免：

### 3.1 禁止 Delegate/Event 的 `+=` 合并

Inject 热更无法处理 `+=` 合并后的委托，且大量合并时性能差。

```csharp
// ❌ 禁止
Action testAction = null;
testAction += Load;

// ✅ 方案 A：使用集合组合
List<Action> testActionList = new List<Action>();
testActionList.Add(Load);

// ✅ 方案 B：使用引擎事件系统
private LTCommonRuntime.EventFast.IFastEvent<int> testEvent;
testEvent = new LTCommonRuntime.EventFast.TFastEvent();
testEvent.On(EventFastHandler);
testEvent.Send(1);
testEvent.Off(EventFastHandler);
testEvent.Clear();
```

### 3.2 构造函数内禁止业务逻辑

Inject 热更无法替换构造函数内的逻辑，后续调整困难。

```csharp
// ❌ 禁止在构造函数内写业务逻辑
public CustomData(int dataId)
{
    this.dataId = dataId;
    // ... 其他初始化逻辑
}

// ✅ 将逻辑移到 Init 方法
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

---

## 4. 接口与显式实现

管理类通过接口对外开放访问权限（对应通用规则 R14）。
实现接口时推荐显式实现，收窄暴露范围。

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

## 5. 字典取值优化

使用 `TryGetValue` 一步完成存在性检查和取值，避免两次哈希查找。

```csharp
// ❌ 差：两次哈希查找
if (MgrUtil.Archive.GameCurrency.ContainsKey(id))
{
    return MgrUtil.Archive.GameCurrency[id].Name;
}

// ❌ 极差：LINQ 线性遍历
MgrUtil.Archive.GameCurrency.Find(v => v.Id == id).Name;

// ✅ 好：一次哈希查找
if (MgrUtil.Archive.GameCurrency.TryGetValue(id, out var currencyItem))
{
    return currencyItem.Name;
}
```

---

## 6. 列表循环优化

循环前缓存列表引用和 `Count`，避免每次迭代重复访问属性和安全性检查。

```csharp
// ❌ 差：每次循环都重新读取属性
for (int i = 0; i < player.curDisable.Count; ++i)
{
    if (player.curDisable[i] != null && !player.curDisable[i].activeSelf)
    {
        player.curDisable[i].SetActive(true);
    }
}

// ✅ 好：缓存引用和计数
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

---

## 7. 装箱拆箱优化

非必要不使用装箱拆箱，优先使用泛型集合。

```csharp
// ❌ 禁止非泛型集合
ArrayList numbers = new ArrayList();
numbers.Add(123);           // 装箱
int number = (int)numbers[0]; // 拆箱

// ✅ 使用泛型集合
List<int> numbers = new List<int>();
numbers.Add(123);           // 无装箱
int number = numbers[0];    // 无拆箱
```

---

## 8. 注释格式

C# 使用 `///` XML 文档注释，对应通用规则 R12。

```csharp
/// <summary>
/// 类/接口的文档注释
/// </summary>
public class PlayerController { }

/// <summary>
/// 非私有函数的文档注释
/// </summary>
/// <param name="damage">伤害值</param>
/// <returns>剩余生命值</returns>
public int TakeDamage(int damage) { }

// 复杂内部逻辑使用行注释
```
