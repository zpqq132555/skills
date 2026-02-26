# TypeScript 质量与代码规范（Cocos Creator 2.4）

## 目录

- [TypeScript 严格模式](#typescript-严格模式)
- [访问修饰符](#访问修饰符)
- [错误处理](#错误处理)
- [日志规范](#日志规范)
- [const 和 readonly](#const-和-readonly)
- [类型安全](#类型安全)
- [命名规范](#命名规范)
- [ESLint 配置](#eslint-配置)

---

## TypeScript 严格模式

```json
// ✅ tsconfig.json 推荐配置（Cocos Creator 2.4）
{
    "compilerOptions": {
        "strict": true,
        "noImplicitAny": true,
        "strictNullChecks": true,
        "strictFunctionTypes": true,
        "noImplicitReturns": true,
        "noUnusedLocals": true,
        "noUnusedParameters": true,
        "target": "es5",
        "module": "commonjs",
        "lib": ["es2015", "es2017"],
        "allowJs": false,
        "skipLibCheck": true
    },
    "exclude": [
        "node_modules",
        "library",
        "local",
        "temp",
        "build"
    ]
}
```

---

## 访问修饰符

```typescript
const { ccclass, property } = cc._decorator;

// ✅ 优秀：所有成员有明确的访问修饰符
@ccclass
export default class GameService extends cc.Component {
    // @property 暴露给检查器的属性
    @property(cc.Node)
    public targetNode: cc.Node = null;

    // 私有实现细节
    private currentLevel: number = 1;
    private readonly maxLevel: number = 50;
    private static readonly SAVE_KEY: string = "game_data";

    // protected 用于子类访问
    protected baseSpeed: number = 100;

    // 公共 API
    public getCurrentLevel(): number {
        return this.currentLevel;
    }

    public advanceLevel(): void {
        if (this.currentLevel >= this.maxLevel) {
            throw new Error("GameService: 已达最大关卡");
        }
        this.currentLevel++;
    }

    // 私有辅助方法
    private saveProgress(): void {
        cc.sys.localStorage.setItem(
            GameService.SAVE_KEY,
            JSON.stringify({ level: this.currentLevel })
        );
    }
}

// ❌ 差：没有访问修饰符（隐式 public）
@ccclass
export default class BadExample extends cc.Component {
    targetNode: cc.Node = null;        // 隐式 public
    currentLevel: number = 1;          // 隐式 public
    saveProgress(): void { }           // 隐式 public
}
```

---

## 错误处理

```typescript
// ✅ 优秀：必要引用缺失时抛出异常
onLoad(): void {
    if (!this.targetNode) {
        throw new Error("MyComponent: targetNode 未赋值，请在编辑器中设置");
    }
    if (!this.bulletPrefab) {
        throw new Error("MyComponent: bulletPrefab 未赋值");
    }
}

// ✅ 优秀：参数验证
public setHealth(value: number): void {
    if (value < 0) {
        throw new Error(`setHealth: value 不能为负数, 收到 ${value}`);
    }
    if (value > this.maxHealth) {
        throw new Error(`setHealth: value 超出最大值 ${this.maxHealth}`);
    }
    this.currentHealth = value;
}

// ✅ 优秀：异步操作的错误处理
private loadResource(): void {
    cc.resources.load("prefabs/enemy", cc.Prefab, (err, prefab) => {
        if (err) {
            cc.error("加载 enemy prefab 失败:", err.message);
            return;
        }
        this.enemyPrefab = prefab;
    });
}

// ❌ 差：静默失败
onLoad(): void {
    // targetNode 可能为 null，后续使用会崩溃
    this.targetNode.setPosition(0, 0); // 💥 TypeError!
}

// ❌ 差：空的 catch
try {
    this.parse(data);
} catch (e) {
    // 什么都不做 → 吞掉错误，调试困难
}
```

---

## 日志规范

```typescript
// ✅ 优秀：使用 CC_DEBUG 包裹日志
if (CC_DEBUG) {
    cc.log("GameManager 已初始化, 当前关卡:", this.currentLevel);
}

// ✅ 优秀：使用 cc.warn 和 cc.error
cc.warn("玩家生命值过低:", this.health);
cc.error("加载资源失败:", err.message);

// ✅ 优秀：关键错误使用 cc.error + throw
if (!this.requiredAsset) {
    cc.error("必须的资源未找到");
    throw new Error("缺少必须资源");
}

// ❌ 差：生产代码中的 console.log
console.log("player position:", this.node.position);  // 会打包到生产环境

// ❌ 差：无条件的大量日志
update(dt: number): void {
    console.log("frame update:", dt);  // 每帧都打印，严重影响性能！
}

// Cocos Creator 2.4 日志 API:
// cc.log()   → 普通信息（CC_DEBUG 时有效）
// cc.warn()  → 警告
// cc.error() → 错误
// CC_DEBUG   → 编辑器和调试模式为 true，发布构建为 false
```

---

## const 和 readonly

```typescript
// ✅ 常量使用 const
const MAX_ENEMIES: number = 50;
const GRAVITY: number = -980;
const GAME_VERSION: string = "1.0.0";

// ✅ 类静态常量使用 static readonly
@ccclass
export default class GameConfig extends cc.Component {
    private static readonly MAX_HEALTH: number = 100;
    private static readonly MOVE_SPEED: number = 200;
    private static readonly SAVE_KEY: string = "game_save";

    // ✅ 不会被重新赋值的实例属性使用 readonly
    private readonly tempVec: cc.Vec2 = cc.v2();
    private readonly eventTarget: cc.EventTarget = new cc.EventTarget();
}

// ❌ 差：使用 let 声明不变的值
let MAX_ENEMIES = 50;  // 应该用 const
let GRAVITY = -980;    // 应该用 const
```

---

## 类型安全

```typescript
// ✅ 优秀：定义接口
interface PlayerData {
    name: string;
    level: number;
    health: number;
    inventory: string[];
}

interface EnemyConfig {
    type: string;
    health: number;
    speed: number;
    reward: number;
}

// ✅ 优秀：使用类型而不是 any
public loadPlayerData(): PlayerData | null {
    const json = cc.sys.localStorage.getItem("player");
    if (!json) return null;
    return JSON.parse(json) as PlayerData;
}

// ✅ 优秀：枚举类型
enum GameState {
    IDLE = "idle",
    PLAYING = "playing",
    PAUSED = "paused",
    GAME_OVER = "game_over",
}

// ✅ 优秀：类型守卫
function isPlayerNode(node: cc.Node): boolean {
    return node.getComponent("PlayerController") !== null;
}

// ❌ 差：使用 any
public processData(data: any): any {
    return data.value; // 完全没有类型检查
}

// ❌ 差：类型断言滥用
const player = someObject as PlayerData; // 不安全的断言
```

---

## 命名规范

```typescript
// ✅ 类名：PascalCase
export default class PlayerController extends cc.Component { }
export default class GameManager extends cc.Component { }
export default class UIScorePanel extends cc.Component { }

// ✅ 方法名和变量名：camelCase
private currentHealth: number = 100;
public getPlayerName(): string { return ""; }
private handleTouchStart(event: cc.Event.EventTouch): void { }

// ✅ 常量：UPPER_SNAKE_CASE
private static readonly MAX_HEALTH: number = 100;
private static readonly MOVE_SPEED: number = 200;
const GRAVITY: number = -980;

// ✅ 枚举值：PascalCase 或 UPPER_SNAKE_CASE
enum Direction {
    Up = "up",
    Down = "down",
    Left = "left",
    Right = "right",
}

enum GameEvent {
    SCORE_CHANGED = "score_changed",
    LEVEL_COMPLETE = "level_complete",
}

// ✅ 接口名：PascalCase（不加 I 前缀）
interface PlayerData { }
interface EnemyConfig { }

// ✅ 文件名：PascalCase（与类名一致）
// PlayerController.ts → export default class PlayerController
// GameManager.ts → export default class GameManager

// ✅ 描述性命名（不需要行内注释）
private handlePlayerDeath(): void { }      // 方法名自解释
private calculateDamageReduction(): number { return 0; }
private isPlayerInSafeZone(): boolean { return false; }
```

---

## ESLint 配置

```json
// ✅ .eslintrc.json（Cocos Creator 2.4 项目推荐）
{
    "parser": "@typescript-eslint/parser",
    "parserOptions": {
        "ecmaVersion": 2018,
        "sourceType": "module"
    },
    "extends": [
        "eslint:recommended",
        "plugin:@typescript-eslint/recommended"
    ],
    "plugins": ["@typescript-eslint"],
    "rules": {
        "@typescript-eslint/explicit-function-return-type": "warn",
        "@typescript-eslint/no-explicit-any": "warn",
        "@typescript-eslint/no-unused-vars": "error",
        "@typescript-eslint/explicit-member-accessibility": "warn",
        "no-console": "warn",
        "prefer-const": "error",
        "no-var": "error",
        "eqeqeq": ["error", "always"]
    },
    "globals": {
        "cc": "readonly",
        "CC_DEBUG": "readonly",
        "CC_EDITOR": "readonly",
        "CC_PREVIEW": "readonly",
        "CC_BUILD": "readonly"
    },
    "env": {
        "browser": true,
        "es6": true
    }
}
```
