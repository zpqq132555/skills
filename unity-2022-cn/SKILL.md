---
name: unity-2022-cn
description: 提供 Unity 2022.3 LTS 游戏引擎的全面开发指导，包括 MonoBehaviour 生命周期、GameObject/Component 组件系统、Transform 变换、物理碰撞（Rigidbody/Collider）、输入系统（Input Manager/Input System）、UI 系统（uGUI/UI Toolkit）、资源管理（Resources/Addressables/AssetBundle）、协程、动画系统（Animator/Animation）、ScriptableObject、事件系统（UnityEvent/C# Event/Action）、对象池、场景管理以及性能优化。在用户编写或重构 Unity 2022.x C# 代码、实现游戏功能、处理资源加载与释放、优化性能、审查代码变更、搭建 Unity 项目架构时触发。也适用于用户提到 MonoBehaviour、GameObject、Transform、Rigidbody、Collider、Canvas、SerializeField、Instantiate、Destroy、SceneManager、Addressables 等 Unity API 时使用。
---

# Unity 2022.3 LTS 开发指导技能

## 元信息 (Frontmatter)

- **技能名称**: `unity-2022-cn`
- **适用引擎**: Unity 2022.3 (LTS)
- **语言**: C# (.NET Standard 2.1 / .NET Framework)
- **官方文档**: https://docs.unity3d.com/2022.3/Documentation/Manual/
- **API 参考**: https://docs.unity3d.com/2022.3/Documentation/ScriptReference/

---

## 1. 组件系统 (Component System)

### 1.1 基础脚本模板

```csharp
using UnityEngine;

public class MyComponent : MonoBehaviour
{
    [SerializeField] private Transform targetTransform;
    [SerializeField] private float speed = 10f;

    // 生命周期见 §2
    private void Awake() { }
    private void Start() { }
    private void Update() { }
    private void OnDestroy() { }
}
```

### 1.2 常用特性 (Attributes) 速查

| 特性 | 说明 | 示例 |
|------|------|------|
| `[SerializeField]` | 序列化私有字段到 Inspector | `[SerializeField] private int hp;` |
| `[HideInInspector]` | 隐藏公共字段 | `[HideInInspector] public int score;` |
| `[Header("分组")]` | Inspector 中的分组标题 | `[Header("移动设置")]` |
| `[Tooltip("提示")]` | 鼠标悬停提示 | `[Tooltip("移动速度")]` |
| `[Range(0, 100)]` | 滑动条 | `[Range(0f, 1f)] float ratio;` |
| `[Space(10)]` | Inspector 间距 | `[Space(10)]` |
| `[TextArea(3,5)]` | 多行文本框 | `[TextArea] string desc;` |
| `[RequireComponent]` | 依赖组件 | `[RequireComponent(typeof(Rigidbody))]` |
| `[DisallowMultipleComponent]` | 禁止重复添加 | 类级别 |
| `[AddComponentMenu("路径")]` | 组件菜单路径 | `[AddComponentMenu("Custom/MyComp")]` |
| `[ExecuteInEditMode]` | 编辑器模式执行 | 类级别 |
| `[ExecuteAlways]` | 编辑器+运行时执行 | 类级别（推荐替代） |
| `[CreateAssetMenu]` | 创建 ScriptableObject 菜单 | 见 §9 |
| `[System.Serializable]` | 可序列化类/结构 | 嵌套数据类 |

### 1.3 序列化规则

```csharp
// ✅ 可序列化
[SerializeField] private int myInt;              // 私有 + 特性
public float myFloat;                            // 公有字段
[SerializeField] private List<string> myList;    // 列表
[SerializeField] private MyData myData;          // [Serializable] 类

// ❌ 不可序列化
private int hidden;           // 私有无特性
static int staticVar;         // 静态
const int constVar = 1;       // 常量
Dictionary<int, string> dict; // 字典不被默认序列化

[System.Serializable]
public class MyData
{
    public string name;
    public int value;
}
```

---

## 2. 生命周期回调 (Lifecycle)

执行顺序：`Awake` → `OnEnable` → `Start` → `FixedUpdate` → `Update` → `LateUpdate` → `OnDisable` → `OnDestroy`

```
 ┌────────┐   ┌──────────┐   ┌───────┐   ┌─────────────┐
 │ Awake  │──▶│ OnEnable │──▶│ Start │──▶│ FixedUpdate │──┐
 └────────┘   └──────────┘   └───────┘   └─────────────┘  │
                                              │             │
                                         ┌────────┐        │
                                         │ Update │◄───────┘
                                         └────────┘
                                              │
                                         ┌────────────┐
                                         │ LateUpdate │
                                         └────────────┘
                                              │
                                         ┌───────────┐   ┌─────────────┐
                                         │ OnDisable │──▶│ OnDestroy   │
                                         └───────────┘   └─────────────┘
```

| 回调 | 触发时机 | 典型用途 |
|------|---------|---------|
| `Awake()` | 对象实例化时（仅一次），即使组件未启用也会调用 | 初始化自身引用、缓存组件 |
| `OnEnable()` | 组件启用时 | 注册事件监听、订阅委托 |
| `Start()` | 第一次 `Update` 之前（仅一次），仅在组件启用时 | 依赖其他对象 `Awake` 完成的初始化 |
| `FixedUpdate()` | 固定时间间隔（默认 0.02s） | 物理计算、Rigidbody 操作 |
| `Update()` | 每帧调用 | 游戏逻辑、输入检测、非物理移动 |
| `LateUpdate()` | 所有 `Update` 后 | 跟随相机、后处理 |
| `OnDisable()` | 组件禁用时 | 取消事件监听 |
| `OnDestroy()` | 对象销毁时 | 资源释放、清理 |
| `OnApplicationPause(bool)` | 应用暂停/恢复 | 保存进度 |
| `OnApplicationQuit()` | 应用退出 | 最终清理 |

**关键规则**:
- `Awake` 在对象实例化时调用，即使 `enabled = false`（但 GameObject 必须 active）
- 同一场景中不同对象的 `Awake` 调用顺序不确定，可通过 Script Execution Order 设置
- `FixedUpdate` 可能在一帧中调用多次（帧率低时）或不调用（帧率高时）
- `OnEnable`/`OnDisable` 配对使用：注册/注销事件、委托
- `OnDestroy` 仅在之前调用过 `Awake` 的对象上调用

---

## 3. GameObject 与 Transform

### 3.1 节点访问

```csharp
// 子对象
Transform child = transform.Find("ChildName");
Transform child2 = transform.GetChild(0);
int count = transform.childCount;

// 通过路径查找
GameObject obj = GameObject.Find("Canvas/Panel/Button");

// 通过标签
GameObject player = GameObject.FindWithTag("Player");
GameObject[] enemies = GameObject.FindGameObjectsWithTag("Enemy");

// 组件获取
Rigidbody rb = GetComponent<Rigidbody>();
Collider[] cols = GetComponentsInChildren<Collider>();
AudioSource audio = GetComponentInParent<AudioSource>();

// 泛型查找（全局，慎用）
MyManager mgr = FindObjectOfType<MyManager>();
MyManager[] all = FindObjectsOfType<MyManager>();
// Unity 2022.3+ 推荐
MyManager mgr2 = FindAnyObjectByType<MyManager>();
MyManager[] all2 = FindObjectsByType<MyManager>(FindObjectsSortMode.None);
```

### 3.2 Transform 操作

```csharp
// 位置
transform.position = new Vector3(1, 2, 3);       // 世界坐标
transform.localPosition = Vector3.zero;            // 本地坐标

// 旋转
transform.rotation = Quaternion.Euler(0, 90, 0);  // 世界旋转
transform.localRotation = Quaternion.identity;     // 本地旋转
transform.eulerAngles = new Vector3(0, 90, 0);     // 欧拉角
transform.Rotate(Vector3.up, 90f * Time.deltaTime); // 增量旋转

// 缩放
transform.localScale = Vector3.one;

// 朝向
transform.LookAt(target.transform);
Vector3 forward = transform.forward;  // 前方向
Vector3 right = transform.right;      // 右方向
Vector3 up = transform.up;            // 上方向

// 层级
transform.SetParent(parentTransform);
transform.SetParent(parentTransform, worldPositionStays: false);
transform.SetSiblingIndex(0);          // 设置在父节点中的顺序

// 坐标转换
Vector3 worldPos = transform.TransformPoint(localPos);
Vector3 localPos = transform.InverseTransformPoint(worldPos);
Vector3 worldDir = transform.TransformDirection(localDir);
```

### 3.3 对象实例化与销毁

```csharp
// 实例化
GameObject instance = Instantiate(prefab);
GameObject instance2 = Instantiate(prefab, position, rotation);
GameObject instance3 = Instantiate(prefab, parent);

// 泛型实例化
MyComponent comp = Instantiate(prefabWithComponent);

// 销毁
Destroy(gameObject);            // 当前帧结束后销毁
Destroy(gameObject, 2f);        // 延迟 2 秒销毁
Destroy(GetComponent<Rigidbody>()); // 只销毁组件
DestroyImmediate(obj);          // 立即销毁（仅编辑器脚本使用）

// 跨场景保持
DontDestroyOnLoad(gameObject);

// 激活/禁用
gameObject.SetActive(false);
bool isActive = gameObject.activeSelf;       // 自身激活状态
bool isActiveInHierarchy = gameObject.activeInHierarchy; // 层级中实际激活
```

---

## 4. 事件系统 (Events)

### 4.1 C# 委托与事件

```csharp
// 定义事件
public class GameManager : MonoBehaviour
{
    // 方式一：Action（推荐）
    public static event System.Action OnGameStart;
    public static event System.Action<int> OnScoreChanged;

    // 方式二：自定义委托
    public delegate void GameOverHandler(string reason, int score);
    public static event GameOverHandler OnGameOver;

    public void StartGame()
    {
        OnGameStart?.Invoke();
    }

    public void AddScore(int score)
    {
        OnScoreChanged?.Invoke(score);
    }
}

// 订阅事件
public class UIManager : MonoBehaviour
{
    private void OnEnable()
    {
        GameManager.OnGameStart += HandleGameStart;
        GameManager.OnScoreChanged += HandleScoreChanged;
    }

    private void OnDisable()
    {
        GameManager.OnGameStart -= HandleGameStart;
        GameManager.OnScoreChanged -= HandleScoreChanged;
    }

    private void HandleGameStart() { /* ... */ }
    private void HandleScoreChanged(int score) { /* ... */ }
}
```

### 4.2 UnityEvent（Inspector 拖拽绑定）

```csharp
using UnityEngine;
using UnityEngine.Events;

public class Health : MonoBehaviour
{
    [SerializeField] private UnityEvent onDeath;
    [SerializeField] private UnityEvent<float> onHealthChanged;

    private float hp = 100f;

    public void TakeDamage(float damage)
    {
        hp -= damage;
        onHealthChanged?.Invoke(hp);
        if (hp <= 0f)
        {
            onDeath?.Invoke();
        }
    }
}
```

---

## 5. 输入系统 (Input)

### 5.1 旧版 Input Manager

```csharp
// 键盘
if (Input.GetKeyDown(KeyCode.Space)) { /* 按下瞬间 */ }
if (Input.GetKey(KeyCode.W)) { /* 按住 */ }
if (Input.GetKeyUp(KeyCode.Space)) { /* 抬起瞬间 */ }

// 轴向输入（Edit > Project Settings > Input Manager）
float h = Input.GetAxis("Horizontal");     // 带平滑
float v = Input.GetAxisRaw("Vertical");    // 无平滑 -1/0/1

// 鼠标
if (Input.GetMouseButtonDown(0)) { /* 左键 */ }
Vector3 mousePos = Input.mousePosition;    // 屏幕坐标

// 触摸
if (Input.touchCount > 0)
{
    Touch touch = Input.GetTouch(0);
    if (touch.phase == TouchPhase.Began) { /* ... */ }
}
```

### 5.2 新版 Input System（需安装包）

```csharp
using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerInput : MonoBehaviour
{
    [SerializeField] private InputActionAsset inputActions;
    private InputAction moveAction;
    private InputAction fireAction;

    private void Awake()
    {
        var actionMap = inputActions.FindActionMap("Player");
        moveAction = actionMap.FindAction("Move");
        fireAction = actionMap.FindAction("Fire");
    }

    private void OnEnable()
    {
        moveAction.Enable();
        fireAction.Enable();
        fireAction.performed += OnFire;
    }

    private void OnDisable()
    {
        fireAction.performed -= OnFire;
        moveAction.Disable();
        fireAction.Disable();
    }

    private void Update()
    {
        Vector2 moveInput = moveAction.ReadValue<Vector2>();
        transform.Translate(new Vector3(moveInput.x, 0, moveInput.y) * Time.deltaTime);
    }

    private void OnFire(InputAction.CallbackContext ctx)
    {
        Debug.Log("Fire!");
    }
}
```

---

## 6. 物理系统 (Physics)

### 6.1 3D 物理

```csharp
using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class PhysicsExample : MonoBehaviour
{
    private Rigidbody rb;

    private void Awake()
    {
        rb = GetComponent<Rigidbody>();
    }

    private void FixedUpdate()
    {
        // 施加力
        rb.AddForce(Vector3.forward * 10f);
        rb.AddForce(Vector3.up * 5f, ForceMode.Impulse);

        // 速度
        rb.velocity = new Vector3(0, rb.velocity.y, 5f);

        // 移动（保持物理碰撞）
        rb.MovePosition(rb.position + Vector3.forward * Time.fixedDeltaTime);
        rb.MoveRotation(Quaternion.Euler(0, 90, 0));
    }

    // 碰撞回调（需双方都有 Collider，至少一方有 Rigidbody）
    private void OnCollisionEnter(Collision collision)
    {
        Debug.Log($"碰撞: {collision.gameObject.name}");
        ContactPoint contact = collision.contacts[0];
        Debug.Log($"碰撞点: {contact.point}, 法线: {contact.normal}");
    }

    private void OnCollisionStay(Collision collision) { }
    private void OnCollisionExit(Collision collision) { }

    // 触发器回调（Collider 设置为 isTrigger = true）
    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Pickup"))
        {
            Destroy(other.gameObject);
        }
    }

    private void OnTriggerStay(Collider other) { }
    private void OnTriggerExit(Collider other) { }
}
```

### 6.2 射线检测 (Raycasting)

```csharp
// 单条射线
if (Physics.Raycast(transform.position, transform.forward, out RaycastHit hit, 100f))
{
    Debug.Log($"击中: {hit.collider.name}, 距离: {hit.distance}");
}

// 带 LayerMask
int layerMask = LayerMask.GetMask("Enemy", "Obstacle");
if (Physics.Raycast(origin, direction, out hit, maxDistance, layerMask))
{ /* ... */ }

// 从屏幕发射射线
Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
if (Physics.Raycast(ray, out hit))
{ /* ... */ }

// 球形检测
Collider[] colliders = Physics.OverlapSphere(transform.position, 5f);

// 多结果射线
RaycastHit[] hits = Physics.RaycastAll(origin, direction, maxDistance);

// 非分配版本（推荐，避免 GC）
private RaycastHit[] hitBuffer = new RaycastHit[10];
int count = Physics.RaycastNonAlloc(origin, direction, hitBuffer, maxDistance);
```

### 6.3 2D 物理

```csharp
// 2D 物理使用后缀 2D 的对应类
// Rigidbody2D, Collider2D, BoxCollider2D, CircleCollider2D
// OnCollisionEnter2D(Collision2D), OnTriggerEnter2D(Collider2D)
// Physics2D.Raycast(), Physics2D.OverlapCircle()

private void OnCollisionEnter2D(Collision2D collision)
{
    Debug.Log($"2D 碰撞: {collision.gameObject.name}");
}

private void OnTriggerEnter2D(Collider2D other)
{
    if (other.CompareTag("Coin"))
    {
        Destroy(other.gameObject);
    }
}
```

---

## 7. 资源管理

### 7.1 Resources（简单但不推荐大量使用）

```csharp
// 加载（Assets/Resources/ 文件夹下的资源）
GameObject prefab = Resources.Load<GameObject>("Prefabs/Enemy");
Texture2D tex = Resources.Load<Texture2D>("Textures/Icon");

// 异步加载
ResourceRequest request = Resources.LoadAsync<GameObject>("Prefabs/Enemy");
yield return request;
GameObject loaded = request.asset as GameObject;

// 释放
Resources.UnloadAsset(asset);
Resources.UnloadUnusedAssets();
```

**⚠️ 注意**: Resources 文件夹中的所有资源都会被打包，无论是否使用。大型项目推荐使用 Addressables。

### 7.2 AssetBundle

```csharp
// 加载 Bundle
AssetBundle bundle = AssetBundle.LoadFromFile(path);
// 或异步
AssetBundleCreateRequest req = AssetBundle.LoadFromFileAsync(path);
yield return req;
AssetBundle bundle2 = req.assetBundle;

// 从 Bundle 加载资源
GameObject prefab = bundle.LoadAsset<GameObject>("EnemyPrefab");

// 异步加载资源
AssetBundleRequest assetReq = bundle.LoadAssetAsync<GameObject>("EnemyPrefab");
yield return assetReq;
GameObject loaded = assetReq.asset as GameObject;

// 卸载
bundle.Unload(false); // false: 不卸载已加载的资源
bundle.Unload(true);  // true: 卸载所有资源（谨慎使用）
```

### 7.3 Addressables（推荐方案）

```csharp
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;

public class AddressableExample : MonoBehaviour
{
    [SerializeField] private AssetReference prefabRef;

    private AsyncOperationHandle<GameObject> handle;

    private async void LoadAsset()
    {
        // 通过地址加载
        handle = Addressables.LoadAssetAsync<GameObject>("Assets/Prefabs/Enemy.prefab");
        await handle.Task;

        if (handle.Status == AsyncOperationStatus.Succeeded)
        {
            Instantiate(handle.Result);
        }

        // 通过 AssetReference 加载
        var refHandle = prefabRef.LoadAssetAsync<GameObject>();
        await refHandle.Task;
    }

    // 实例化 + 自动管理
    private async void InstantiateAsset()
    {
        var op = Addressables.InstantiateAsync("Assets/Prefabs/Enemy.prefab");
        GameObject instance = await op.Task;
    }

    private void OnDestroy()
    {
        // 释放
        Addressables.Release(handle);
    }
}
```

---

## 8. 协程 (Coroutines)

```csharp
using System.Collections;
using UnityEngine;

public class CoroutineExample : MonoBehaviour
{
    private Coroutine myCoroutine;

    private void Start()
    {
        // 启动协程
        myCoroutine = StartCoroutine(MyRoutine());
        StartCoroutine(FadeOut(2f));
    }

    private IEnumerator MyRoutine()
    {
        Debug.Log("开始");

        yield return null;                                    // 等待下一帧
        yield return new WaitForSeconds(1f);                  // 等待 1 秒
        yield return new WaitForSecondsRealtime(1f);          // 不受 timeScale 影响
        yield return new WaitForFixedUpdate();                // 等待 FixedUpdate
        yield return new WaitForEndOfFrame();                 // 等待帧结束
        yield return new WaitUntil(() => hp > 0);             // 等待条件为 true
        yield return new WaitWhile(() => isLoading);          // 等待条件为 false
        yield return StartCoroutine(AnotherRoutine());        // 等待另一协程

        Debug.Log("结束");
    }

    private IEnumerator FadeOut(float duration)
    {
        float elapsed = 0f;
        while (elapsed < duration)
        {
            float t = elapsed / duration;
            // 插值操作...
            elapsed += Time.deltaTime;
            yield return null;
        }
    }

    private void StopMyCoroutine()
    {
        if (myCoroutine != null)
        {
            StopCoroutine(myCoroutine);
            myCoroutine = null;
        }
        StopAllCoroutines(); // 停止当前 MonoBehaviour 的所有协程
    }
}
```

**关键规则**:
- 协程在 `MonoBehaviour` 所在的 `GameObject` 被禁用或销毁时自动停止
- 仅禁用组件（`enabled = false`）不会停止协程
- 不要在 `FixedUpdate` 中启动协程
- 推荐缓存 `WaitForSeconds` 等 YieldInstruction 避免 GC

```csharp
// ✅ 缓存 yield
private readonly WaitForSeconds wait1s = new WaitForSeconds(1f);
private IEnumerator MyRoutine()
{
    yield return wait1s; // 复用，不产生 GC
}
```

---

## 9. ScriptableObject

```csharp
using UnityEngine;

[CreateAssetMenu(fileName = "NewWeaponData", menuName = "Game/Weapon Data")]
public class WeaponData : ScriptableObject
{
    public string weaponName;
    public int damage;
    public float attackSpeed;
    public Sprite icon;
    public AudioClip attackSound;
}

// 使用
public class Weapon : MonoBehaviour
{
    [SerializeField] private WeaponData data;

    private void Attack()
    {
        Debug.Log($"攻击：{data.weaponName}，伤害：{data.damage}");
    }
}
```

---

## 10. UI 系统

### 10.1 Unity UI (uGUI) — 运行时 UI 推荐

```csharp
using UnityEngine;
using UnityEngine.UI;
using TMPro;  // TextMeshPro

public class UIExample : MonoBehaviour
{
    [SerializeField] private Button startButton;
    [SerializeField] private TMP_Text scoreText;
    [SerializeField] private Slider hpSlider;
    [SerializeField] private Image hpFill;
    [SerializeField] private Toggle soundToggle;
    [SerializeField] private TMP_InputField nameInput;
    [SerializeField] private CanvasGroup panelGroup;

    private void OnEnable()
    {
        startButton.onClick.AddListener(OnStartClicked);
        soundToggle.onValueChanged.AddListener(OnSoundToggled);
        nameInput.onEndEdit.AddListener(OnNameSubmit);
    }

    private void OnDisable()
    {
        startButton.onClick.RemoveListener(OnStartClicked);
        soundToggle.onValueChanged.RemoveListener(OnSoundToggled);
        nameInput.onEndEdit.RemoveListener(OnNameSubmit);
    }

    private void OnStartClicked()
    {
        Debug.Log("开始游戏");
    }

    private void OnSoundToggled(bool isOn)
    {
        AudioListener.volume = isOn ? 1f : 0f;
    }

    private void OnNameSubmit(string playerName)
    {
        Debug.Log($"玩家名: {playerName}");
    }

    // 更新 UI
    public void UpdateScore(int score)
    {
        scoreText.text = $"分数: {score}";
    }

    public void UpdateHP(float ratio)
    {
        hpSlider.value = ratio;
        hpFill.color = Color.Lerp(Color.red, Color.green, ratio);
    }

    // CanvasGroup 控制面板显隐
    public void ShowPanel(bool show)
    {
        panelGroup.alpha = show ? 1f : 0f;
        panelGroup.interactable = show;
        panelGroup.blocksRaycasts = show;
    }
}
```

### 10.2 Canvas 设置要点

| 渲染模式 | 说明 | 适用场景 |
|---------|------|---------|
| Screen Space - Overlay | 始终覆盖在屏幕最上层 | HUD、菜单 |
| Screen Space - Camera | 渲染到指定相机 | 需要 3D 效果的 UI |
| World Space | UI 存在于世界空间 | 场景内血条、名称牌 |

---

## 11. 场景管理

```csharp
using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneController : MonoBehaviour
{
    // 加载场景（替换当前场景）
    public void LoadScene(string sceneName)
    {
        SceneManager.LoadScene(sceneName);
    }

    // 异步加载
    public IEnumerator LoadSceneAsync(string sceneName)
    {
        AsyncOperation op = SceneManager.LoadSceneAsync(sceneName);
        op.allowSceneActivation = false;

        while (op.progress < 0.9f)
        {
            float progress = Mathf.Clamp01(op.progress / 0.9f);
            Debug.Log($"加载进度: {progress * 100}%");
            yield return null;
        }

        // 准备好后激活
        op.allowSceneActivation = true;
    }

    // 叠加加载
    public void LoadSceneAdditive(string sceneName)
    {
        SceneManager.LoadScene(sceneName, LoadSceneMode.Additive);
    }

    // 卸载叠加场景
    public void UnloadScene(string sceneName)
    {
        SceneManager.UnloadSceneAsync(sceneName);
    }

    // 场景事件
    private void OnEnable()
    {
        SceneManager.sceneLoaded += OnSceneLoaded;
        SceneManager.sceneUnloaded += OnSceneUnloaded;
    }

    private void OnDisable()
    {
        SceneManager.sceneLoaded -= OnSceneLoaded;
        SceneManager.sceneUnloaded -= OnSceneUnloaded;
    }

    private void OnSceneLoaded(Scene scene, LoadSceneMode mode)
    {
        Debug.Log($"场景加载: {scene.name}");
    }

    private void OnSceneUnloaded(Scene scene)
    {
        Debug.Log($"场景卸载: {scene.name}");
    }
}
```

---

## 12. 动画系统

### 12.1 Animator 控制

```csharp
using UnityEngine;

public class AnimatorExample : MonoBehaviour
{
    private Animator animator;
    private static readonly int SpeedHash = Animator.StringToHash("Speed");
    private static readonly int JumpHash = Animator.StringToHash("Jump");
    private static readonly int IsGroundedHash = Animator.StringToHash("IsGrounded");
    private static readonly int AttackHash = Animator.StringToHash("Attack");

    private void Awake()
    {
        animator = GetComponent<Animator>();
    }

    private void Update()
    {
        // 设置参数
        animator.SetFloat(SpeedHash, moveSpeed);
        animator.SetBool(IsGroundedHash, isGrounded);
        animator.SetInteger("State", currentState);

        // 触发
        if (Input.GetKeyDown(KeyCode.Space))
        {
            animator.SetTrigger(JumpHash);
        }

        // 播放指定状态
        animator.Play("Idle", 0, 0f); // (状态名, 层级, 归一化时间)
        animator.CrossFade("Run", 0.2f); // 带过渡

        // 获取状态信息
        AnimatorStateInfo info = animator.GetCurrentAnimatorStateInfo(0);
        if (info.IsName("Attack") && info.normalizedTime >= 1f)
        {
            // 攻击动画播放完毕
        }
    }
}
```

### 12.2 DOTween 缓动（常用第三方插件）

```csharp
using DG.Tweening;

// 位移
transform.DOMove(new Vector3(5, 0, 0), 1f).SetEase(Ease.OutBounce);
transform.DOLocalMove(Vector3.zero, 0.5f);

// 旋转
transform.DORotate(new Vector3(0, 360, 0), 1f, RotateMode.FastBeyond360);

// 缩放
transform.DOScale(Vector3.one * 1.5f, 0.3f).SetLoops(-1, LoopType.Yoyo);

// UI
canvasGroup.DOFade(0f, 0.5f);
rectTransform.DOAnchorPos(Vector2.zero, 0.3f);

// 序列
Sequence seq = DOTween.Sequence();
seq.Append(transform.DOMove(new Vector3(5, 0, 0), 1f));
seq.Join(transform.DOScale(2f, 1f));  // 同时
seq.AppendInterval(0.5f);              // 等待
seq.Append(transform.DOMove(Vector3.zero, 1f));
seq.OnComplete(() => Debug.Log("完成"));

// 停止
transform.DOKill();
DOTween.KillAll();
```

---

## 13. 对象池 (Object Pool)

### 13.1 Unity 内置对象池（2021+）

```csharp
using UnityEngine;
using UnityEngine.Pool;

public class BulletPool : MonoBehaviour
{
    [SerializeField] private GameObject bulletPrefab;

    private ObjectPool<GameObject> pool;

    private void Awake()
    {
        pool = new ObjectPool<GameObject>(
            createFunc: () => Instantiate(bulletPrefab),
            actionOnGet: (obj) => obj.SetActive(true),
            actionOnRelease: (obj) => obj.SetActive(false),
            actionOnDestroy: (obj) => Destroy(obj),
            collectionCheck: false,
            defaultCapacity: 20,
            maxSize: 100
        );
    }

    public GameObject GetBullet()
    {
        return pool.Get();
    }

    public void ReturnBullet(GameObject bullet)
    {
        pool.Release(bullet);
    }
}
```

### 13.2 手动实现

```csharp
using System.Collections.Generic;
using UnityEngine;

public class SimplePool : MonoBehaviour
{
    [SerializeField] private GameObject prefab;
    [SerializeField] private int initialSize = 10;

    private readonly Queue<GameObject> available = new Queue<GameObject>();

    private void Awake()
    {
        for (int i = 0; i < initialSize; i++)
        {
            GameObject obj = Instantiate(prefab, transform);
            obj.SetActive(false);
            available.Enqueue(obj);
        }
    }

    public GameObject Get()
    {
        GameObject obj = available.Count > 0
            ? available.Dequeue()
            : Instantiate(prefab, transform);
        obj.SetActive(true);
        return obj;
    }

    public void Return(GameObject obj)
    {
        obj.SetActive(false);
        available.Enqueue(obj);
    }
}
```

---

## 14. 常用工具方法

### 14.1 数学与插值

```csharp
// 线性插值
float result = Mathf.Lerp(a, b, t);
Vector3 pos = Vector3.Lerp(start, end, t);
Color col = Color.Lerp(Color.red, Color.green, t);
Quaternion rot = Quaternion.Slerp(from, to, t); // 球面插值

// 平滑阻尼
float velocity = 0f;
float smoothed = Mathf.SmoothDamp(current, target, ref velocity, smoothTime);
Vector3 smoothedV = Vector3.SmoothDamp(currentPos, targetPos, ref vel, smoothTime);

// 钳制
float clamped = Mathf.Clamp(value, 0f, 1f);
int clampedInt = Mathf.Clamp(value, 0, 100);

// 角度相关
float angle = Vector3.Angle(v1, v2);
float signedAngle = Vector3.SignedAngle(v1, v2, Vector3.up);
```

### 14.2 时间

```csharp
float dt = Time.deltaTime;          // 帧间隔（受 timeScale 影响）
float fixedDt = Time.fixedDeltaTime; // 固定间隔
float realDt = Time.unscaledDeltaTime; // 不受 timeScale 影响
float elapsed = Time.time;          // 游戏启动后时间
float realTime = Time.realtimeSinceStartup;
int frameCount = Time.frameCount;

// 慢动作
Time.timeScale = 0.5f;  // 半速
Time.timeScale = 0f;    // 暂停（Update 仍调用，物理停止）
Time.timeScale = 1f;    // 恢复
```

### 14.3 数据持久化

```csharp
// PlayerPrefs（轻量数据）
PlayerPrefs.SetInt("HighScore", 100);
PlayerPrefs.SetFloat("Volume", 0.8f);
PlayerPrefs.SetString("PlayerName", "Hero");
int score = PlayerPrefs.GetInt("HighScore", 0);
PlayerPrefs.Save();
PlayerPrefs.DeleteAll();
PlayerPrefs.DeleteKey("HighScore");

// JSON 序列化
string json = JsonUtility.ToJson(myData);
MyData loaded = JsonUtility.FromJson<MyData>(json);

// 文件读写
string path = Application.persistentDataPath + "/save.json";
System.IO.File.WriteAllText(path, json);
string content = System.IO.File.ReadAllText(path);
```

### 14.4 常用路径

```csharp
Application.dataPath;              // Assets 目录（编辑器）
Application.persistentDataPath;    // 持久化数据目录（运行时可写）
Application.streamingAssetsPath;   // StreamingAssets 目录（只读）
Application.temporaryCachePath;    // 临时缓存目录
```

---

## 15. 平台判断与条件编译

```csharp
// 运行时平台判断
if (Application.platform == RuntimePlatform.Android) { /* ... */ }
if (Application.platform == RuntimePlatform.IPhonePlayer) { /* ... */ }
if (Application.isMobilePlatform) { /* ... */ }

// 条件编译
#if UNITY_EDITOR
    Debug.Log("仅编辑器");
#elif UNITY_ANDROID
    Debug.Log("Android");
#elif UNITY_IOS
    Debug.Log("iOS");
#elif UNITY_WEBGL
    Debug.Log("WebGL");
#elif UNITY_STANDALONE_WIN
    Debug.Log("Windows");
#endif

#if UNITY_EDITOR
using UnityEditor;
#endif

#if DEVELOPMENT_BUILD || UNITY_EDITOR
    Debug.Log("开发模式");
#endif
```

---

## 16. async/await（Unity 2022.3 支持）

```csharp
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;

public class AsyncExample : MonoBehaviour
{
    private CancellationTokenSource cts;

    private async void Start()
    {
        cts = new CancellationTokenSource();

        try
        {
            await LoadDataAsync(cts.Token);
        }
        catch (TaskCanceledException)
        {
            Debug.Log("任务已取消");
        }
    }

    private async Task LoadDataAsync(CancellationToken token)
    {
        // 异步等待（在主线程恢复）
        await Task.Delay(1000, token);

        // 切换回主线程（如果从其他线程回来）
        // 使用 UniTask 或 Awaitable (Unity 2023+) 更佳
    }

    private void OnDestroy()
    {
        cts?.Cancel();
        cts?.Dispose();
    }
}
```

---

## 17. 编辑器扩展 (Editor Scripts)

```csharp
#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

// 自定义 Inspector
[CustomEditor(typeof(MyComponent))]
public class MyComponentEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        MyComponent comp = (MyComponent)target;
        if (GUILayout.Button("执行操作"))
        {
            comp.DoSomething();
        }
    }
}

// 自定义菜单
public class MyEditorTools
{
    [MenuItem("Tools/My Tool %#t")] // Ctrl+Shift+T
    private static void MyTool()
    {
        Debug.Log("执行工具");
    }

    [MenuItem("Tools/My Tool", true)]
    private static bool MyToolValidation()
    {
        return Selection.activeGameObject != null;
    }
}

// Gizmos
public class GizmoExample : MonoBehaviour
{
    [SerializeField] private float radius = 5f;

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.yellow;
        Gizmos.DrawWireSphere(transform.position, radius);
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawSphere(transform.position, 0.5f);
    }
}
#endif
```

---

## 18. 性能优化要点

### 18.1 代码优化

| 问题 | 优化方案 |
|------|---------|
| `GetComponent<T>()` 每帧调用 | 在 `Awake`/`Start` 中缓存引用 |
| `GameObject.Find()` 每帧调用 | 用 `[SerializeField]` 引用或缓存 |
| `string` 拼接频繁 | 使用 `StringBuilder` 或 `$""` |
| 频繁创建/销毁对象 | 使用对象池 |
| `Camera.main` 每帧访问 | 缓存到变量（Unity 2022 已优化） |
| LINQ 在 Update 中使用 | 避免，手写循环 |
| `foreach` 在 List 上 | 使用 `for` 循环避免装箱（旧版 Unity） |
| `SendMessage()` | 使用直接引用或事件系统 |
| `CompareTag("Tag")` vs `tag == "Tag"` | 使用 `CompareTag`（无 GC） |

### 18.2 渲染优化

- **批处理**：静态合批（Static Batching）、动态合批、GPU Instancing、SRP Batcher
- **LOD**：Level of Detail，远处使用低模
- **遮挡剔除**：Occlusion Culling
- **图集**：Sprite Atlas 合并贴图减少 Draw Call
- **烘焙光照**：减少实时光照计算

### 18.3 内存优化

- 及时释放不用的资源：`Resources.UnloadUnusedAssets()`
- 使用 Addressables 精细管理资源生命周期
- 避免资源重复加载
- 压缩纹理，合理设置 Max Size
- 使用 Profiler 和 Memory Profiler 分析内存

---

## 参考文件索引

### 框架参考 (references/framework/)
| 文件 | 说明 |
|------|------|
| [component-lifecycle.md](references/framework/component-lifecycle.md) | 组件系统、生命周期、执行顺序详解 |
| [physics-collision.md](references/framework/physics-collision.md) | 物理引擎、碰撞检测、射线检测 |
| [ui-system.md](references/framework/ui-system.md) | UI 系统、uGUI/UI Toolkit 选型与使用 |
| [asset-management.md](references/framework/asset-management.md) | 资源管理、Addressables/AssetBundle/Resources |

### 语言参考 (references/language/)
| 文件 | 说明 |
|------|------|
| [csharp-patterns.md](references/language/csharp-patterns.md) | C# 设计模式、单例、工厂、观察者 |
| [performance.md](references/language/performance.md) | 性能优化、内存管理、GC 减少策略 |

### 审查参考 (references/review/)
| 文件 | 说明 |
|------|------|
| [code-review.md](references/review/code-review.md) | 代码审查清单、常见问题 |
