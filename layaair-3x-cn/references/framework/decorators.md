````markdown
# 组件装饰器完整参考 — LayaAir 3.x

> 📖 LayaAir 3.x 通过装饰器让 IDE 识别自定义组件脚本、暴露属性到属性面板、实现编辑器内运行和组件分组管理。

---

## 1. @regClass() — 注册组件脚本

每个组件脚本文件**必须**且**只能有一个**类使用 `@regClass()`：

```typescript
const { regClass } = Laya;

@regClass()
export class MyScript extends Laya.Script {
}
```

**规则**：
- 未标记 `@regClass()` 的类**不会被 IDE 识别**，无法添加到节点
- 一个 TS 文件**只能有一个** `@regClass()` 类
- 非 Script 子类也可使用 `@regClass()`（用于自定义对象类型被其他组件引用时）
- 发布时，未被引用的 `@regClass()` 类会被裁剪

---

## 2. @property() — 暴露属性到 IDE

### 2.1 基础用法

```typescript
const { regClass, property } = Laya;

@regClass()
export class MyScript extends Laya.Script {
    // 标准写法（推荐，支持 caption/tips 等完整功能）
    @property({ type: String, caption: "IDE显示用的别名", tips: "这是一个文本对象" })
    public text1: string = "";

    // 简写方式（仅定义类型时使用）
    @property(String)
    public text2: string = "";
}
```

### 2.2 类型定义

#### TS 基本类型

| 类型标识 | 说明 | 等价简写 |
|---------|------|---------|
| `"number"` | 数字类型 | `Number` |
| `"string"` | 单行字符串 | `String` |
| `"boolean"` | 布尔值 | `Boolean` |
| `"int"` | 整数 | `{ type: Number, fractionDigits: 0 }` |
| `"uint"` | 正整数 | `{ type: Number, fractionDigits: 0, min: 0 }` |
| `"text"` | 多行文本 | `{ type: String, multiline: true }` |
| `"any"` | 任意类型 | 只序列化，不可编辑 |

```typescript
@property(Number)         // 数字
num: number;

@property(String)         // 单行字符串
str: string;

@property(Boolean)        // 布尔
bool: boolean;

@property("int")          // 整数
int: number;

@property("uint")         // 正整数
uint: number;

@property("text")         // 多行文本
text: string;

@property("any")          // 任意类型（仅序列化）
a: any;
```

#### 引擎对象类型

```typescript
@property({ type: Laya.Camera })
private camera: Laya.Camera;

@property({ type: Laya.Scene3D })
private scene3D: Laya.Scene3D;

@property({ type: Laya.Sprite3D })
private cube: Laya.Sprite3D;

@property({ type: Laya.Sprite })
private sprite: Laya.Sprite;

@property({ type: Laya.Node })
private node: Laya.Node;

@property({ type: Laya.Prefab })
private prefab: Laya.Prefab;

@property({ type: Laya.Image })
private image: Laya.Image;

@property({ type: Laya.Label })
private label: Laya.Label;

@property({ type: Laya.Button })
private button: Laya.Button;

@property({ type: Laya.Box })
private box: Laya.Box;

@property({ type: Laya.List })
private list: Laya.List;

@property({ type: Laya.Animation })
private animation: Laya.Animation;

@property({ type: Laya.Vector3 })
private vector3: Laya.Vector3;

@property({ type: Laya.Color })
private color: Laya.Color;

@property({ type: Laya.DirectionLightCom })
private dirLight: Laya.DirectionLightCom;

@property({ type: Laya.ShurikenParticleRenderer })
private particle: Laya.ShurikenParticleRenderer;
```

#### 类型化数组

支持 7 种：`Int8Array`、`Uint8Array`、`Int16Array`、`Uint16Array`、`Int32Array`、`Uint32Array`、`Float32Array`

```typescript
@property(Int8Array)
i8a: Int8Array;

@property(Float32Array)
f32a: Float32Array;
```

#### 数组类型

```typescript
@property({ type: ["number"] })
arr1: number[];

@property({ type: ["string"] })
arr2: string[];

@property({ type: [Laya.Prefab] })
prefabs: Laya.Prefab[];
```

#### 枚举类型

```typescript
// 普通枚举（可用简写）
enum TestEnum { A, B, C }
@property(TestEnum)
enumVal: TestEnum;

// 字符串枚举（必须使用标准写法，不能简写！）
enum Direction { Up = 'UP', Down = 'DOWN', Left = 'LEFT', Right = 'RIGHT' }
@property({ type: Direction })
dir: Direction;
```

#### 字典类型（Record）

```typescript
// Record 类型，第二个参数为值的类型
@property({ type: ["Record", Number] })
dict: Record<string, number>;

@property({ type: ["Record", String] })
dictStr: Record<string, string>;
```

#### 自定义对象类型

```typescript
// Animal.ts — 自定义数据对象（也需要 @regClass()）
const { regClass, property } = Laya;

@regClass()
export default class Animal {
    @property({ type: Number })
    weight: number;
}

// MyScript.ts — 引用自定义对象
import Animal from "./Animal";

@regClass()
export class MyScript extends Laya.Script {
    @property({ type: Animal })
    animal: Animal;
}
```

### 2.3 访问器（Getter/Setter）装饰器

```typescript
@regClass()
class Animal {
    private _weight: number = 0;

    // Getter 和 Setter 同时存在时，装饰 Getter
    @property({ type: Number })
    get weight(): number {
        return this._weight;
    }
    // 没有 Setter 则为只读属性
    set weight(value: number) {
        this._weight = value;
    }
}
```

### 2.4 @property() 全部参数速查

#### 基础参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `type` | 类型 | **必填**。属性的值类型 |
| `caption` | string | IDE 属性面板的显示别名 |
| `tips` | string | 鼠标悬停提示说明 |
| `name` | string | 属性名称，一般不需设定 |

#### 序列化与可见性

| 参数 | 类型 | 说明 |
|------|------|------|
| `serializable` | boolean | 是否序列化保存到 .ls 文件（默认 true） |
| `private` | boolean | 是否在 IDE 面板上隐藏。默认下划线属性为 true，非下划线为 false |
| `hidden` | boolean \| string | 隐藏控制。支持表达式：`"!data.a"`（data 为当前类属性集合） |
| `readonly` | boolean \| string | 只读控制。支持表达式：`"data.b"` |

#### 数字控制

| 参数 | 类型 | 说明 |
|------|------|------|
| `min` | number | 最小值 |
| `max` | number | 最大值 |
| `range` | [number, number] | 滑动条范围，如 `[0, 5]` |
| `step` | number | 鼠标滑动/滚轮的最小精度 |
| `fractionDigits` | number | 小数点后保留位数 |
| `percentage` | boolean | 配合 `range: [0,1]` 显示为百分比 |

#### 字符串控制

| 参数 | 类型 | 说明 |
|------|------|------|
| `multiline` | boolean | 是否多行输入 |
| `password` | boolean | 密码输入模式 |
| `submitOnTyping` | boolean | true=每次输入提交；false=失焦后提交 |
| `prompt` | string | 输入框占位提示文本 |

#### 输入控件与验证

| 参数 | 类型 | 说明 |
|------|------|------|
| `inspector` | string \| null | 强制指定输入控件：`"number"` `"string"` `"boolean"` `"color"` `"vec2"` `"vec3"` `"vec4"` `"asset"`。设为 null 不创建控件 |
| `validator` | string | 验证表达式：`"if (value == data.text1) return '不能相同'"` |
| `enumSource` | array \| string | 下拉框数据：`[{name:"Yes", value:1}]` 或属性名（动态下拉） |
| `reverseBool` | boolean | 反转布尔值显示 |
| `nullable` | boolean | 是否允许 null（默认 true） |

#### 颜色控制

| 参数 | 类型 | 说明 |
|------|------|------|
| `showAlpha` | boolean | 是否提供透明度 alpha 修改 |
| `defaultColor` | string | 非 null 时的默认颜色，如 `"rgba(217, 232, 0, 1)"` |
| `colorNullable` | boolean | 显示 checkbox 决定颜色是否为 null |

#### 数组控制

| 参数 | 类型 | 说明 |
|------|------|------|
| `fixedLength` | boolean | 固定数组长度，不允许修改 |
| `arrayActions` | string[] | 允许的操作：`"append"` `"insert"` `"delete"` `"move"` |
| `elementProps` | object | 数组元素的属性，如 `{ range: [0, 100] }` |

#### 资源相关

| 参数 | 类型 | 说明 |
|------|------|------|
| `isAsset` | boolean | 说明此属性引用资源 |
| `assetTypeFilter` | string | 资源类型过滤，如 `"Image"` |
| `useAssetPath` | boolean | true=使用原始路径，false=使用 `res://uuid` 格式（默认 false） |

#### 分类与排序

| 参数 | 类型 | 说明 |
|------|------|------|
| `catalog` | string | 属性分类标签名，相同值归为一组 |
| `catalogCaption` | string | 分类栏目的中文别名 |
| `catalogOrder` | number | 分类栏目排序，数值越小越靠前 |
| `position` | string | 显示顺序：`"before x"` `"after x"` `"first"` `"last"` |
| `addIndent` | number | 增加缩进层级 |

#### 回调

| 参数 | 类型 | 说明 |
|------|------|------|
| `onChange` | string | 属性变化时调用的函数名（需在当前类中定义） |

### 2.5 常用组合示例

```typescript
const { regClass, property } = Laya;

enum TestEnum { A, B, C }

@regClass()
export class DemoScript extends Laya.Script {
    // ========== 基础类型 ==========
    @property({ type: Number, caption: "血量", tips: "角色血量", min: 0, max: 100 })
    public hp: number = 100;

    @property({ type: String, caption: "名称" })
    public playerName: string = "Hero";

    @property(Boolean)
    public isAlive: boolean = true;

    // ========== 带滑动条的数值 ==========
    @property({ type: Number, range: [0, 1], percentage: true, caption: "透明度" })
    public alpha: number = 1;

    @property({ type: Number, range: [0, 360], step: 1, fractionDigits: 0, caption: "角度" })
    public angle: number = 0;

    // ========== 下拉框 ==========
    @property(TestEnum)
    public enumVal: TestEnum;

    @property({ type: Number, enumSource: [{ name: "是", value: 1 }, { name: "否", value: 0 }] })
    public yesNo: number;

    // ========== 颜色 ==========
    @property({ type: Laya.Color, showAlpha: false })
    public color: Laya.Color;

    @property({ type: String, inspector: "color" })
    public colorStr: string;

    // ========== 隐藏/只读联动 ==========
    @property(Boolean)
    public showAdvanced: boolean = false;

    @property({ type: Number, hidden: "!data.showAdvanced", caption: "高级参数" })
    public advancedParam: number = 0;

    @property({ type: Boolean })
    public lockName: boolean = false;

    @property({ type: String, readonly: "data.lockName", caption: "名称" })
    public charName: string = "";

    // ========== 序列化控制（弧度/角度转换）==========
    @property({ type: Number })
    _radian: number = 0;

    @property({ type: Number, caption: "角度值", serializable: false })
    get degree(): number {
        return this._radian * (180 / Math.PI);
    }
    set degree(value: number) {
        this._radian = value * (Math.PI / 180);
    }

    // ========== 私有属性显示到面板 ==========
    @property({ type: "number", private: false })
    _velocity: number = 0;

    // ========== 资源引用 ==========
    @property({ type: String, isAsset: true, assetTypeFilter: "Image" })
    public imagePath: string;

    @property({ type: Laya.Prefab })
    public prefab: Laya.Prefab;

    // ========== 数组 ==========
    @property({ type: ["number"], fixedLength: true })
    public scores: number[] = [0, 0, 0];

    @property({ type: [Number], elementProps: { range: [0, 100] } })
    public values: number[];

    // ========== 输入验证 ==========
    @property(String)
    public text1: string;

    @property({ type: String, validator: "if (value == data.text1) return '不能与 text1 值相同'" })
    public text2: string = "";

    // ========== 属性分类 ==========
    @property({ type: "boolean", catalog: "adv", catalogCaption: "高级设置", catalogOrder: 1 })
    public debugMode: boolean;

    @property({ type: Number, catalog: "adv" })
    public debugLevel: number = 0;

    // ========== 属性变化回调 ==========
    @property({ type: Boolean, onChange: "onDebugChanged" })
    public enableDebug: boolean;

    onDebugChanged(): void {
        console.log("Debug mode changed:", this.enableDebug);
    }
}
```

### 2.6 嵌套数组与字典（特殊用法）

```typescript
// 二维字符串数组
@property([["string"]])
test1: string[][] = [["a", "b"], ["c", "d"]];

// 字典数组
@property([["Record", "string"]])
test2: Array<Record<string, string>> = [{ name: "A", value: "a" }];

// 字典值为数组
@property({ type: ["Record", [Number]], elementProps: { elementProps: { range: [0, 10] } } })
test3: Record<string, number[]> = { a: [1, 2, 3] };

// 字典值为 Prefab 数组
@property(["Record", [Laya.Prefab]])
test4: Record<string, Laya.Prefab[]>;
```

### 2.7 动态下拉框

```typescript
// 提供动态选项的 getter（数据仅用于编辑器，不序列化）
@property({ type: [["Record", String]], serializable: false })
get itemsProvider(): Array<Record<string, string>> {
    return [{ name: "Item0", value: "0" }, { name: "Item1", value: "1" }];
}

// enumSource 设为字符串，表示使用该属性名作为下拉数据源
@property({ type: String, enumSource: "itemsProvider" })
enumItems: string;
```

---

## 3. @runInEditor — IDE 编辑模式运行

让组件在 IDE 编辑器内也触发生命周期方法（`onEnable`、`onStart`、`onUpdate` 等）：

```typescript
const { regClass, property, runInEditor } = Laya;

@regClass()
@runInEditor     // 放在类之前，与 @regClass() 谁先谁后均可
export class EditorScript extends Laya.Script {
    @property({ type: Laya.Sprite3D })
    sp3: Laya.Sprite3D;

    onEnable(): void {
        console.log("编辑器中也会执行", this.sp3.name);
    }
}
```

**⚠️ 注意事项**：
- 不建议在 `@runInEditor` 中做复杂动画/物理逻辑
- IDE 场景编辑器帧率较低，效果与实际运行有差异
- 静态物体更有利于 IDE 编辑

---

## 4. @classInfo() — 组件分组管理

### 4.1 组件列表分类

将组件加入 IDE 增加组件列表的自定义分类：

```typescript
const { regClass, classInfo } = Laya;

@regClass()
@classInfo({
    menu: "MyScript",          // 分类菜单路径
    caption: "Main",           // 组件在列表中的显示名
})
export class Main extends Laya.Script {
    onStart(): void {
        console.log("Game start");
    }
}
```

### 4.2 属性分组

将多个属性显示在一个可折叠的组内：

```typescript
const { regClass, property, classInfo } = Laya;

@regClass()
@classInfo({
    properties: [
        {
            name: "Group1",
            inspector: "Group",
            options: {
                members: ["b", "c"]    // 指定组内属性名
                // 也支持范围语法：["b~c"]
            },
            position: "after a"        // 可选，指定分组显示位置
        }
    ]
})
export class MyScript extends Laya.Script {
    @property(String)
    public a: string = "";

    @property(String)
    public b: string = "";

    @property(String)
    public c: string = "";

    @property(String)
    public d: string = "";
}
```

---

## 5. 装饰器解构模式

所有装饰器**必须**从 `Laya` 解构后使用：

```typescript
// ✅ 正确 — 从 Laya 解构
const { regClass, property } = Laya;
const { regClass, property, runInEditor } = Laya;
const { regClass, property, classInfo } = Laya;
const { regClass, property, runInEditor, classInfo } = Laya;

// ❌ 错误 — 不能直接用 Laya.regClass
@Laya.regClass()   // 不支持
```

---

## 6. 完整模板

```typescript
const { regClass, property, classInfo } = Laya;

enum GameState { Idle, Running, Paused, Over }

@regClass()
@classInfo({
    menu: "Game/Player",
    caption: "玩家控制器",
    properties: [
        {
            name: "MovementGroup",
            inspector: "Group",
            options: { members: ["speed", "jumpForce"] },
            position: "after hp"
        }
    ]
})
export class PlayerController extends Laya.Script {
    // === 基础属性 ===
    @property({ type: Number, caption: "血量", min: 0, max: 100 })
    public hp: number = 100;

    // === 运动参数（分组）===
    @property({ type: Number, caption: "移动速度", range: [0, 20], step: 0.5 })
    public speed: number = 5;

    @property({ type: Number, caption: "跳跃力", min: 0 })
    public jumpForce: number = 10;

    // === 引用 ===
    @property({ type: Laya.Camera, tips: "主摄像机" })
    public mainCamera: Laya.Camera;

    @property({ type: Laya.Prefab, tips: "子弹预制体" })
    public bulletPrefab: Laya.Prefab;

    // === 高级设置 ===
    @property(Boolean)
    public showDebug: boolean = false;

    @property({ type: GameState, hidden: "!data.showDebug" })
    public forceState: GameState;

    @property({ type: Laya.Color, catalog: "Visual", catalogCaption: "视觉效果" })
    public hitColor: Laya.Color;

    // === 生命周期 ===
    onAwake(): void { }
    onEnable(): void { }
    onStart(): void { }
    onUpdate(): void { }
    onDisable(): void { }
    onDestroy(): void { }
}
```
````
