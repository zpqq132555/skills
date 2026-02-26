# TypeScript 质量与代码规范

## 启用 TypeScript 严格模式

```typescript
// ✅ 良好：在 tsconfig.json 中启用严格模式
{
    "compilerOptions": {
        "strict": true,
        "noImplicitAny": true,
        "strictNullChecks": true,
        "strictFunctionTypes": true,
        "strictBindCallApply": true,
        "strictPropertyInitialization": true,
        "noImplicitThis": true,
        "alwaysStrict": true
    }
}

// 显式声明可空类型
public playerName: string | null = null; // 可以为 null
public requiredName: string = ''; // 永不为 null

// ❌ 差：忽略可空性
public playerName: string; // 未初始化，可能为 undefined
```

## 使用访问修饰符（public/private/protected）

```typescript
// ✅ 良好：显式的访问修饰符
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('GameService')
export class GameService extends Component {
    // 私有实现细节
    private readonly playerNodes: Node[] = [];
    private currentLevel: number = 1;

    // protected 用于子类访问
    protected readonly maxHealth: number = 100;

    // 仅在必要时使用 public API
    public getCurrentLevel(): number {
        return this.currentLevel;
    }

    // 私有辅助方法
    private loadGameData(): void {
        // 实现
    }
}

// ❌ 差：无访问修饰符（隐式 public）
@ccclass('GameService')
export class GameService extends Component {
    playerNodes: Node[] = []; // 隐式 public
    currentLevel: number = 1; // 隐式 public
}
```

## 启用 ESLint + TypeScript 支持

```json
// ✅ 良好：.eslintrc.json 配置
{
    "parser": "@typescript-eslint/parser",
    "extends": [
        "eslint:recommended",
        "plugin:@typescript-eslint/recommended"
    ],
    "plugins": ["@typescript-eslint"],
    "rules": {
        "@typescript-eslint/explicit-function-return-type": "error",
        "@typescript-eslint/no-explicit-any": "error",
        "@typescript-eslint/no-unused-vars": "error",
        "@typescript-eslint/explicit-member-accessibility": "error"
    }
}
```

## 错误时抛出异常

**关键规则**：抛出异常而非静默失败或返回 undefined。

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('PlayerService')
export class PlayerService extends Component {
    @property(Node)
    private readonly playerNode: Node | null = null;

    // ✅ 优秀：错误时抛出异常
    protected onLoad(): void {
        if (!this.playerNode) {
            throw new Error('PlayerService: playerNode 是必需的');
        }
    }

    public getPlayer(id: string): Player {
        const player = this.players.get(id);
        if (!player) {
            // 抛出异常，不返回 undefined
            throw new Error(`未找到玩家: ${id}`);
        }
        return player;
    }

    public loadLevel(levelId: number): void {
        if (levelId < 1 || levelId > 100) {
            throw new RangeError(`无效的关卡 ID: ${levelId}。必须在 1-100 之间。`);
        }

        const levelData = this.loadLevelData(levelId);
        if (!levelData) {
            throw new Error(`加载关卡 ${levelId} 的数据失败`);
        }

        this.initializeLevel(levelData);
    }
}

// ❌ 错误：静默失败
public getPlayer(id: string): Player | undefined {
    const player = this.players.get(id);
    // 返回 undefined - 调用者不知道为什么失败
    return player;
}

// ❌ 错误：只记日志而不抛出
public loadLevel(levelId: number): void {
    if (levelId < 1) {
        console.error('无效的关卡 ID'); // 不要只是记日志
        return; // 静默失败
    }
}
```

## 日志：console.log 仅用于开发

**日志指南：**
- **console.log**：仅用于开发调试
- **生产环境移除**：包装在 `CC_DEBUG` 中或完全移除
- **性能影响**：console.log 可能降低可试玩广告速度
- **包体大小**：日志字符串增加包体大小

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

@ccclass('GameManager')
export class GameManager extends Component {
    private currentScore: number = 0;

    // ✅ 优秀：开发条件日志
    protected onLoad(): void {
        if (CC_DEBUG) {
            console.log('GameManager 已初始化');
        }
    }

    public addScore(points: number): void {
        this.currentScore += points;

        // ✅ 良好：仅开发的调试日志
        if (CC_DEBUG) {
            console.log(`分数更新: ${this.currentScore}`);
        }
    }

    private loadGameData(): void {
        try {
            const data = this.fetchData();
            this.processData(data);
        } catch (error) {
            // ✅ 良好：开发中记录错误
            if (CC_DEBUG) {
                console.error('加载游戏数据失败:', error);
            }
            // 始终抛出以让调用者处理
            throw error;
        }
    }
}

// ❌ 错误：生产环境中无条件的 console.log
public addScore(points: number): void {
    console.log(`添加 ${points} 分`); // 会出现在生产构建中
    this.currentScore += points;
}

// ❌ 错误：到处都是冗长的日志
public update(dt: number): void {
    console.log('Update 被调用'); // 每帧调用！
    console.log(`增量时间: ${dt}`); // 性能影响
}

// ✅ 更好：生产构建中移除日志或使用构建时移除
// 配置构建流程在生产中去除 console.log
```

**生产构建配置：**

```javascript
// 生产构建中移除 console.log 的配置
// rollup.config.js 或 webpack.config.js
export default {
    plugins: [
        // 生产环境移除 console 语句
        terser({
            compress: {
                drop_console: true, // 移除所有 console.* 调用
                pure_funcs: ['console.log', 'console.debug'], // 移除特定调用
            }
        })
    ]
};
```

## 不可变字段使用 readonly

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('PlayerController')
export class PlayerController extends Component {
    // ✅ 良好：不被重新赋值的 @property 字段使用 readonly
    @property(Node)
    private readonly targetNode: Node | null = null;

    @property(Number)
    private readonly moveSpeed: number = 100;

    // ✅ 良好：注入的依赖使用 readonly
    private readonly eventManager: EventManager;

    // 常规可变字段
    private currentHealth: number = 100;

    constructor(eventManager: EventManager) {
        super();
        this.eventManager = eventManager;
    }

    // ❌ 错误：不能重新赋值 readonly 字段
    public setTarget(node: Node): void {
        // this.targetNode = node; // 错误：无法赋值给 'targetNode'，因为它是只读属性
    }
}

// ❌ 差：不应可变时却可变
@ccclass('GameConfig')
export class GameConfig extends Component {
    @property(Number)
    private maxHealth: number = 100; // 应该是 readonly
}
```

## 常量使用 const

```typescript
// ✅ 良好：常量使用 const
const MAX_PLAYERS = 4;
const DEFAULT_PLAYER_NAME = 'Player';
const GAME_VERSION = '1.0.0';

// ✅ 良好：类常量使用 static readonly
@ccclass('GameRules')
export class GameRules extends Component {
    private static readonly MAX_HEALTH: number = 100;
    private static readonly MIN_LEVEL: number = 1;
    private static readonly MAX_LEVEL: number = 50;

    public static isValidLevel(level: number): boolean {
        return level >= GameRules.MIN_LEVEL && level <= GameRules.MAX_LEVEL;
    }
}

// ✅ 良好：相关常量使用枚举
export enum GameState {
    LOADING = 'loading',
    PLAYING = 'playing',
    PAUSED = 'paused',
    GAME_OVER = 'game_over',
}

// ❌ 差：常量使用 let
let maxPlayers = 4; // 应该是 const
let defaultPlayerName = 'Player'; // 应该是 const

// ❌ 差：没有常量的魔法数字
public checkHealth(): boolean {
    return this.health > 0 && this.health <= 100; // 100 是什么？
}

// ✅ 更好：命名常量
private static readonly MAX_HEALTH: number = 100;

public checkHealth(): boolean {
    return this.health > 0 && this.health <= GameRules.MAX_HEALTH;
}
```

## 不使用行内注释（使用描述性命名）

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

// ✅ 优秀：代码自解释，无行内注释
@ccclass('PlayerController')
export class PlayerController extends Component {
    @property(Node)
    private readonly healthBarNode: Node | null = null;

    private currentHealth: number = 100;
    private static readonly MAX_HEALTH: number = 100;
    private static readonly CRITICAL_HEALTH_THRESHOLD: number = 20;

    public takeDamage(amount: number): void {
        this.currentHealth = Math.max(0, this.currentHealth - amount);
        this.updateHealthBar();

        if (this.isHealthCritical()) {
            this.triggerLowHealthWarning();
        }

        if (this.isDead()) {
            this.handlePlayerDeath();
        }
    }

    private isHealthCritical(): boolean {
        return this.currentHealth <= PlayerController.CRITICAL_HEALTH_THRESHOLD;
    }

    private isDead(): boolean {
        return this.currentHealth === 0;
    }

    private triggerLowHealthWarning(): void {
        // 实现
    }

    private handlePlayerDeath(): void {
        // 实现
    }

    private updateHealthBar(): void {
        if (!this.healthBarNode) return;

        const healthPercentage = this.currentHealth / PlayerController.MAX_HEALTH;
        this.healthBarNode.scale = new Vec3(healthPercentage, 1, 1);
    }
}

// ❌ 差：行内注释解释不清晰的代码
@ccclass('PlayerController')
export class PlayerController extends Component {
    private h: number = 100; // 血量

    public td(a: number): void { // 受伤
        this.h = Math.max(0, this.h - a); // 减去伤害但不低于 0
        this.uh(); // 更新血条

        if (this.h <= 20) { // 如果血量危急
            this.tlhw(); // 触发低血量警告
        }

        if (this.h === 0) { // 如果死了
            this.hpd(); // 处理玩家死亡
        }
    }
}

// ❌ 差：注释解释代码做了什么（应该是显而易见的）
public addScore(points: number): void {
    // 将分数加到当前分数上
    this.currentScore += points;

    // 检查分数是否超过最大值
    if (this.currentScore > MAX_SCORE) {
        // 将分数设为最大值
        this.currentScore = MAX_SCORE;
    }
}

// ✅ 更好：描述性命名使注释不必要
public addScore(points: number): void {
    this.currentScore += points;
    this.clampScoreToMaximum();
}

private clampScoreToMaximum(): void {
    this.currentScore = Math.min(this.currentScore, MAX_SCORE);
}
```

**适合使用注释的情况：**

```typescript
// ✅ 良好：记录"为什么"而非"做了什么"
/**
 * 使用二次公式计算伤害以创建平滑的伤害曲线。
 * 玩测期间发现线性伤害对新玩家来说太严苛了。
 */
private calculateDamage(baseAmount: number, level: number): number {
    return baseAmount * Math.pow(level, 0.8);
}

// ✅ 良好：记录复杂算法
/**
 * A* 寻路算法实现。
 * 使用曼哈顿距离启发式进行网格移动。
 * @see https://en.wikipedia.org/wiki/A*_search_algorithm
 */
private findPath(start: Vec2, end: Vec2): Vec2[] {
    // 实现
}

// ✅ 良好：记录变通方案
/**
 * 变通方案：Cocos Creator 3.8.x 有一个 bug，精灵图集帧
 * 在首次访问时未正确加载。在 onLoad() 中访问一次
 * 可确保它们被缓存以供后续使用。
 * @see https://github.com/cocos/cocos-engine/issues/12345
 */
protected onLoad(): void {
    this.atlas?.getSpriteFrame('dummy');
}
```

## 正确处理 Null/Undefined

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('PlayerManager')
export class PlayerManager extends Component {
    @property(Node)
    private readonly playerNode: Node | null = null;

    // ✅ 优秀：显式验证和错误处理
    protected onLoad(): void {
        if (!this.playerNode) {
            throw new Error('PlayerManager: playerNode 是必需的');
        }
    }

    // ✅ 良好：可选链安全访问
    public getPlayerName(): string {
        return this.playerNode?.name ?? '未知';
    }

    // ✅ 良好：空值合并设置默认值
    public getPlayerHealth(): number {
        return this.playerNode?.getComponent(PlayerController)?.health ?? 0;
    }

    // ✅ 良好：类型守卫确保类型安全
    private isValidPlayer(node: Node | null): node is Node {
        return node !== null && node.getComponent(PlayerController) !== null;
    }

    public updatePlayer(): void {
        if (this.isValidPlayer(this.playerNode)) {
            // TypeScript 知道 playerNode 是 Node（非 null）
            const controller = this.playerNode.getComponent(PlayerController)!;
            controller.update();
        }
    }
}

// ❌ 差：无 null 检查
public updatePlayer(): void {
    this.playerNode.position = new Vec3(0, 0, 0); // 为 null 时会崩溃
}

// ❌ 差：不安全的类型断言
public getController(): PlayerController {
    return this.playerNode!.getComponent(PlayerController)!; // 不安全！
}
```

## 避免 `any` 类型

```typescript
// ✅ 良好：正确的类型和接口
interface PlayerData {
    id: string;
    name: string;
    level: number;
    health: number;
}

@ccclass('PlayerService')
export class PlayerService extends Component {
    private readonly players: Map<string, PlayerData> = new Map();

    public addPlayer(data: PlayerData): void {
        this.players.set(data.id, data);
    }

    public getPlayer(id: string): PlayerData | undefined {
        return this.players.get(id);
    }
}

// ❌ 差：使用 any 类型
@ccclass('PlayerService')
export class PlayerService extends Component {
    private players: any = {}; // 类型安全丢失

    public addPlayer(data: any): void { // 无类型检查
        this.players[data.id] = data;
    }

    public getPlayer(id: string): any { // 调用者不知道结构
        return this.players[id];
    }
}

// ✅ 良好：使用泛型替代 any
class DataStore<T> {
    private data: Map<string, T> = new Map();

    public set(key: string, value: T): void {
        this.data.set(key, value);
    }

    public get(key: string): T | undefined {
        return this.data.get(key);
    }
}

// ✅ 良好：真正未知的类型使用 unknown（比 any 安全）
function parseJSON(json: string): unknown {
    return JSON.parse(json);
}

// 然后验证并收窄类型
const result = parseJSON('{"name": "Player"}');
if (isPlayerData(result)) {
    // result 现在类型化为 PlayerData
    console.log(result.name);
}

function isPlayerData(obj: unknown): obj is PlayerData {
    return (
        typeof obj === 'object' &&
        obj !== null &&
        'id' in obj &&
        'name' in obj &&
        'level' in obj &&
        'health' in obj
    );
}
```

## 总结：质量清单

**提交代码前验证：**

- [ ] tsconfig.json 中启用了 TypeScript 严格模式
- [ ] ESLint 配置已激活且通过
- [ ] 所有类成员都有访问修饰符（public/private/protected）
- [ ] 错误时抛出异常（无静默失败）
- [ ] console.log 已移除或包装在 CC_DEBUG 中
- [ ] 不被重新赋值的字段使用了 readonly
- [ ] 常量使用了 const（而非 let）
- [ ] 无行内注释（代码自解释）
- [ ] 使用可选链（?.）安全访问属性
- [ ] 使用空值合并（??）设置默认值
- [ ] 无无理由的 `any` 类型
- [ ] 在 onLoad() 中验证了必要引用

**质量是所有其他模式的基础。首先做好这一点。**
