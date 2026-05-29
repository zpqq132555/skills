# 显示系统 — LayaAir 1.0

> 📖 LayaAir 1.0 基于**显示对象树**驱动，无组件系统。所有逻辑通过继承 `Laya.Sprite` 或在类内手动调用 `Laya.timer.frameLoop` 驱动。

---

## 1. 显示对象层级

```
Laya.stage (Stage)
└── Sprite (根容器)
    ├── Sprite (背景层)
    ├── Sprite (游戏层)
    │   ├── Sprite (玩家)
    │   └── Sprite (敌人)
    └── Sprite (UI 层)
        ├── Text
        └── Button
```

---

## 2. Sprite 基类

### 常用属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `x`, `y` | number | 位置（相对父节点） |
| `width`, `height` | number | 尺寸 |
| `alpha` | number | 透明度 0-1 |
| `rotation` | number | 旋转角度（度） |
| `scaleX`, `scaleY` | number | 缩放 |
| `pivotX`, `pivotY` | number | 轴心点坐标 |
| `visible` | boolean | 显隐 |
| `mouseEnabled` | boolean | 接收鼠标/触摸（默认 false） |
| `mouseThrough` | boolean | 空白区域是否可点击 |
| `zOrder` | number | 层次排序 |
| `cacheAs` | string | 缓存类型："normal"/"bitmap" |

### 常用方法

```typescript
// 位置与尺寸
sp.pos(x, y);           // 等同 sp.x=x; sp.y=y;
sp.size(w, h);          // 等同 sp.width=w; sp.height=h;
sp.pivot(px, py);       // 设置轴心（世界坐标）

// 节点层级
sp.addChild(child);
sp.removeChild(child);
sp.addChildAt(child, 0);        // 插入到指定层次
sp.removeChildAt(0);
sp.removeChildren(0, -1);       // 移除所有子节点
sp.getChildAt(0);
sp.getChildByName("hero");
sp.numChildren;                  // 子节点数量
sp.removeSelf();                 // 从父节点移除
sp.destroy(true);               // 销毁（true=递归销毁子节点）

// 显示图片
sp.loadImage("res/img/bg.png");
sp.graphics.drawRect(0, 0, 200, 100, "#ff0000");
sp.graphics.drawCircle(x, y, r, "#0000ff");
sp.graphics.drawLine(x1, y1, x2, y2, "#00ff00", lineWidth);
sp.graphics.clear();
```

---

## 3. 游戏对象模式（替代组件系统）

由于 1.0 没有脚本组件，推荐以下两种模式：

### 模式 A：继承 Sprite

```typescript
class Player extends Laya.Sprite {
    private _speed: number = 5;
    private _hp: number = 100;
    private _isAlive: boolean = true;

    constructor() {
        super();
        this.loadImage("res/img/player.png");
        this.pivotX = this.width / 2;
        this.pivotY = this.height / 2;
        this.mouseEnabled = true;

        // 注册帧循环（等同 onUpdate）
        Laya.timer.frameLoop(1, this, this.update);

        // 注册事件
        this.on(Laya.Event.CLICK, this, this.onClicked);
    }

    private update(): void {
        if (!this._isAlive) return;
        this.x += this._speed;
        if (this.x > Laya.stage.width) {
            this.x = 0;
        }
    }

    public takeDamage(amount: number): void {
        this._hp -= amount;
        if (this._hp <= 0) {
            this.die();
        }
    }

    private die(): void {
        this._isAlive = false;
        // 派发死亡事件
        this.event("player-die");
    }

    private onClicked(): void {
        console.log("Player clicked");
    }

    // 必须重写 destroy 清理定时器
    public destroy(destroyChild: boolean = true): void {
        Laya.timer.clearAll(this);
        this.off(Laya.Event.CLICK, this, this.onClicked);
        super.destroy(destroyChild);
    }
}
```

### 模式 B：外部管理器模式（推荐）

```typescript
class GameManager {
    private static _inst: GameManager;
    public static get inst(): GameManager {
        if (!this._inst) this._inst = new GameManager();
        return this._inst;
    }

    private _players: Laya.Sprite[] = [];
    private _enemies: Laya.Sprite[] = [];

    public start(): void {
        Laya.timer.frameLoop(1, this, this.update);
    }

    private update(): void {
        for (const player of this._players) {
            // 更新玩家逻辑
        }
        for (const enemy of this._enemies) {
            // 更新敌人逻辑
        }
    }

    public stop(): void {
        Laya.timer.clearAll(this);
    }
}
```

---

## 4. 文本（Text）

```typescript
const txt = new Laya.Text();
Laya.stage.addChild(txt);

// 内容
txt.text = "Hello LayaAir 1.0";

// 样式
txt.color = "#ffffff";
txt.fontSize = 30;
txt.bold = true;
txt.italic = true;
txt.font = "Microsoft YaHei";

// 对齐
txt.align = "center";     // left / center / right
txt.valign = "middle";    // top / middle / bottom

// 换行
txt.wordWrap = true;
txt.leading = 5;          // 行间距
txt.size(300, 0);         // 宽度限制（高度 0 = 自动）

// 描边
txt.stroke = 2;
txt.strokeColor = "#000000";

// 溢出处理
txt.overflow = Laya.Text.SCROLL;  // VISIBLE / HIDDEN / SCROLL
```

---

## 5. 图片与图集（Texture）

```typescript
// 加载并显示图片
const sp = new Laya.Sprite();
sp.loadImage("res/img/hero.png");
Laya.stage.addChild(sp);

// 从预加载缓存获取 Texture
const tex = Laya.loader.getRes("res/img/hero.png") as Laya.Texture;
sp.graphics.drawTexture(tex, 0, 0, 100, 100);

// 图集（Atlas）使用
// 1. 先加载图集
Laya.loader.load("res/atlas/ui.atlas", Laya.Handler.create(this, () => {
    // 2. 从图集获取单帧
    const frameTex = Laya.loader.getRes("res/atlas/ui.atlas#btn_play") as Laya.Texture;
    sp.graphics.drawTexture(frameTex, 0, 0);
}));

// Image 组件（UI 用）
const img = new Laya.Image("res/img/bg.png");
img.sizeGrid = "10,10,10,10";  // 九宫格切片
Laya.stage.addChild(img);
```

---

## 6. 骨骼动画（Skeleton）

```typescript
// 加载骨骼动画资源
const skResources = [
    "res/ani/role.sk",
    "res/ani/role.png",
    "res/ani/role.atlas"
];
Laya.loader.load(skResources, Laya.Handler.create(this, () => {
    const sk = Laya.loader.getRes("res/ani/role.sk") as Laya.Skeleton;
    Laya.stage.addChild(sk);
    sk.pos(300, 500);

    // 播放动画
    sk.play("run", true);   // 第一个参数：动画名，第二个：是否循环
    sk.play(0, false);      // 也可以用动画索引

    // 动画事件监听
    sk.on(Laya.Event.COMPLETE, this, () => {
        sk.play("idle", true);
    });
}));
```

---

## 7. MovieClip（帧动画）

```typescript
// 创建帧动画
const mc = new Laya.Animation();
mc.loadAnimation("res/ani/explode.ani");

// 播放
mc.play(0, true, "explode");  // startFrame, loop, name

// 事件监听
mc.on(Laya.Event.COMPLETE, this, () => {
    mc.stop();
    mc.removeSelf();
});

// 停止
mc.stop();
```

---

## 8. 坐标系与碰撞检测

```typescript
// 坐标转换
const globalPt = new Laya.Point(100, 200);
const localPt = sp.globalToLocal(globalPt);
const backGlobal = sp.localToGlobal(localPt);

// AABB 矩形碰撞（简单）
function isColliding(sp1: Laya.Sprite, sp2: Laya.Sprite): boolean {
    const b1 = sp1.getBounds();
    const b2 = sp2.getBounds();
    return !(b1.right < b2.x || b1.x > b2.right ||
             b1.bottom < b2.y || b1.y > b2.bottom);
}

// 获取节点全局边界
const bounds = sp.getBounds();
console.log(bounds.x, bounds.y, bounds.width, bounds.height);
```

---

## 9. 常见反模式

```typescript
// ❌ 不清理 frameLoop
class Enemy extends Laya.Sprite {
    constructor() {
        super();
        Laya.timer.frameLoop(1, this, this.update);
    }
    // 忘了重写 destroy → 定时器继续运行 → 崩溃/内存泄漏
}

// ✅ 必须重写 destroy 清理定时器
class Enemy extends Laya.Sprite {
    constructor() {
        super();
        Laya.timer.frameLoop(1, this, this.update);
    }

    public destroy(destroyChild: boolean = true): void {
        Laya.timer.clearAll(this);  // ← 必须
        super.destroy(destroyChild);
    }
}

// ❌ 每帧查找节点
private update(): void {
    const hero = Laya.stage.getChildByName("hero"); // 低效！
}

// ✅ 在构造函数中缓存引用
private _hero: Laya.Sprite;
constructor() {
    super();
    Laya.timer.once(0, this, () => {
        this._hero = Laya.stage.getChildByName("hero") as Laya.Sprite;
    });
}
```
