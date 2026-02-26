# 显示与组件系统 — LayaAir 2.0

> 📖 LayaAir 2.0 核心特性：**脚本组件（Script）系统**，统一管理对象生命周期。

---

## 1. 脚本组件（Script）生命周期

### 完整生命周期流程
```
组件挂载
    ↓
onAwake()       ← 组件激活，owner 已准备好（只调用一次）
    ↓
onEnable()      ← 组件 enabled=true 时（每次启用都调用）
    ↓
onStart()       ← 第一次执行 onUpdate 之前（只调用一次）
    ↓
onUpdate()      ← 每帧调用
onLateUpdate()  ← 每帧 onUpdate 后调用
    ↓
onDisable()     ← 组件 enabled=false 时（每次禁用都调用）
    ↓
onDestroy()     ← 组件销毁时（只调用一次）
```

### 生命周期各阶段职责

| 生命周期 | 适合在此做的事 | 禁止在此做的事 |
|---------|-------------|-------------|
| `onAwake` | 获取 owner 引用、初始化内部状态 | 访问其他组件（可能未初始化） |
| `onEnable` | 注册事件监听、启动定时器 | 仅应初始化的逻辑（放 onStart） |
| `onStart` | 跨组件初始化、UI 绑定 | 每帧逻辑 |
| `onUpdate` | 逻辑更新、移动、状态机 | 创建临时对象、执行 find 查找 |
| `onLateUpdate` | 摄像机跟随、依赖其他组件更新后的逻辑 | - |
| `onDisable` | 注销事件监听、暂停定时器 | 释放已销毁的引用 |
| `onDestroy` | 释放资源、清理定时器、清空引用 | - |

### 标准脚本组件模板

```typescript
class EnemyScript extends Laya.Script {
    /** @prop {name: hp, tips:"血量", type: Int, default: 100} */
    public hp: number = 100;

    /** @prop {name: speed, tips:"速度", type: Number, default: 3} */
    public speed: number = 3;

    /** @prop {name: targetNode, tips:"目标节点", type: Node} */
    public targetNode: Laya.Sprite = null;

    private _spriteOwner: Laya.Sprite;
    private _isAlive: boolean = true;

    public onAwake(): void {
        this._spriteOwner = this.owner as Laya.Sprite;
    }

    public onEnable(): void {
        this._spriteOwner.on(Laya.Event.CLICK, this, this.onClicked);
    }

    public onStart(): void {
        // 跨组件初始化
        this._isAlive = true;
    }

    public onUpdate(): void {
        if (!this._isAlive) return;
        // 更新逻辑
    }

    public onDisable(): void {
        this._spriteOwner.off(Laya.Event.CLICK, this, this.onClicked);
    }

    public onDestroy(): void {
        this._spriteOwner = null;
        this.targetNode = null;
        Laya.timer.clearAll(this);
    }

    private onClicked(): void {
        this.hp -= 10;
    }
}
```

---

## 2. Script 属性 @prop 注释系统

LayaAir 2.0 IDE 支持通过特殊注释将脚本属性暴露到编辑器：

```typescript
/** @prop {name: myVar, tips:"工具提示", type: TypeName, default: defaultValue} */
```

### 支持的属性类型

| type | 说明 | 示例 |
|------|------|------|
| `Int` | 整数 | `default: 10` |
| `Number` | 浮点数 | `min: 0, max: 100` |
| `sNumber` | 滑块数值 | `min: 0, max: 1` |
| `String` | 字符串 | `default: "hello"` |
| `Bool` | 布尔值 | `default: true` |
| `Option` | 下拉选择 | `option: "a,b,c"` |
| `Color` | 颜色选择器 | - |
| `Node` | 节点引用 | `acceptTypes: Sprite` |
| `Prefab` | 预制体 | - |
| `SizeGrid` | 九宫格 | - |

```typescript
class UIConfig extends Laya.Script {
    /** @prop {name: title, type: String, default: "游戏"} */
    public title: string = "游戏";

    /** @prop {name: bgColor, type: Color} */
    public bgColor: string = "#000000";

    /** @prop {name: maxHp, tips:"最大血量", type: Int, min: 1, max: 9999, default: 100} */
    public maxHp: number = 100;

    /** @prop {name: difficulty, type: Option, option: "简单,普通,困难"} */
    public difficulty: string = "普通";

    /** @prop {name: bgImage, type: String, accept: res} */
    public bgImage: string = "";

    /** @prop {name: playerNode, type: Node, acceptTypes: Sprite} */
    public playerNode: Laya.Sprite = null;
}
```

---

## 3. 显示对象 Sprite

### 常用属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `x`, `y` | number | 位置 |
| `width`, `height` | number | 尺寸 |
| `alpha` | number | 透明度 0-1 |
| `rotation` | number | 旋转角度 |
| `scaleX`, `scaleY` | number | 缩放比例 |
| `pivotX`, `pivotY` | number | 轴心点 |
| `visible` | boolean | 显隐 |
| `mouseEnabled` | boolean | 是否接收鼠标/触摸事件 |
| `mouseThrough` | boolean | 是否响应空白区域点击 |
| `zOrder` | number | 层级排序 |
| `cacheAs` | string | 静态缓存类型（"normal"/"bitmap"） |

### 坐标方法

```typescript
sp.pos(x, y);                        // 设置位置
sp.size(width, height);              // 设置尺寸
sp.pivot(pivotX, pivotY);            // 设置轴心（世界坐标）
sp.setPivots(0.5, 0.5);             // 设置轴心（比例 0-1）

// 坐标转换
const localPos = sp.globalToLocal(globalPoint);
const globalPos = sp.localToGlobal(localPoint);
```

### 绘制图形（矢量绘图）

```typescript
const sp = new Laya.Sprite();
// 绘制矩形
sp.graphics.drawRect(0, 0, 200, 100, "#ff0000");
// 绘制圆形
sp.graphics.drawCircle(100, 100, 50, "#00ff00");
// 绘制线段
sp.graphics.drawLine(0, 0, 200, 200, "#0000ff", 2);
// 清空绘制
sp.graphics.clear();
```

---

## 4. 场景（Scene）管理（2.0 新特性）

```typescript
// 打开场景（由 IDE 编辑器生成 .scene 文件）
Laya.Scene.open("scene/Game.scene", true, null,
    Laya.Handler.create(this, this.onSceneOpened));

private onSceneOpened(scene: Laya.Scene): void {
    // scene 已添加到舞台
}

// 关闭场景
Laya.Scene.close("scene/Game.scene");

// 预加载场景（不显示）
Laya.Scene.load("scene/Preload.scene",
    Laya.Handler.create(this, (scene: Laya.Scene) => {
        // 手动添加
        Laya.stage.addChild(scene);
    }));

// 销毁场景（释放内存）
Laya.Scene.destroy("scene/Game.scene");
```

---

## 5. 节点树操作

```typescript
// 添加/移除子节点
parent.addChild(child);
parent.removeChild(child);
parent.addChildAt(child, index);  // 指定层次
parent.removeChildAt(index);
parent.removeChildren();           // 移除所有子节点

// 遍历子节点
for (let i = 0; i < parent.numChildren; i++) {
    const child = parent.getChildAt(i);
}

// 查找节点
const node = parent.getChildByName("heroSprite") as Laya.Sprite;

// 获取组件（Script 之间互访）
const script = node.getComponent(PlayerScript) as PlayerScript;
// 2.0 支持
node.addComponent(PlayerScript);
node.removeComponent(PlayerScript);
node.getComponents(Laya.Script); // 获取所有脚本组件
```

---

## 6. 常见反模式（必须避免）

```typescript
// ❌ 在 onUpdate 中查找节点
onUpdate(): void {
    const hero = Laya.stage.getChildByName("hero"); // 每帧查找！
}

// ✅ 在 onAwake/onStart 中缓存引用
private _hero: Laya.Sprite;
onStart(): void {
    this._hero = Laya.stage.getChildByName("hero") as Laya.Sprite;
}
onUpdate(): void {
    this._hero.x += 5;
}

// ❌ 在 onEnable 注册但忘记在 onDisable 注销
onEnable(): void {
    Laya.stage.on(Laya.Event.CLICK, this, this.onClick);
    // 缺少 onDisable 中的 off！→ 内存泄漏
}

// ✅ 配对注册/注销
onEnable(): void {
    Laya.stage.on(Laya.Event.CLICK, this, this.onClick);
}
onDisable(): void {
    Laya.stage.off(Laya.Event.CLICK, this, this.onClick);
}

// ❌ 不清理定时器
onDestroy(): void {
    // 忘记 clearAll → 定时器仍在运行，调用已销毁的对象 → 崩溃
}

// ✅ 销毁前清理
onDestroy(): void {
    Laya.timer.clearAll(this);
    Laya.Tween.clearAll(this.owner);
    Laya.loader.clearRes("res/img/xxx.png"); // 动态加载的资源
}
```
