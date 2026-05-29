# 质量审查 — LayaAir 3.x

> 审查 LayaAir 3.x 代码质量时的检查清单。

---

## 1. 代码审查清单

### TypeScript 质量
- [ ] 启用 `strict` 模式
- [ ] 无隐式 `any` 类型
- [ ] 类型转换明确（`as Laya.Sprite`）
- [ ] 无未使用的变量/导入
- [ ] 访问修饰符正确（public/private/protected）
- [ ] 常量使用 `static readonly`

### 组件规范
- [ ] `@regClass()` 和 `export` 齐全
- [ ] `@property()` 类型匹配
- [ ] 生命周期方法使用正确
- [ ] 事件注册/注销配对
- [ ] 定时器清理完整

### 错误处理
- [ ] 资源加载有 try-catch
- [ ] 空引用有保护检查
- [ ] 无静默错误（至少 console.error）
- [ ] Promise 有 catch 处理

---

## 2. 常见代码问题

### 问题 1：事件泄漏
```typescript
// ❌ 没有 off
onEnable(): void {
    Laya.stage.on("event", this, this.handler);
}
// 缺少 onDisable 中的 off！

// ✅ 修复
onDisable(): void {
    Laya.stage.off("event", this, this.handler);
}
```

### 问题 2：onUpdate 内存泄漏
```typescript
// ❌ 每帧创建对象
onUpdate(): void {
    let pos = new Laya.Vector3(this.owner.x, this.owner.y, 0);
}

// ✅ 预分配
private _pos: Laya.Vector3 = new Laya.Vector3();
onUpdate(): void {
    this._pos.setValue(this.owner.x, this.owner.y, 0);
}
```

### 问题 3：忘记清理定时器
```typescript
// ❌ 定时器未清理
onStart(): void {
    Laya.timer.loop(1000, this, this.tick);
}

// ✅ 配对清理
onDestroy(): void {
    Laya.timer.clearAll(this);
}
```

### 问题 4：装饰器缺失
```typescript
// ❌ 缺少 @regClass
export class BadScript extends Laya.Script {
    public speed: number = 5; // IDE 无法识别
}

// ✅ 完整
@regClass()
export class GoodScript extends Laya.Script {
    @property({ type: Number })
    public speed: number = 5;
}
```

### 问题 5：匿名函数事件
```typescript
// ❌ 匿名函数无法注销
onEnable(): void {
    this.owner.on(Laya.Event.CLICK, this, () => {
        console.log("clicked");
    });
}

// ✅ 命名函数
private onClick(): void {
    console.log("clicked");
}
onEnable(): void {
    this.owner.on(Laya.Event.CLICK, this, this.onClick);
}
onDisable(): void {
    this.owner.off(Laya.Event.CLICK, this, this.onClick);
}
```

### 问题 6：资源加载无错误处理
```typescript
// ❌ 无错误处理
async onStart(): Promise<void> {
    const res = await Laya.loader.load("config.json");
    this.parse(res); // res 可能为 null
}

// ✅ 安全加载
async onStart(): Promise<void> {
    try {
        const res = await Laya.loader.load("config.json");
        if (!res) {
            console.error("加载失败: config.json");
            return;
        }
        this.parse(res);
    } catch (e) {
        console.error("加载异常:", e);
    }
}
```

---

## 3. 审查优先级

| 优先级 | 检查项 |
|--------|--------|
| **P0 - 必须修复** | 事件泄漏、内存泄漏、无错误处理、装饰器缺失 |
| **P1 - 应该修复** | 类型不安全（any）、定时器未清理、性能问题 |
| **P2 - 建议优化** | 命名不规范、缺少注释、结构不清晰 |

---

## 4. 自动检查脚本

在代码审查中重点搜索的模式：

```
# 搜索未配对的事件
.on(    → 检查是否有对应的 .off(
.loop(  → 检查是否有 .clear( 或 .clearAll(
.once(  → 一般安全，但检查回调是否可能被多次注册

# 搜索潜在问题
new Laya.Vector  → 检查是否在 onUpdate 中
console.log      → 检查是否在生产代码中
as any           → 避免类型擦除
```
