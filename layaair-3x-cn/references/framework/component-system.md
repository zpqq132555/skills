# 组件系统 — LayaAir 3.x

> 📖 LayaAir 3.x 核心特性：**ECS 组件系统** + **装饰器**（`@regClass`/`@property`），替代 2.x 的 `@prop` 注释。

---

## 1. 组件脚本（Script）生命周期

### 完整生命周期流程
```
组件挂载到节点
    ↓
onAdded()       ← 被添加到节点后（即使节点未激活也调用）
    ↓
onReset()       ← 重置参数（实现此函数则自动回收到对象池）
    ↓
onAwake()       ← 组件首次激活，只执行一次
    ↓
onEnable()      ← 组件被启用（每次添加到舞台都执行）
    ↓
onStart()       ← 第一次 onUpdate 之前，只执行一次
    ↓
onUpdate()      ← 每帧调用
onLateUpdate()  ← 每帧 onUpdate 之后调用
    ↓
onPreRender()   ← 渲染之前
onPostRender()  ← 渲染之后
    ↓
onDisable()     ← 组件被禁用（如从舞台移除）
    ↓
onDestroy()     ← 节点销毁时（只执行一次）
```

### 生命周期各阶段职责

| 生命周期 | 适合做的事 | 禁止做的事 |
|---------|-----------|-----------|
| `onAdded` | 极早期初始化，此时组件已挂载到节点 | 依赖激活状态的逻辑 |
| `onAwake` | 获取 owner 引用、初始化内部状态（只执行一次） | 访问其他组件（可能未初始化） |
| `onEnable` | 注册事件监听、启动定时器（对象池取出也会触发） | 仅应初始化的逻辑 |
| `onStart` | 跨组件初始化、UI 绑定 | 每帧逻辑 |
| `onUpdate` | 逻辑更新、移动、状态机 | 创建临时对象、find 查找 |
| `onLateUpdate` | 摄像机跟随、后处理逻辑 | - |
| `onPreRender` | 渲染前数据准备 | 耗时逻辑 |
| `onDisable` | 注销事件监听、暂停定时器 | 释放已销毁的引用 |
| `onDestroy` | 释放资源、清理定时器、清空引用 | - |

**关键区别**：
- `onAwake` → 只执行一次（首次激活时）
- `onEnable` → 每次添加到舞台都执行（包括从对象池取出时）
- 对象池复用场景**必须**在 `onEnable` 中做初始化

---

## 2. 装饰器系统

### @regClass() — 注册组件脚本类（必须）
```typescript
const { regClass, property } = Laya;

@regClass()
export class MyScript extends Laya.Script { }
```
- 所有继承 `Laya.Script` 的类**必须**使用 `@regClass()`
- 否则无法在 IDE 中使用、属性不会被序列化

### @property() — 暴露属性到 IDE

> 📖 **完整参数详见** [装饰器参考](decorators.md)，此处仅列出常用写法。

```typescript
// 完整参数
@property({ type: Number, caption: "速度", tips: "移动速度" })
public speed: number = 5;

// 简写
@property(Number)
public count: number = 0;

// 引擎对象类型
@property({ type: Laya.Sprite3D })
public target: Laya.Sprite3D;

@property({ type: Laya.Prefab })
public bulletPrefab: Laya.Prefab;

@property({ type: Laya.Camera })
public mainCamera: Laya.Camera;

// 字符串
@property({ type: String, caption: "名称" })
public playerName: string = "Hero";

// 布尔
@property({ type: Boolean })
public isAlive: boolean = true;

// 枚举
enum Direction { Up, Down, Left, Right }
@property(Direction)
public dir: Direction = Direction.Up;

// 字符串枚举（必须用标准写法）
enum StrEnum { A = "a", B = "b" }
@property({ type: StrEnum })
public strDir: StrEnum;

// 数组
@property({ type: ["number"] })
public scores: number[];

// 带滑动条的数值
@property({ type: Number, range: [0, 1], percentage: true })
public alpha: number = 1;

// 隐藏联动
@property(Boolean)
public showAdv: boolean = false;

@property({ type: Number, hidden: "!data.showAdv" })
public advParam: number = 0;

// 资源引用
@property({ type: String, isAsset: true, assetTypeFilter: "Image" })
public imagePath: string;
```

### @property() 常用参数速查

> 📖 **全部 30+ 参数详见** [装饰器参考](decorators.md#24-property-全部参数速查)

| 参数 | 类型 | 说明 |
|------|------|------|
| `type` | 类型 | **必填**。属性类型 |
| `caption` | string | IDE 面板显示别名 |
| `tips` | string | 鼠标悬停提示 |
| `serializable` | boolean | 是否序列化保存（默认 true） |
| `private` | boolean | 是否在面板隐藏 |
| `hidden` | boolean \| string | 隐藏控制，支持表达式 `"!data.a"` |
| `readonly` | boolean \| string | 只读控制，支持表达式 `"data.b"` |
| `range` | [min, max] | 滑动条范围 |
| `min` / `max` | number | 最小/最大值 |
| `inspector` | string | 输入控件类型（`"color"` `"vec3"` 等） |
| `enumSource` | array \| string | 下拉框数据源 |
| `isAsset` | boolean | 是否引用资源 |
| `catalog` | string | 属性分类标签 |
| `catalogCaption` | string | 分类别名 |
| `catalogOrder` | number | 分类排序 |
| `onChange` | string | 属性变化回调函数名 |

### @runInEditor — 在 IDE 编辑模式运行
```typescript
const { regClass, runInEditor } = Laya;

@regClass()
@runInEditor
export class EditorScript extends Laya.Script {
    onUpdate(): void {
        // 在 IDE 编辑器中也会执行
    }
}
```

### @classInfo() — 组件分组管理
```typescript
const { regClass, classInfo } = Laya;

@regClass()
@classInfo({ menu: "MyScripts", caption: "玩家控制器" })
export class PlayerController extends Laya.Script { }
```

---

## 3. 标准脚本组件模板

```typescript
const { regClass, property } = Laya;

@regClass()
export class EnemyScript extends Laya.Script {
    @property({ type: Number, tips: "血量" })
    public hp: number = 100;

    @property({ type: Number, tips: "移动速度" })
    public speed: number = 3;

    @property({ type: Laya.Sprite3D, tips: "目标节点" })
    public targetNode: Laya.Sprite3D;

    private _isAlive: boolean = true;

    public onAwake(): void {
        // 初始化，只执行一次
    }

    public onEnable(): void {
        // 注册事件（每次添加到舞台）
        this.owner.on(Laya.Event.CLICK, this, this.onClicked);
    }

    public onStart(): void {
        this._isAlive = true;
    }

    public onUpdate(): void {
        if (!this._isAlive) return;
        // 更新逻辑
    }

    public onDisable(): void {
        // 注销事件（每次从舞台移除）
        this.owner.off(Laya.Event.CLICK, this, this.onClicked);
    }

    public onDestroy(): void {
        this.targetNode = null;
        Laya.timer.clearAll(this);
    }

    private onClicked(evt: Laya.Event): void {
        this.hp -= 10;
        if (this.hp <= 0) {
            this._isAlive = false;
            this.owner.destroy(true);
        }
    }
}
```

---

## 4. 脚本内置事件方法

LayaAir 3.x 的 Script 内置了鼠标、键盘、物理事件方法，无需手动注册：

### 鼠标事件
```typescript
public onMouseDown(evt: Laya.Event): void { }
public onMouseUp(evt: Laya.Event): void { }
public onMouseClick(evt: Laya.Event): void { }
public onMouseMove(evt: Laya.Event): void { }
public onMouseOver(evt: Laya.Event): void { }
public onMouseOut(evt: Laya.Event): void { }
public onMouseDrag(evt: Laya.Event): void { }
public onMouseDragEnd(evt: Laya.Event): void { }
```

### 键盘事件
```typescript
public onKeyDown(evt: Laya.Event): void { }
public onKeyPress(evt: Laya.Event): void { }
public onKeyUp(evt: Laya.Event): void { }
```

### 物理碰撞事件（2D/3D 通用）
```typescript
public onTriggerEnter(other: any, self?: any, contact?: any): void { }
public onTriggerStay(other: any, self?: any, contact?: any): void { }
public onTriggerExit(other: any, self?: any, contact?: any): void { }
public onCollisionEnter(other: any, self?: any, contact?: any): void { }
public onCollisionStay(other: any, self?: any, contact?: any): void { }
public onCollisionExit(other: any, self?: any, contact?: any): void { }
```

---

## 5. 与 2.x 组件系统的对比

| 特性 | 3.x | 2.x |
|------|-----|-----|
| 类注册 | `@regClass()` | 无需装饰器 |
| 属性暴露 | `@property({ type })` | `/** @prop {name, type} */` |
| IDE 运行 | `@runInEditor` | 不支持 |
| 组件分组 | `@classInfo()` | 不支持 |
| 内置事件 | `onMouseClick` 等直接重写 | 需手动 `on(Event)` |
| 生命周期 | 新增 `onAdded`、`onReset`、`onPreRender`、`onPostRender` | 无 |
| 对象池 | `onReset` 自动支持 | 手动实现 |
