# UI 系统 — LayaAir 3.x

> 📖 LayaAir 3.x UI 系统包含 17 个基础组件和 9 个容器组件，支持相对布局、数据绑定和弹窗管理。

---

## 1. UI 组件概览

### 基础组件（17 个）
| 组件 | 类名 | 说明 |
|------|------|------|
| Image | `Laya.Image` | 图片显示（支持九宫格） |
| Label | `Laya.Label` | 文本标签 |
| TextInput | `Laya.TextInput` | 单行输入框 |
| TextArea | `Laya.TextArea` | 多行输入框 |
| Button | `Laya.Button` | 按钮（支持多态皮肤） |
| CheckBox | `Laya.CheckBox` | 复选框 |
| Radio | `Laya.Radio` | 单选框 |
| ComboBox | `Laya.ComboBox` | 下拉选项框 |
| Clip | `Laya.Clip` | 位图切片 |
| FontClip | `Laya.FontClip` | 字体切片 |
| ProgressBar | `Laya.ProgressBar` | 进度条 |
| HSlider | `Laya.HSlider` | 水平滑动条 |
| VSlider | `Laya.VSlider` | 垂直滑动条 |
| HScrollBar | `Laya.HScrollBar` | 水平滚动条 |
| VScrollBar | `Laya.VScrollBar` | 垂直滚动条 |
| ColorPicker | `Laya.ColorPicker` | 取色器 |
| Tab | `Laya.Tab` | 导航标签组 |

### 容器组件（9 个）
| 组件 | 类名 | 说明 |
|------|------|------|
| Box | `Laya.Box` | 基础容器 |
| HBox | `Laya.HBox` | 水平布局容器 |
| VBox | `Laya.VBox` | 垂直布局容器 |
| Panel | `Laya.Panel` | 面板容器（可滚动） |
| List | `Laya.List` | 列表组件 |
| Tree | `Laya.Tree` | 树状列表 |
| RadioGroup | `Laya.RadioGroup` | 单选框组 |
| ViewStack | `Laya.ViewStack` | 导航容器 |
| Dialog | `Laya.Dialog` | 弹窗视图 |

---

## 2. 常用 UI 组件代码示例

### Button（按钮）
```typescript
@regClass()
export class UIScript extends Laya.Script {
    @property({ type: Laya.Button })
    public btnStart: Laya.Button;

    onEnable(): void {
        this.btnStart.on(Laya.Event.CLICK, this, this.onBtnStart);
    }

    onDisable(): void {
        this.btnStart.off(Laya.Event.CLICK, this, this.onBtnStart);
    }

    private onBtnStart(): void {
        console.log("开始按钮被点击");
    }
}
```

### Label（文本标签）
```typescript
@property({ type: Laya.Label })
public lblScore: Laya.Label;

updateScore(score: number): void {
    this.lblScore.text = `分数: ${score}`;
    this.lblScore.color = "#FFFF00";
    this.lblScore.fontSize = 30;
}
```

### Image（图片）
```typescript
@property({ type: Laya.Image })
public imgBg: Laya.Image;

onStart(): void {
    this.imgBg.skin = "res/bg.png";
    this.imgBg.sizeGrid = "30,30,30,30"; // 九宫格拉伸
}
```

### ProgressBar（进度条）
```typescript
@property({ type: Laya.ProgressBar })
public hpBar: Laya.ProgressBar;

updateHP(current: number, max: number): void {
    this.hpBar.value = current / max; // 0~1
}
```

### List（列表）
```typescript
@property({ type: Laya.List })
public itemList: Laya.List;

onStart(): void {
    // 设置列表数据
    this.itemList.array = [
        { name: "物品1", count: 5 },
        { name: "物品2", count: 10 },
    ];

    // 渲染回调
    this.itemList.renderHandler = Laya.Handler.create(this, this.onRenderItem, null, false);

    // 选择回调
    this.itemList.selectHandler = Laya.Handler.create(this, this.onSelectItem, null, false);
}

private onRenderItem(cell: Laya.Box, index: number): void {
    let data = this.itemList.array[index];
    let label = cell.getChildByName("name") as Laya.Label;
    label.text = data.name;
}

private onSelectItem(index: number): void {
    console.log("选中:", index);
}
```

---

## 3. 相对布局

```typescript
// 相对于父容器的布局属性
ui.left = 0;      // 距左边距
ui.right = 0;     // 距右边距
ui.top = 0;       // 距上边距
ui.bottom = 0;    // 距下边距
ui.centerX = 0;   // 水平居中偏移
ui.centerY = 0;   // 垂直居中偏移

// 示例：底部居中按钮
btn.centerX = 0;
btn.bottom = 50;

// 全屏背景
bg.left = 0;
bg.right = 0;
bg.top = 0;
bg.bottom = 0;
```

---

## 4. Dialog 弹窗

```typescript
const { regClass, property } = Laya;

@regClass()
export class GameDialog extends Laya.Script {
    @property({ type: Laya.Button })
    public btnClose: Laya.Button;

    @property({ type: Laya.Button })
    public btnConfirm: Laya.Button;

    onEnable(): void {
        this.btnClose.on(Laya.Event.CLICK, this, this.onClose);
        this.btnConfirm.on(Laya.Event.CLICK, this, this.onConfirm);
    }

    onDisable(): void {
        this.btnClose.off(Laya.Event.CLICK, this, this.onClose);
        this.btnConfirm.off(Laya.Event.CLICK, this, this.onConfirm);
    }

    private onClose(): void {
        // 关闭弹窗
        (this.owner as Laya.Dialog).close();
    }

    private onConfirm(): void {
        // 确认操作
        this.owner.event("confirm");
        (this.owner as Laya.Dialog).close();
    }
}
```

### Dialog 管理
```typescript
// 打开弹窗
Laya.Dialog.open("dialog/Settings.ls");

// 关闭所有弹窗
Laya.Dialog.closeAll();

// 弹窗遮罩
// 在 IDE 中设置 Dialog 的 isModal 属性
```

---

## 5. 灰化与禁用

```typescript
// 禁用（变灰 + 不可交互）
btn.disabled = true;

// 仅灰化（视觉效果）
btn.gray = true;

// 恢复
btn.disabled = false;
btn.gray = false;
```

---

## 6. dataSource 数据绑定

```typescript
// UI 组件支持 dataSource 进行数据绑定
let item = new Laya.Box();
item.dataSource = {
    name: { text: "物品名称" },
    count: { text: "99" },
    icon: { skin: "res/icon.png" }
};
// 子节点 name 匹配的组件会自动绑定对应属性
```
