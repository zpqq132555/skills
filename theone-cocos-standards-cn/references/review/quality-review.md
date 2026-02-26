# Cocos Creator 代码质量审查

本审查关注 TypeScript 代码质量和卫生问题，确保代码可维护、可调试且符合严格的类型安全标准。

## 严格模式违规

### 缺少严格模式配置

```typescript
// ❌ 严重：tsconfig.json 未启用严格模式
{
    "compilerOptions": {
        "strict": false  // 丢失类型安全保障！
    }
}

// ✅ 正确：启用严格模式
{
    "compilerOptions": {
        "strict": true,
        "noImplicitAny": true,
        "strictNullChecks": true,
        "strictFunctionTypes": true,
        "noUnusedLocals": true,
        "noUnusedParameters": true
    }
}

// 严重级别：🔴 严重
// 影响：类型错误在运行时暴露而非编译时
// 修复：在 tsconfig.json 中开启 strict: true
```

### 隐式 any 类型

```typescript
// ❌ 严重：参数缺少类型标注
function processData(data) {          // 隐式 any
    return data.value;                // 无类型检查
}

function handleEvent(event) {         // 隐式 any
    event.stopPropagation();
}

// ✅ 正确：显式类型标注
function processData(data: GameData): number {
    return data.value;
}

function handleEvent(event: EventTouch): void {
    event.stopPropagation();
}

// 严重级别：🔴 严重
// 影响：类型安全完全失效
// 修复：为所有参数和返回值添加类型标注
```

## 访问修饰符违规

### 缺少访问修饰符

```typescript
// ❌ 严重：成员缺少访问修饰符
@ccclass('NoAccessModifiers')
export class NoAccessModifiers extends Component {
    speed: number = 10;           // 默认 public,意图不明
    scoreLabel: Label | null = null;

    onTouchStart(): void {}       // 意外暴露
    calculateScore(): number {    // 意外暴露
        return 0;
    }
}

// ✅ 正确：显式访问修饰符
@ccclass('WithAccessModifiers')
export class WithAccessModifiers extends Component {
    @property
    private readonly speed: number = 10;

    @property(Label)
    private readonly scoreLabel: Label | null = null;

    private onTouchStart(): void {}
    private calculateScore(): number {
        return 0;
    }

    // 仅需要外部访问时才用 public
    public getScore(): number {
        return this.calculateScore();
    }
}

// 严重级别：🔴 严重
// 影响：封装性被破坏,API 边界不清晰
// 修复：为所有成员添加 private/protected/public
// 原则：默认 private,仅在必要时放开
```

## 静默错误处理

### 空的 catch 块

```typescript
// ❌ 严重：静默吞掉错误
try {
    this.loadConfig();
} catch (e) {
    // 什么都不做...
}

resources.load('data/config', JsonAsset, (err, asset) => {
    if (err) return; // 静默忽略加载失败！
    this.applyConfig(asset);
});

// ✅ 正确：有意义的错误处理
try {
    this.loadConfig();
} catch (error: unknown) {
    const message = error instanceof Error
        ? error.message
        : String(error);
    warn(`配置加载失败,使用默认值: ${message}`);
    this.applyDefaults();
}

resources.load('data/config', JsonAsset, (err, asset) => {
    if (err) {
        throw new Error(`配置加载失败: ${err.message}`);
    }
    asset.addRef();
    this.applyConfig(asset);
});

// 严重级别：🔴 严重
// 影响：难以排查的隐蔽 Bug
// 修复：记录错误,提供兜底,或上抛异常
```

## 生产代码中的 console.log

### 调试日志残留

```typescript
// ❌ 重要：生产代码中的调试日志
@ccclass('DebugLogsBad')
export class DebugLogsBad extends Component {
    protected update(dt: number): void {
        console.log('position:', this.node.position);  // 每帧调用！
        console.log('dt:', dt);
    }

    private onTouchStart(event: EventTouch): void {
        console.log('touch:', event);                  // 调试残留
        console.log('node:', this.node.name);
    }
}

// ✅ 正确：使用引擎日志 API 或移除
@ccclass('ProperLoggingGood')
export class ProperLoggingGood extends Component {
    // 开发调试使用 log()
    // 警告使用 warn()
    // 错误使用 error()
    // 生产构建中这些可以被引擎自动剔除

    private onTouchStart(event: EventTouch): void {
        // 不保留调试日志
    }
}

// 严重级别：🟡 重要
// 影响：性能浪费（特别是 update 中）、包体增大
// 修复：移除 console.log,需要时使用引擎 log/warn/error
```

## 行内注释

### 代码中嵌入解释性注释

```typescript
// ❌ 重要：行内注释是代码异味
@ccclass('InlineCommentsBad')
export class InlineCommentsBad extends Component {
    protected update(dt: number): void {
        // 检查玩家是否在地面上
        if (this.playerY <= 0) {
            // 把速度设为 0
            this.velocityY = 0;
            // 标记在地面上
            this.isGrounded = true;
        }
        // 应用重力
        this.velocityY -= 9.8 * dt;
    }
}

// ✅ 正确：代码自解释
@ccclass('SelfDocumentingGood')
export class SelfDocumentingGood extends Component {
    private readonly GRAVITY: number = 9.8;

    protected update(dt: number): void {
        if (this.isOnGround()) {
            this.land();
        }
        this.applyGravity(dt);
    }

    private isOnGround(): boolean {
        return this.playerY <= 0;
    }

    private land(): void {
        this.velocityY = 0;
        this.isGrounded = true;
    }

    private applyGravity(dt: number): void {
        this.velocityY -= this.GRAVITY * dt;
    }
}

// 严重级别：🟡 重要
// 影响：代码噪音、注释与代码不一致
// 修复：通过有意义的命名和函数提取让代码自解释
// 仅在解释"为什么"（而非"做什么"）时使用注释
```

## 缺少 readonly/const

### 可变但不应被修改的值

```typescript
// ❌ 重要：应为 readonly 的属性
@ccclass('MissingReadonlyBad')
export class MissingReadonlyBad extends Component {
    @property(Node)
    private targetNode: Node | null = null;    // 运行时不会重新赋值

    private pool: Node[] = [];                  // 引用不会变
    private eventMap: Map<string, Function> = new Map(); // 引用不会变

    private maxRetries = 3;                     // 常量
    private apiUrl = 'https://example.com';     // 常量
}

// ✅ 正确：使用 readonly 和 const
@ccclass('WithReadonlyGood')
export class WithReadonlyGood extends Component {
    @property(Node)
    private readonly targetNode: Node | null = null;

    private readonly pool: Node[] = [];
    private readonly eventMap: Map<string, Function> = new Map();

    private static readonly MAX_RETRIES: number = 3;
    private static readonly API_URL: string = 'https://example.com';
}

// 严重级别：🟡 重要
// 影响：意外修改、意图不清
// 修复：不被重新赋值的属性加 readonly,真正的常量用 static readonly
```

## 使用 any 类型

### 滥用 any 绕过类型检查

```typescript
// ❌ 严重：使用 any 绕过类型系统
function processEvent(data: any): any {
    return data.result;
}

const config: any = loadConfig();
const items: any[] = getItems();

// ✅ 正确：使用正确的类型
interface EventData {
    readonly type: string;
    readonly result: number;
}

function processEvent(data: EventData): number {
    return data.result;
}

// 确实不知道类型时使用 unknown
function handleUnknown(data: unknown): void {
    if (typeof data === 'object' && data !== null && 'result' in data) {
        const result = (data as EventData).result;
    }
}

// 严重级别：🔴 严重
// 影响：类型安全被完全绕过
// 修复：定义接口,使用 unknown + 类型守卫代替 any
```

## null 处理违规

### 使用非空断言 (!) 代替正确检查

```typescript
// ❌ 严重：到处使用非空断言
@ccclass('NullAssertionBad')
export class NullAssertionBad extends Component {
    @property(Node)
    private targetNode: Node | null = null;

    protected start(): void {
        this.targetNode!.setPosition(0, 0, 0);  // 可能崩溃！
        this.targetNode!.getComponent(Sprite)!.color = Color.RED; // 双重危险！
    }
}

// ✅ 正确：适当的 null 检查
@ccclass('NullCheckGood')
export class NullCheckGood extends Component {
    @property(Node)
    private readonly targetNode: Node | null = null;

    protected onLoad(): void {
        if (!this.targetNode) {
            throw new Error('NullCheckGood: targetNode 是必需的');
        }
    }

    protected start(): void {
        // onLoad 已验证
        this.targetNode!.setPosition(0, 0, 0);

        const sprite = this.targetNode!.getComponent(Sprite);
        if (!sprite) {
            warn('未找到 Sprite 组件');
            return;
        }
        sprite.color = Color.RED;
    }
}

// 严重级别：🔴 严重
// 影响：运行时崩溃
// 修复：在 onLoad 中验证必要引用;getComponent 结果需判空
// 仅在已验证非空后才使用 ! 断言
```

## 总结：代码质量审查清单

**🔴 严重（必须修复）：**
- [ ] tsconfig.json 开启 strict: true
- [ ] 所有参数和返回值有类型标注（无隐式 any）
- [ ] 所有成员有显式访问修饰符
- [ ] 无空的 catch 块（记录/兜底/上抛）
- [ ] 不使用 any 类型（用接口或 unknown）
- [ ] 必要引用在 onLoad 中验证（减少非空断言）

**🟡 重要（应该修复）：**
- [ ] 移除 console.log（使用引擎 log/warn/error）
- [ ] 消除行内注释（代码自解释）
- [ ] 不变引用加 readonly/const
- [ ] 命名有意义（无需注释解释）

**🟢 建议（锦上添花）：**
- [ ] 使用 ESLint 自动检查规范
- [ ] 接口属性标记 readonly
- [ ] 枚举值使用字符串枚举
- [ ] 泛型约束替代类型断言

**代码质量是团队效率的基础 - 今天的偷懒是明天的技术债。**
