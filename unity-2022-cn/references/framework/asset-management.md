# 资源管理详解

## 资源加载方案对比

| 方案 | 热更新 | 细粒度控制 | 复杂度 | 推荐度 |
|------|--------|-----------|--------|--------|
| Resources | ❌ | ❌ | 低 | 不推荐（原型快速开发可用） |
| AssetBundle | ✅ | ✅ | 高 | 中等（需自行管理依赖） |
| Addressables | ✅ | ✅ | 中 | ✅ 推荐 |
| 直接引用 | ❌ | ❌ | 最低 | 适合小项目 |

---

## Resources 详解

### 目录规则
- 必须放在 `Assets/Resources/` 目录下（支持多个）
- 路径不含扩展名：`Resources.Load<Sprite>("Icons/sword")`
- **所有 Resources 目录下的资源都会被打进包**，无论是否引用

```csharp
// 同步加载
GameObject prefab = Resources.Load<GameObject>("Prefabs/Enemy");
Sprite sprite = Resources.Load<Sprite>("Icons/sword");
TextAsset json = Resources.Load<TextAsset>("Config/items");
AudioClip clip = Resources.Load<AudioClip>("Audio/bgm");

// 加载所有
Object[] allPrefabs = Resources.LoadAll("Prefabs");
Sprite[] allSprites = Resources.LoadAll<Sprite>("Icons");

// 异步加载
private IEnumerator LoadAsync()
{
    ResourceRequest req = Resources.LoadAsync<GameObject>("Prefabs/BigAsset");
    yield return req;

    if (req.asset != null)
    {
        Instantiate(req.asset);
    }
}

// 释放
Resources.UnloadAsset(texture);        // 释放单个（不能释放 GameObject/Component）
Resources.UnloadUnusedAssets();         // 释放所有未引用资源（异步，较耗时）
```

### Resources 使用建议
- **仅用于**：启动画面、常驻配置、全局字体等全局资源
- **不要用于**：关卡资源、大量贴图、可选内容
- 理由：无法按需加载，增大包体和初始内存

---

## AssetBundle 详解

### 构建 AssetBundle

```csharp
#if UNITY_EDITOR
using UnityEditor;

public class AssetBundleBuilder
{
    [MenuItem("Build/Build AssetBundles")]
    static void BuildAll()
    {
        string output = "Assets/AssetBundles";
        if (!System.IO.Directory.Exists(output))
            System.IO.Directory.CreateDirectory(output);

        BuildPipeline.BuildAssetBundles(
            output,
            BuildAssetBundleOptions.ChunkBasedCompression,
            EditorUserBuildSettings.activeBuildTarget
        );
    }
}
#endif
```

### 加载使用

```csharp
using System.Collections;
using UnityEngine;
using UnityEngine.Networking;

public class BundleLoader : MonoBehaviour
{
    // 从本地文件加载
    private IEnumerator LoadFromFile(string path)
    {
        AssetBundle bundle = AssetBundle.LoadFromFile(path);
        if (bundle == null)
        {
            Debug.LogError("加载失败");
            yield break;
        }

        GameObject prefab = bundle.LoadAsset<GameObject>("MyPrefab");
        Instantiate(prefab);

        // 使用完毕卸载
        bundle.Unload(false);
    }

    // 从网络加载
    private IEnumerator LoadFromWeb(string url)
    {
        using (UnityWebRequest req = UnityWebRequestAssetBundle.GetAssetBundle(url))
        {
            yield return req.SendWebRequest();

            if (req.result != UnityWebRequest.Result.Success)
            {
                Debug.LogError(req.error);
                yield break;
            }

            AssetBundle bundle = DownloadHandlerAssetBundle.GetContent(req);
            // 使用 bundle...
        }
    }

    // 异步加载资源
    private IEnumerator LoadAssetAsync(AssetBundle bundle, string assetName)
    {
        AssetBundleRequest req = bundle.LoadAssetAsync<GameObject>(assetName);
        yield return req;

        if (req.asset != null)
        {
            Instantiate(req.asset as GameObject);
        }
    }
}
```

### Unload 策略

```csharp
// bundle.Unload(false):
//   - 释放 bundle 的压缩数据
//   - 已加载的资源保留在内存
//   - 之后无法再从此 bundle 加载新资源
//   - 可能导致资源副本（重新加载 bundle 后加载同一资源）

// bundle.Unload(true):
//   - 释放 bundle 和所有已加载的资源
//   - 如果有对象仍在引用这些资源，会出现丢失（粉红材质等）
//   - 确保没有引用后才使用
```

---

## Addressables 详解

### 安装
通过 Package Manager 安装 `com.unity.addressables`

### 配置
1. 打开 **Window > Asset Management > Addressables > Groups**
2. 标记资源为 Addressable（Inspector 中勾选）
3. 组织 Group（按场景/功能分组）
4. 设置 Build Path 和 Load Path

### 加载模式

```csharp
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using System.Collections.Generic;

public class AddressableManager : MonoBehaviour
{
    // === 通过 Address（字符串）加载 ===
    public async void LoadByAddress()
    {
        AsyncOperationHandle<GameObject> handle =
            Addressables.LoadAssetAsync<GameObject>("Assets/Prefabs/Enemy.prefab");
        GameObject prefab = await handle.Task;

        if (handle.Status == AsyncOperationStatus.Succeeded)
        {
            Instantiate(prefab);
        }

        // 不再需要时释放
        Addressables.Release(handle);
    }

    // === 通过 AssetReference（Inspector 拖拽）加载 ===
    [SerializeField] private AssetReference prefabRef;
    [SerializeField] private AssetReferenceGameObject enemyRef;
    [SerializeField] private AssetReferenceSprite iconRef;

    private AsyncOperationHandle<GameObject> loadedHandle;

    public async void LoadByReference()
    {
        loadedHandle = prefabRef.LoadAssetAsync<GameObject>();
        await loadedHandle.Task;
        Instantiate(loadedHandle.Result);
    }

    // === 通过 Label 批量加载 ===
    public async void LoadByLabel()
    {
        AsyncOperationHandle<IList<GameObject>> handle =
            Addressables.LoadAssetsAsync<GameObject>(
                "enemies",                              // Label
                (obj) => { Debug.Log($"加载: {obj.name}"); }  // 每个资源加载完的回调
            );
        await handle.Task;

        // handle.Result 包含所有加载的资源
    }

    // === 实例化 ===
    public async void InstantiateAddressable()
    {
        // Addressables.InstantiateAsync 会追踪实例
        AsyncOperationHandle<GameObject> handle =
            Addressables.InstantiateAsync("Assets/Prefabs/Enemy.prefab",
                transform.position, Quaternion.identity);
        GameObject instance = await handle.Task;

        // 释放实例（内部处理引用计数）
        Addressables.ReleaseInstance(instance);
        // 或直接 Destroy(instance); 如果在 Instantiate 时设置了 trackHandle = true
    }

    // === 加载场景 ===
    public async void LoadScene()
    {
        var handle = Addressables.LoadSceneAsync("Assets/Scenes/Level1.unity",
            UnityEngine.SceneManagement.LoadSceneMode.Additive);
        await handle.Task;

        // 卸载
        Addressables.UnloadSceneAsync(handle);
    }

    private void OnDestroy()
    {
        // 确保释放所有 handle
        if (loadedHandle.IsValid())
            Addressables.Release(loadedHandle);
    }
}
```

### 引用计数管理

```csharp
// Addressables 使用引用计数自动管理资源
// 每次 LoadAssetAsync → 引用计数 +1
// 每次 Release → 引用计数 -1
// 计数归零 → 资源自动卸载

// ⚠️ Load 和 Release 必须配对
AsyncOperationHandle<Sprite> handle = Addressables.LoadAssetAsync<Sprite>("icon");
await handle.Task;
// 使用...
Addressables.Release(handle); // ← 必须释放

// 多次加载同一资源，只会实际加载一次，但引用计数增加
// 必须 Release 相同次数才会真正卸载
```

---

## 特殊文件夹

| 文件夹 | 说明 |
|--------|------|
| `Assets/Resources/` | Resources.Load 加载，全部打入包 |
| `Assets/StreamingAssets/` | 原样拷贝到构建目录，只读 |
| `Assets/Editor/` | 仅编辑器脚本，不打入包 |
| `Assets/Editor Default Resources/` | 编辑器默认资源 |
| `Assets/Gizmos/` | Gizmo 图标 |
| `Assets/Plugins/` | 原生插件 |

### StreamingAssets 使用

```csharp
// 路径获取
string path = Application.streamingAssetsPath + "/config.json";

// Android 平台需要使用 UnityWebRequest（因为在 .apk 内）
private IEnumerator LoadStreamingAsset(string fileName)
{
    string path = System.IO.Path.Combine(Application.streamingAssetsPath, fileName);

#if UNITY_ANDROID && !UNITY_EDITOR
    using (UnityWebRequest req = UnityWebRequest.Get(path))
    {
        yield return req.SendWebRequest();
        string content = req.downloadHandler.text;
    }
#else
    string content = System.IO.File.ReadAllText(path);
    yield return null;
#endif
}
```

---

## 远程资源加载 (UnityWebRequest)

```csharp
using UnityEngine;
using UnityEngine.Networking;
using System.Collections;

public class WebLoader : MonoBehaviour
{
    // 加载文本/JSON
    private IEnumerator LoadText(string url)
    {
        using (UnityWebRequest req = UnityWebRequest.Get(url))
        {
            yield return req.SendWebRequest();
            if (req.result == UnityWebRequest.Result.Success)
            {
                string text = req.downloadHandler.text;
                MyData data = JsonUtility.FromJson<MyData>(text);
            }
        }
    }

    // 加载纹理
    private IEnumerator LoadTexture(string url)
    {
        using (UnityWebRequest req = UnityWebRequestTexture.GetTexture(url))
        {
            yield return req.SendWebRequest();
            if (req.result == UnityWebRequest.Result.Success)
            {
                Texture2D tex = DownloadHandlerTexture.GetContent(req);
                // 创建 Sprite
                Sprite sprite = Sprite.Create(tex,
                    new Rect(0, 0, tex.width, tex.height),
                    new Vector2(0.5f, 0.5f));
            }
        }
    }

    // 加载音频
    private IEnumerator LoadAudio(string url, AudioType type)
    {
        using (UnityWebRequest req = UnityWebRequestMultimedia.GetAudioClip(url, type))
        {
            yield return req.SendWebRequest();
            if (req.result == UnityWebRequest.Result.Success)
            {
                AudioClip clip = DownloadHandlerAudioClip.GetContent(req);
            }
        }
    }

    // POST 请求
    private IEnumerator PostData(string url, string json)
    {
        using (UnityWebRequest req = new UnityWebRequest(url, "POST"))
        {
            byte[] bodyRaw = System.Text.Encoding.UTF8.GetBytes(json);
            req.uploadHandler = new UploadHandlerRaw(bodyRaw);
            req.downloadHandler = new DownloadHandlerBuffer();
            req.SetRequestHeader("Content-Type", "application/json");

            yield return req.SendWebRequest();
            Debug.Log(req.downloadHandler.text);
        }
    }
}
```
