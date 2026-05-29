# Unity 代码审查清单

## 生命周期

- [ ] `Awake` 只做自身初始化，不依赖其他对象
- [ ] `Start` 处理跨对象依赖的初始化
- [ ] `OnEnable`/`OnDisable` 配套注册/注销事件
- [ ] `OnDestroy` 释放动态加载的资源
- [ ] 协程在对象销毁前正确停止
- [ ] 没有在 `Awake`/`Start` 中使用 `Find` 系列方法获取跨场景对象

## 序列化

- [ ] 所有 Inspector 引用字段使用 `[SerializeField] private`
- [ ] 公共字段仅用于真正需要外部访问的 API
- [ ] `[System.Serializable]` 标记嵌套数据类
- [ ] 没有序列化不必要的大数据（如 Mesh、Texture 引用应通过 Addressable）

## 内存与 GC

- [ ] `GetComponent<T>()` 结果已缓存（不在 Update 中重复调用）
- [ ] `Camera.main` 已缓存（或使用 Unity 2022+ 优化版本）
- [ ] 字符串操作使用 `StringBuilder` 或内插（避免循环内拼接）
- [ ] 使用 `CompareTag()` 代替 `tag ==` 比较
- [ ] 使用对象池代替频繁 `Instantiate`/`Destroy`
- [ ] 没有在 `Update` 中使用 LINQ
- [ ] 使用 `NonAlloc` 版本的物理查询
- [ ] 容器预分配容量 `new List<T>(capacity)`

## 物理

- [ ] Rigidbody 操作放在 `FixedUpdate` 中
- [ ] 使用 `Time.fixedDeltaTime` 而非 `Time.deltaTime`（在 FixedUpdate 中）
- [ ] 没有在 `Update` 中直接修改有 Rigidbody 物体的 Transform
- [ ] 射线检测使用了 LayerMask
- [ ] 碰撞层矩阵已优化（关闭不必要的层间碰撞）

## UI

- [ ] 事件监听使用 `AddListener`/`RemoveListener` 配对
- [ ] 不需要射线检测的 UI 元素禁用 `raycastTarget`
- [ ] 动态 UI 和静态 UI 分离到不同 Canvas
- [ ] 使用 `CanvasGroup` 控制面板显隐（而非 `SetActive`）
- [ ] 使用 TextMeshPro 而非旧版 Text

## 资源管理

- [ ] Addressables 的 `LoadAssetAsync` 有对应的 `Release`
- [ ] AssetBundle 的 `LoadFromFile` 有对应的 `Unload`
- [ ] 不在 Resources 文件夹存放大量资源
- [ ] 纹理 Max Size 和压缩格式合理
- [ ] 未使用资源通过 `Resources.UnloadUnusedAssets()` 或 `Addressables.Release()` 释放

## 线程安全

- [ ] 只在主线程访问 Unity API
- [ ] `async/await` 使用 `CancellationToken` 防止泄漏
- [ ] `OnDestroy` 中取消异步操作

## 代码质量

- [ ] 使用 `TryGetComponent` 代替 `GetComponent` + null 检查
- [ ] 使用命名空间组织代码
- [ ] 公共方法有注释（`///` XML 文档）
- [ ] 常量使用 `const` 或 `static readonly`
- [ ] 枚举有明确值（`[Flags]` 枚举使用 2 的幂）
- [ ] 避免 `SendMessage`/`BroadcastMessage`（使用直接引用或事件）
- [ ] 魔数提取为常量或 `[SerializeField]`
