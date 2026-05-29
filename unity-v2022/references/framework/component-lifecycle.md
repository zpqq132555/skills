# 组件系统与生命周期详解

## MonoBehaviour 完整生命周期执行顺序

基于 Unity 2022.3 官方文档 (https://docs.unity3d.com/2022.3/Documentation/Manual/ExecutionOrder.html)

### 完整流程图

```
┌─────────────────────────── 初始化阶段 ──────────────────────────┐
│                                                                  │
│  Awake()          ← 对象实例化时（即使组件 disabled 也调用）       │
│       │                                                         │
│  OnEnable()       ← 对象/组件启用时                              │
│       │                                                         │
│  [SceneManager.sceneLoaded 回调]                                 │
│       │                                                         │
│  Start()          ← 第一次 Update 之前（仅当 enabled）            │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────── 物理循环（每固定帧）─────────────────────┐
│                                                                  │
│  FixedUpdate()    ← 固定时间间隔（Time.fixedDeltaTime）          │
│       │                                                         │
│  [Internal Physics Update]                                       │
│       │                                                         │
│  OnTriggerXXX()   ← 触发器回调                                  │
│  OnCollisionXXX() ← 碰撞回调                                    │
│       │                                                         │
│  [yield WaitForFixedUpdate 恢复]                                 │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
                              │
┌────────────────────── 游戏逻辑循环（每帧）─────────────────────┐
│                                                                  │
│  Update()         ← 每帧一次                                    │
│       │                                                         │
│  [yield null / yield WaitForSeconds 恢复]                        │
│       │                                                         │
│  [Internal Animation Update]                                     │
│  OnAnimatorMove()                                                │
│  OnAnimatorIK()                                                  │
│       │                                                         │
│  LateUpdate()     ← 所有 Update 之后                            │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────── 渲染阶段 ───────────────────────────────┐
│                                                                  │
│  OnPreCull()      ← 相机剔除前（仅挂载 Camera 的对象）          │
│  OnBecameVisible() / OnBecameInvisible()                         │
│  OnWillRenderObject()                                            │
│  OnPreRender()                                                   │
│  OnRenderObject()                                                │
│  OnPostRender()                                                  │
│  OnRenderImage()  ← 后处理                                      │
│                                                                  │
│  OnGUI()          ← IMGUI 渲染（每帧可调用多次）                │
│                                                                  │
│  [yield WaitForEndOfFrame 恢复]                                  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
                              │
┌────────────────────── 销毁阶段 ────────────────────────────────┐
│                                                                  │
│  OnDisable()      ← 对象/组件禁用时                              │
│       │                                                         │
│  OnDestroy()      ← 对象销毁时                                  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
                              │
┌────────────────────── 应用退出 ────────────────────────────────┐
│                                                                  │
│  OnApplicationQuit()                                             │
│  OnDisable()                                                     │
│  OnDestroy()                                                     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 关键注意事项

#### Awake vs Start

| 时机 | Awake | Start |
|------|-------|-------|
| 调用次数 | 仅一次 | 仅一次 |
| 组件禁用时 | **仍然调用** | 不调用 |
| 用途 | 初始化自身引用 | 依赖其他对象初始化完成 |
| 保证 | 在同一对象先于 OnEnable | 在所有 Awake 之后 |

#### 跨对象调用顺序

- 同一场景中不同 GameObject 的 `Awake` 调用顺序**不确定**
- 可通过 **Edit > Project Settings > Script Execution Order** 设置优先级
- 所有场景对象的 `Awake`/`OnEnable` 在任何 `Start` 之前完成
- 运行时 `Instantiate` 的对象不保证这个顺序

#### FixedUpdate 频率

```
高帧率(120fps)：FixedUpdate 可能不是每帧都调
低帧率(15fps)：FixedUpdate 每帧可能多次调用
```

#### OnEnable/OnDisable 配对

```csharp
private void OnEnable()
{
    // ✅ 注册事件
    GameManager.OnGameOver += HandleGameOver;
    EventBus.Subscribe<DamageEvent>(OnDamage);
}

private void OnDisable()
{
    // ✅ 注销事件（防止内存泄漏和空引用）
    GameManager.OnGameOver -= HandleGameOver;
    EventBus.Unsubscribe<DamageEvent>(OnDamage);
}
```

---

## Script Execution Order

通过 `[DefaultExecutionOrder]` 特性或 Project Settings 设置。

```csharp
// 数字越小越先执行，默认为 0
[DefaultExecutionOrder(-100)]
public class GameManager : MonoBehaviour { }

[DefaultExecutionOrder(-50)]
public class InputManager : MonoBehaviour { }

[DefaultExecutionOrder(0)]  // 默认
public class PlayerController : MonoBehaviour { }

[DefaultExecutionOrder(100)]
public class UIManager : MonoBehaviour { }
```

---

## 组件操作 API

```csharp
// 添加组件
Rigidbody rb = gameObject.AddComponent<Rigidbody>();

// 获取组件
Renderer renderer = GetComponent<Renderer>();
Collider col = GetComponent<Collider>();

// 获取子物体组件（包括自身）
Renderer[] renderers = GetComponentsInChildren<Renderer>(includeInactive: true);

// 获取父物体组件
Canvas canvas = GetComponentInParent<Canvas>();

// 检查组件是否存在
if (TryGetComponent<Rigidbody>(out var rb))
{
    rb.AddForce(Vector3.up);
}

// 启用/禁用组件
GetComponent<Collider>().enabled = false;
this.enabled = false; // 禁用当前脚本（不再调用 Update 等）

// 通过类型名获取
Component comp = GetComponent("MyScript");
```

---

## Reset 和 OnValidate（仅编辑器）

```csharp
// Reset: 组件首次添加或右键 Reset 时调用
private void Reset()
{
    // 设置合理的默认值
    speed = 5f;
    health = 100;
    // 自动获取组件引用
    if (TryGetComponent<Rigidbody>(out var rb))
    {
        rb.mass = 1f;
        rb.drag = 0.5f;
    }
}

// OnValidate: Inspector 中属性变化时调用
private void OnValidate()
{
    // 值校验
    speed = Mathf.Max(0, speed);
    health = Mathf.Clamp(health, 0, maxHealth);
}
```
