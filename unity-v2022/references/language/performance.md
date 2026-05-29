# 性能优化指南

## GC 分配优化

### 避免 GC 的常见做法

```csharp
// ❌ 每帧产生 GC
void Update()
{
    string label = "Score: " + score; // 字符串拼接
    var enemies = FindObjectsOfType<Enemy>();  // 分配数组
    var components = GetComponents<Collider>(); // 分配数组
    foreach (var item in myDict) { }  // 字典枚举器装箱（旧版 Unity）
    var result = myList.Where(x => x > 0).ToList(); // LINQ 分配
}

// ✅ 优化后
private readonly StringBuilder sb = new StringBuilder(64);
private readonly List<Collider> colliderCache = new List<Collider>();
private Enemy[] enemyCache;

void Start()
{
    enemyCache = FindObjectsByType<Enemy>(FindObjectsSortMode.None);
}

void Update()
{
    // 复用 StringBuilder
    sb.Clear();
    sb.Append("Score: ");
    sb.Append(score);
    label.text = sb.ToString();

    // 使用 NonAlloc / 复用列表
    GetComponentsInChildren(colliderCache); // List 版本不分配

    // 手写循环代替 LINQ
    for (int i = 0; i < myList.Count; i++)
    {
        if (myList[i] > 0) { /* ... */ }
    }
}
```

### 缓存常用值

```csharp
// ❌ 重复获取
void Update()
{
    Camera.main.transform.position; // Camera.main 内部调用 FindObjectOfType（旧版）
    GetComponent<Rigidbody>().AddForce(Vector3.up);
    transform.position; // 每次访问 transform 都有原生调用开销
}

// ✅ 缓存
private Camera mainCam;
private Rigidbody rb;
private Transform cachedTransform;

void Awake()
{
    mainCam = Camera.main;
    rb = GetComponent<Rigidbody>();
    cachedTransform = transform;
}
```

### 对象池替代频繁 Instantiate/Destroy

```csharp
// ❌ 每次创建销毁
void Fire()
{
    var bullet = Instantiate(bulletPrefab);
    Destroy(bullet, 3f);
}

// ✅ 使用对象池
// 参见 SKILL.md §13 对象池
```

---

## 渲染性能

### Draw Call 优化

| 技术 | 说明 | 适用 |
|------|------|------|
| Static Batching | 静态物体合批 | 不移动的场景物体 |
| Dynamic Batching | 动态物体合批（顶点数限制） | 小型动态物体 |
| GPU Instancing | 相同 Mesh+Material 实例化渲染 | 大量相同物体（草、树） |
| SRP Batcher | URP/HDRP 的材质变体优化 | 使用 SRP 时 |
| Sprite Atlas | 2D 精灵图集合批 | 2D UI 和精灵 |

### LOD (Level of Detail)

```csharp
// LOD Group 组件自动管理
// 也可以代码控制
LODGroup lodGroup = GetComponent<LODGroup>();
LOD[] lods = new LOD[3];
lods[0] = new LOD(0.6f, new Renderer[] { highDetailRenderer });
lods[1] = new LOD(0.3f, new Renderer[] { medDetailRenderer });
lods[2] = new LOD(0.1f, new Renderer[] { lowDetailRenderer });
lodGroup.SetLODs(lods);
lodGroup.RecalculateBounds();
```

### 减少 Overdraw

- 不透明物体从前到后排序（Unity 自动）
- 半透明物体尽量减少
- 使用 Occlusion Culling
- 减少全屏后处理效果

---

## 物理性能

```csharp
// 1. 减少物理对象数量
// 2. 使用简单的碰撞体（Box > Sphere > Capsule > Mesh）
// 3. 合理设置碰撞层矩阵（Physics > Layer Collision Matrix）
// 4. 减少 FixedUpdate 频率（如果不需要高精度）
//    Edit > Project Settings > Time > Fixed Timestep

// 5. 使用 NonAlloc 版本
private RaycastHit[] hitBuffer = new RaycastHit[16];
private Collider[] overlapBuffer = new Collider[32];

void DoPhysicsQuery()
{
    int hitCount = Physics.RaycastNonAlloc(origin, dir, hitBuffer, maxDist, layerMask);
    int overlapCount = Physics.OverlapSphereNonAlloc(pos, radius, overlapBuffer, layerMask);
}

// 6. 禁用不需要物理的对象的碰撞
// 7. Rigidbody.Sleep() 让静止物体进入睡眠
```

---

## 内存优化

### 纹理优化

| 设置 | 建议 |
|------|------|
| Max Size | 按实际需求设置，移动端通常 1024 或 512 |
| Compression | Android: ASTC / ETC2，iOS: ASTC / PVRTC |
| Mip Maps | 3D 场景需要，UI 纹理关闭 |
| Read/Write | 除非需要运行时读写，否则关闭 |
| Sprite Atlas | UI 图片打包图集 |

### 网格优化

- 关闭不需要的 Read/Write Enabled
- 合理设置 Mesh Compression
- 使用 LOD 减少远处顶点数
- 合并小物体的 Mesh

### 音频优化

| 类型 | 加载方式 | 压缩 |
|------|---------|------|
| 短音效(< 200KB) | Decompress On Load | Vorbis |
| 中等音效 | Compressed In Memory | Vorbis |
| 长音乐 | Streaming | Vorbis / MP3 |

---

## Profiler 使用

```csharp
// 代码中标记 Profiler 区间
using UnityEngine.Profiling;

void Update()
{
    Profiler.BeginSample("My Custom Logic");
    // 你的代码...
    Profiler.EndSample();
}

// 或使用 ProfilerMarker（更高效，推荐）
using Unity.Profiling;

private static readonly ProfilerMarker s_MyMarker = new ProfilerMarker("MyComponent.Update");

void Update()
{
    using (s_MyMarker.Auto())
    {
        // 你的代码...
    }
}

// 内存信息
long totalMemory = Profiler.GetTotalAllocatedMemoryLong();
long usedHeap = Profiler.GetMonoUsedSizeLong();
```

---

## Update 优化策略

```csharp
// 1. 不是每帧都需要执行的逻辑，使用间隔执行
private float checkInterval = 0.5f;
private float nextCheckTime;

void Update()
{
    if (Time.time >= nextCheckTime)
    {
        nextCheckTime = Time.time + checkInterval;
        ExpensiveCheck();
    }
}

// 2. 使用 InvokeRepeating 替代 Update 中的计时器
void Start()
{
    InvokeRepeating(nameof(SpawnEnemy), 2f, 1f); // 2秒后开始，每秒执行
}

// 3. 对极大量对象，考虑关闭 MonoBehaviour 用自定义管理器
public class BulletManager : MonoBehaviour
{
    private readonly List<BulletData> bullets = new();

    void Update()
    {
        for (int i = bullets.Count - 1; i >= 0; i--)
        {
            bullets[i].position += bullets[i].velocity * Time.deltaTime;
            if (bullets[i].lifetime <= 0)
                bullets.RemoveAt(i);
        }
    }
}
```
