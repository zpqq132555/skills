# UI 系统详解

Unity 2022.3 提供三种 UI 系统：**Unity UI (uGUI)**、**UI Toolkit** 和 **IMGUI**。

## UI 系统选型

| 特性 | Unity UI (uGUI) | UI Toolkit | IMGUI |
|------|-----------------|------------|-------|
| 运行时 UI | ✅ 成熟推荐 | ✅ 可用但发展中 | ❌ 不推荐 |
| 编辑器扩展 | ❌ | ✅ 推荐 | ✅ 旧方案 |
| 基于 | Component + Canvas | XML/USS（类似 HTML/CSS） | 代码绘制 |
| 布局方式 | RectTransform | Flexbox | 即时模式 |
| 推荐场景 | 游戏运行时 UI | 编辑器工具、新项目 UI | 遗留/调试 |

---

## Unity UI (uGUI) 详解

### Canvas 层级结构

```
Canvas (Screen Space - Overlay)
├── EventSystem          ← 必须存在才能接收输入
├── Panel (Image)
│   ├── Title (TMP_Text)
│   ├── Button (Button + Image)
│   │   └── Label (TMP_Text)
│   ├── Slider (Slider)
│   │   ├── Background
│   │   ├── Fill Area
│   │   └── Handle
│   └── ScrollView (ScrollRect)
│       ├── Viewport (Mask)
│       │   └── Content
│       └── Scrollbar
└── Popup (CanvasGroup)
```

### Canvas Scaler 设置

```
推荐设置（移动端适配）：
├── UI Scale Mode: Scale With Screen Size
├── Reference Resolution: 1080 x 1920 (竖屏) / 1920 x 1080 (横屏)
├── Screen Match Mode: Match Width Or Height
└── Match: 0.5 (平衡宽高) / 1 (匹配高度) / 0 (匹配宽度)
```

### 常用 UI 组件

```csharp
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using TMPro;

// === Button ===
[SerializeField] private Button myButton;
myButton.onClick.AddListener(() => Debug.Log("Clicked"));
myButton.interactable = false; // 禁用交互

// === Text (TextMeshPro) ===
[SerializeField] private TMP_Text label;
label.text = "Hello";
label.fontSize = 24;
label.color = Color.white;
label.alignment = TextAlignmentOptions.Center;

// === Image ===
[SerializeField] private Image icon;
icon.sprite = newSprite;
icon.color = new Color(1, 1, 1, 0.5f);
icon.fillAmount = 0.75f; // 需设置 Image Type = Filled
icon.raycastTarget = false; // 不阻挡射线（优化性能）

// === Slider ===
[SerializeField] private Slider hpBar;
hpBar.value = 0.5f;
hpBar.minValue = 0;
hpBar.maxValue = 1;
hpBar.onValueChanged.AddListener(OnSliderChanged);

// === Toggle ===
[SerializeField] private Toggle toggle;
toggle.isOn = true;
toggle.onValueChanged.AddListener(isOn => Debug.Log(isOn));

// === InputField (TMP) ===
[SerializeField] private TMP_InputField input;
input.text = "";
input.onEndEdit.AddListener(text => Debug.Log(text));
input.onValueChanged.AddListener(text => Debug.Log(text));

// === Dropdown (TMP) ===
[SerializeField] private TMP_Dropdown dropdown;
dropdown.options.Clear();
dropdown.options.Add(new TMP_Dropdown.OptionData("选项1"));
dropdown.options.Add(new TMP_Dropdown.OptionData("选项2"));
dropdown.value = 0;
dropdown.onValueChanged.AddListener(index => Debug.Log(index));

// === ScrollRect ===
[SerializeField] private ScrollRect scrollRect;
scrollRect.verticalNormalizedPosition = 1f; // 滚动到顶部
scrollRect.horizontalNormalizedPosition = 0f;
```

### RectTransform 操作

```csharp
RectTransform rect = GetComponent<RectTransform>();

// 锚点位置
rect.anchoredPosition = new Vector2(100, 50);

// 大小
rect.sizeDelta = new Vector2(200, 100);

// 锚点
rect.anchorMin = new Vector2(0, 0);    // 左下
rect.anchorMax = new Vector2(1, 1);    // 右上（拉伸）
rect.pivot = new Vector2(0.5f, 0.5f); // 中心

// 偏移（拉伸模式下）
rect.offsetMin = new Vector2(10, 10);  // 左下偏移
rect.offsetMax = new Vector2(-10, -10); // 右上偏移

// 坐标转换
Vector2 localPoint;
RectTransformUtility.ScreenPointToLocalPointInRectangle(
    rect, screenPoint, camera, out localPoint);
```

### CanvasGroup 控制

```csharp
// CanvasGroup 可以批量控制子元素的显示/交互
CanvasGroup group = GetComponent<CanvasGroup>();
group.alpha = 0.5f;          // 透明度（影响所有子元素）
group.interactable = false;  // 禁用交互
group.blocksRaycasts = false; // 不阻挡射线（鼠标穿透）
group.ignoreParentGroups = true; // 忽略父级 CanvasGroup
```

### 自定义事件接口 (IPointer/IDrag)

```csharp
using UnityEngine;
using UnityEngine.EventSystems;

public class DragHandler : MonoBehaviour,
    IPointerEnterHandler, IPointerExitHandler,
    IPointerDownHandler, IPointerUpHandler, IPointerClickHandler,
    IBeginDragHandler, IDragHandler, IEndDragHandler,
    IScrollHandler
{
    public void OnPointerEnter(PointerEventData eventData)
    {
        // 鼠标进入
    }

    public void OnPointerExit(PointerEventData eventData)
    {
        // 鼠标离开
    }

    public void OnPointerDown(PointerEventData eventData)
    {
        // 按下
    }

    public void OnPointerUp(PointerEventData eventData)
    {
        // 抬起
    }

    public void OnPointerClick(PointerEventData eventData)
    {
        // 点击（按下+抬起）
    }

    public void OnBeginDrag(PointerEventData eventData)
    {
        // 开始拖拽
    }

    public void OnDrag(PointerEventData eventData)
    {
        // 拖拽中
        transform.position = eventData.position;
    }

    public void OnEndDrag(PointerEventData eventData)
    {
        // 拖拽结束
    }

    public void OnScroll(PointerEventData eventData)
    {
        // 滚轮
        Debug.Log(eventData.scrollDelta);
    }
}
```

### 布局组件

| 组件 | 说明 |
|------|------|
| HorizontalLayoutGroup | 水平排列子元素 |
| VerticalLayoutGroup | 垂直排列子元素 |
| GridLayoutGroup | 网格排列 |
| LayoutElement | 控制元素的首选/最小/弹性大小 |
| ContentSizeFitter | 根据内容自适应大小 |
| AspectRatioFitter | 保持宽高比 |

---

## UI 性能优化

### 减少 Rebuild

1. **分离动态和静态 Canvas**：频繁变化的 UI 放在独立 Canvas
2. **避免频繁 SetActive**：使用 CanvasGroup.alpha = 0 替代
3. **禁用不必要的 raycastTarget**：纯装饰性 Image/Text 设为 false
4. **使用 Canvas.ForceUpdateCanvases()** 时机合理

### 减少 Draw Call

1. **合并图集**：使用 Sprite Atlas 打包 UI 贴图
2. **减少材质变体**：相同材质的元素可以合批
3. **减少 Mask 使用**：RectMask2D 性能优于 Mask
4. **避免 Layout 嵌套过深**

### 文本优化

1. 使用 **TextMeshPro** 替代旧版 Text
2. 静态文本可以用 `TextMeshPro.isTextObjectScaleStatic = true`
3. 频繁更新文本使用 `SetText()` 代替直接赋值 `.text`
