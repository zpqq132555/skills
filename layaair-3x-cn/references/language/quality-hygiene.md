# 质量与规范 — LayaAir 3.x

> TypeScript 严格模式开发规范，适用于 LayaAir 3.x 项目。

---

## 1. TypeScript 严格模式

### tsconfig.json 推荐配置
```json
{
    "compilerOptions": {
        "strict": true,
        "noImplicitAny": true,
        "strictNullChecks": true,
        "noUnusedLocals": true,
        "noUnusedParameters": true
    }
}
```

---

## 2. 装饰器规范

### ✅ 正确用法
```typescript
const { regClass, property } = Laya;

@regClass()
export class GameScript extends Laya.Script {
    // 所有 IDE 可见属性必须使用 @property
    @property({ type: Number, tips: "移动速度" })
    public speed: number = 5;

    @property({ type: Laya.Sprite3D })
    public target: Laya.Sprite3D;

    // 非序列化属性：private + 下划线前缀
    private _isActive: boolean = false;
    private _timer: number = 0;
}
```

### ❌ 常见错误
```typescript
// 1. 忘记 @regClass → IDE 无法识别
export class BadScript extends Laya.Script { } // ❌

// 2. @property 类型不匹配
@property({ type: String })
public count: number = 0; // ❌ 声明 String 但实际是 number

// 3. 没有 export
@regClass()
class NotExported extends Laya.Script { } // ❌ 必须 export
```

---

## 3. 访问修饰符

```typescript
@regClass()
export class PlayerScript extends Laya.Script {
    // public: IDE 暴露属性 + 外部可访问
    @property({ type: Number })
    public speed: number = 5;

    // private: 内部状态
    private _hp: number = 100;

    // protected: 子类可访问
    protected _isAlive: boolean = true;

    // readonly: 常量
    private static readonly MAX_HP: number = 100;
    private static readonly POOL_KEY: string = "player";
}
```

---

## 4. 事件注册/注销配对

### ✅ 标准模式
```typescript
@regClass()
export class SafeScript extends Laya.Script {
    public onEnable(): void {
        this.owner.on(Laya.Event.CLICK, this, this.onClick);
        Laya.stage.on("gameEvent", this, this.onGameEvent);
    }

    public onDisable(): void {
        this.owner.off(Laya.Event.CLICK, this, this.onClick);
        Laya.stage.off("gameEvent", this, this.onGameEvent);
    }

    public onDestroy(): void {
        // 兜底清理
        Laya.stage.offAllCaller(this);
        Laya.timer.clearAll(this);
    }
}
```

---

## 5. 异常处理

```typescript
// ✅ 资源加载异常处理
public async onStart(): Promise<void> {
    try {
        const res = await Laya.loader.load("resources/config.json");
        if (!res) {
            console.error("资源加载失败: config.json");
            return;
        }
        this.initWithConfig(res);
    } catch (e) {
        console.error("加载异常:", e);
    }
}

// ✅ 空引用保护
public onUpdate(): void {
    if (!this.target || !this.target.activeInHierarchy) return;
    // 安全使用 target
}
```

---

## 6. 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 类名 | PascalCase | `PlayerScript`, `GameManager` |
| 公开属性 | camelCase | `speed`, `maxHP` |
| 私有属性 | _前缀 + camelCase | `_timer`, `_isAlive` |
| 常量 | UPPER_SNAKE | `MAX_HP`, `POOL_KEY` |
| 方法 | camelCase | `onStart()`, `fireBullet()` |
| 事件名 | camelCase 字符串 | `"gameOver"`, `"scoreChanged"` |
| 文件名 | PascalCase | `PlayerScript.ts`, `GameManager.ts` |

---

## 7. console.log 规范

```typescript
// ❌ 生产代码中不要留 console.log
public onUpdate(): void {
    console.log(this.owner.x); // ❌ 每帧打印，严重影响性能
}

// ✅ 使用条件编译或开关
private static readonly DEBUG = false;

private log(msg: string): void {
    if (PlayerScript.DEBUG) {
        console.log(`[Player] ${msg}`);
    }
}
```

---

## 8. 类型安全

```typescript
// ✅ 明确类型转换
let sp = this.owner as Laya.Sprite;
let sp3d = this.owner as Laya.Sprite3D;

// ✅ 获取组件时指定类型
let comp = node.getComponent(MyScript);

// ✅ 事件回调参数类型
private onClick(evt: Laya.Event): void {
    let target = evt.target as Laya.Sprite;
}

// ❌ 避免 any
private handleData(data: any): void { } // ❌
private handleData(data: { name: string; score: number }): void { } // ✅
```
