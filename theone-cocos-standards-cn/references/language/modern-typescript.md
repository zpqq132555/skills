# 现代 TypeScript 模式

## 数组方法替代循环

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass } = _decorator;

interface Enemy {
    node: Node;
    isActive: boolean;
    health: number;
    damage: number;
}

@ccclass('EnemyManager')
export class EnemyManager extends Component {
    private readonly enemies: Enemy[] = [];

    // ✅ 优秀：使用数组方法过滤
    public getActiveEnemies(): Enemy[] {
        return this.enemies.filter(enemy => enemy.isActive);
    }

    // ✅ 优秀：使用数组方法映射
    public getEnemyPositions(): Vec3[] {
        return this.enemies.map(enemy => enemy.node.position.clone());
    }

    // ✅ 优秀：使用数组方法归约
    public getTotalDamage(): number {
        return this.enemies.reduce((total, enemy) => total + enemy.damage, 0);
    }

    // ✅ 优秀：链式调用数组方法
    public getActiveEnemyDamage(): number {
        return this.enemies
            .filter(enemy => enemy.isActive)
            .reduce((total, enemy) => total + enemy.damage, 0);
    }

    // ✅ 优秀：使用 find 替代手动循环
    public findEnemyById(id: string): Enemy | undefined {
        return this.enemies.find(enemy => enemy.node.uuid === id);
    }

    // ✅ 优秀：使用 some/every 进行存在性检查
    public hasActiveEnemies(): boolean {
        return this.enemies.some(enemy => enemy.isActive);
    }

    public areAllEnemiesDead(): boolean {
        return this.enemies.every(enemy => enemy.health <= 0);
    }
}

// ❌ 差：手动循环
public getActiveEnemies(): Enemy[] {
    const active: Enemy[] = [];
    for (let i = 0; i < this.enemies.length; i++) {
        if (this.enemies[i].isActive) {
            active.push(this.enemies[i]);
        }
    }
    return active;
}

// ❌ 差：手动累加
public getTotalDamage(): number {
    let total = 0;
    for (const enemy of this.enemies) {
        total += enemy.damage;
    }
    return total;
}
```

## 箭头函数和回调

```typescript
import { _decorator, Component, Node, EventTouch } from 'cc';
const { ccclass } = _decorator;

@ccclass('InputHandler')
export class InputHandler extends Component {
    private readonly buttons: Node[] = [];

    // ✅ 优秀：回调使用箭头函数
    protected onEnable(): void {
        this.buttons.forEach(button => {
            button.on(Node.EventType.TOUCH_START, this.onButtonClick, this);
        });
    }

    protected onDisable(): void {
        this.buttons.forEach(button => {
            button.off(Node.EventType.TOUCH_START, this.onButtonClick, this);
        });
    }

    // ✅ 良好：箭头函数保持 this 上下文
    private readonly onButtonClick = (event: EventTouch): void => {
        const button = event.target as Node;
        this.handleButtonClick(button);
    };

    // ✅ 良好：箭头函数用于事件处理
    private setupAsyncOperation(): void {
        setTimeout(() => {
            this.processData();
        }, 1000);
    }

    // ✅ 良好：Promise 链中的箭头函数
    private async loadData(): Promise<void> {
        fetch('data.json')
            .then(response => response.json())
            .then(data => this.processData(data))
            .catch(error => this.handleError(error));
    }
}

// ❌ 差：函数表达式丢失 this 上下文
protected onEnable(): void {
    this.buttons.forEach(function(button) {
        // 'this' 为 undefined 或错误的上下文
        button.on(Node.EventType.TOUCH_START, this.onButtonClick, this);
    });
}

// ❌ 差：冗长的函数语法
private setupAsyncOperation(): void {
    const self = this;
    setTimeout(function() {
        self.processData();
    }, 1000);
}
```

## 解构

```typescript
import { _decorator, Component, Node, Vec3 } from 'cc';
const { ccclass, property } = _decorator;

interface PlayerData {
    id: string;
    name: string;
    level: number;
    health: number;
    position: { x: number; y: number; z: number };
}

@ccclass('PlayerController')
export class PlayerController extends Component {
    // ✅ 优秀：参数中使用解构
    public updatePlayer({ id, name, level, health, position }: PlayerData): void {
        console.log(`更新 ${name} (${id}) 等级 ${level}`);

        // ✅ 优秀：嵌套解构
        const { x, y, z } = position;
        this.node.setPosition(x, y, z);
    }

    // ✅ 优秀：带默认值的解构
    public loadConfig({ speed = 100, jumpHeight = 50, maxHealth = 100 } = {}): void {
        this.speed = speed;
        this.jumpHeight = jumpHeight;
        this.maxHealth = maxHealth;
    }

    // ✅ 优秀：数组解构
    public getPlayerPosition(): Vec3 {
        const [x, y, z] = [this.node.position.x, this.node.position.y, this.node.position.z];
        return new Vec3(x, y, z);
    }

    // ✅ 优秀：解构配合剩余运算符
    public handleInput({ type, ...eventData }: InputEvent): void {
        switch (type) {
            case 'touch':
                this.handleTouch(eventData);
                break;
            case 'key':
                this.handleKey(eventData);
                break;
        }
    }
}

// ❌ 差：不使用解构
public updatePlayer(playerData: PlayerData): void {
    console.log(`更新 ${playerData.name} (${playerData.id}) 等级 ${playerData.level}`);
    this.node.setPosition(playerData.position.x, playerData.position.y, playerData.position.z);
}

// ❌ 差：冗长的属性访问
public loadConfig(config: Config): void {
    this.speed = config.speed !== undefined ? config.speed : 100;
    this.jumpHeight = config.jumpHeight !== undefined ? config.jumpHeight : 50;
    this.maxHealth = config.maxHealth !== undefined ? config.maxHealth : 100;
}
```

## 展开运算符

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

interface GameConfig {
    playerName: string;
    difficulty: string;
    soundEnabled: boolean;
}

@ccclass('GameManager')
export class GameManager extends Component {
    private readonly defaultConfig: GameConfig = {
        playerName: 'Player',
        difficulty: 'normal',
        soundEnabled: true,
    };

    // ✅ 优秀：展开运算符合并对象
    public createConfig(overrides: Partial<GameConfig>): GameConfig {
        return { ...this.defaultConfig, ...overrides };
    }

    // ✅ 优秀：展开运算符拼接数组
    private readonly baseEnemies: string[] = ['goblin', 'orc'];
    private readonly bossEnemies: string[] = ['dragon', 'demon'];

    public getAllEnemies(): string[] {
        return [...this.baseEnemies, ...this.bossEnemies];
    }

    // ✅ 优秀：展开运算符克隆数组
    public cloneEnemyList(): string[] {
        return [...this.baseEnemies];
    }

    // ✅ 优秀：函数调用中的展开
    public calculateMaxValue(...values: number[]): number {
        return Math.max(...values);
    }

    // ✅ 优秀：展开用于不可变更新
    public addEnemy(enemy: string): void {
        this.baseEnemies = [...this.baseEnemies, enemy];
    }
}

// ❌ 差：手动合并
public createConfig(overrides: Partial<GameConfig>): GameConfig {
    const config: GameConfig = {
        playerName: overrides.playerName ?? this.defaultConfig.playerName,
        difficulty: overrides.difficulty ?? this.defaultConfig.difficulty,
        soundEnabled: overrides.soundEnabled ?? this.defaultConfig.soundEnabled,
    };
    return config;
}

// ❌ 差：手动拼接
public getAllEnemies(): string[] {
    const enemies: string[] = [];
    for (const enemy of this.baseEnemies) {
        enemies.push(enemy);
    }
    for (const enemy of this.bossEnemies) {
        enemies.push(enemy);
    }
    return enemies;
}
```

## 可选链（?.）

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

interface Player {
    name: string;
    stats?: {
        health?: number;
        level?: number;
    };
    inventory?: {
        items?: Item[];
    };
}

@ccclass('PlayerManager')
export class PlayerManager extends Component {
    @property(Node)
    private readonly playerNode: Node | null = null;

    // ✅ 优秀：可选链安全访问
    public getPlayerName(): string | undefined {
        return this.playerNode?.name;
    }

    // ✅ 优秀：深层可选链
    public getPlayerHealth(player: Player): number | undefined {
        return player?.stats?.health;
    }

    // ✅ 优秀：数组的可选链
    public getFirstItem(player: Player): Item | undefined {
        return player?.inventory?.items?.[0];
    }

    // ✅ 优秀：方法的可选链
    public getComponentName(): string | undefined {
        return this.playerNode?.getComponent(PlayerController)?.getName?.();
    }

    // ✅ 优秀：配合空值合并
    public getDisplayName(): string {
        return this.playerNode?.name ?? '未知玩家';
    }
}

// ❌ 差：手动 null 检查
public getPlayerName(): string | undefined {
    if (this.playerNode !== null && this.playerNode !== undefined) {
        return this.playerNode.name;
    }
    return undefined;
}

// ❌ 差：嵌套 null 检查
public getPlayerHealth(player: Player): number | undefined {
    if (player) {
        if (player.stats) {
            if (player.stats.health !== undefined) {
                return player.stats.health;
            }
        }
    }
    return undefined;
}
```

## 空值合并（??）

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

interface GameConfig {
    playerName?: string;
    maxHealth?: number;
    soundVolume?: number;
    enableTutorial?: boolean;
}

@ccclass('ConfigManager')
export class ConfigManager extends Component {
    // ✅ 优秀：空值合并设置默认值
    public loadConfig(config: GameConfig): void {
        const playerName = config.playerName ?? 'Player';
        const maxHealth = config.maxHealth ?? 100;
        const soundVolume = config.soundVolume ?? 0.5;
        const enableTutorial = config.enableTutorial ?? true;

        console.log({ playerName, maxHealth, soundVolume, enableTutorial });
    }

    // ✅ 优秀：空值合并保留假值
    public getVolume(volume?: number): number {
        // volume 为 0 时返回 0（不像 || 会返回 1）
        return volume ?? 1;
    }

    // ✅ 优秀：链式空值合并
    public getPlayerName(primaryName?: string, secondaryName?: string): string {
        return primaryName ?? secondaryName ?? '未知';
    }

    // ✅ 优秀：空值合并配合可选链
    public getHealthDisplay(player?: Player): string {
        const health = player?.stats?.health ?? 0;
        return `血量: ${health}`;
    }
}

// ❌ 差：使用 || 运算符（将 0、''、false 当作 null）
public getVolume(volume?: number): number {
    return volume || 1; // volume 为 0 时也返回 1
}

// ❌ 差：手动 null/undefined 检查
public loadConfig(config: GameConfig): void {
    const playerName = config.playerName !== null && config.playerName !== undefined
        ? config.playerName
        : 'Player';
}

// ❌ 差：冗长的三元表达式
public getPlayerName(name?: string): string {
    return name !== undefined && name !== null ? name : '未知';
}
```

## 类型守卫

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass } = _decorator;

// ✅ 优秀：接口的类型守卫
interface Player {
    type: 'player';
    health: number;
    level: number;
}

interface Enemy {
    type: 'enemy';
    health: number;
    damage: number;
}

type Entity = Player | Enemy;

function isPlayer(entity: Entity): entity is Player {
    return entity.type === 'player';
}

function isEnemy(entity: Entity): entity is Enemy {
    return entity.type === 'enemy';
}

@ccclass('CombatManager')
export class CombatManager extends Component {
    public handleEntity(entity: Entity): void {
        if (isPlayer(entity)) {
            // TypeScript 知道 entity 是 Player
            console.log(`玩家等级: ${entity.level}`);
        } else if (isEnemy(entity)) {
            // TypeScript 知道 entity 是 Enemy
            console.log(`敌人伤害: ${entity.damage}`);
        }
    }

    // ✅ 优秀：null/undefined 的类型守卫
    private isValidNode(node: Node | null | undefined): node is Node {
        return node !== null && node !== undefined;
    }

    public processNode(node: Node | null): void {
        if (this.isValidNode(node)) {
            // TypeScript 知道 node 是 Node（非 null）
            node.setPosition(0, 0, 0);
        }
    }

    // ✅ 优秀：组件的类型守卫
    private hasPlayerController(node: Node): node is Node & { getComponent(PlayerController): PlayerController } {
        return node.getComponent(PlayerController) !== null;
    }

    public updatePlayer(node: Node): void {
        if (this.hasPlayerController(node)) {
            // TypeScript 知道组件存在
            const controller = node.getComponent(PlayerController)!;
            controller.update();
        }
    }
}

// ❌ 差：无类型守卫，到处类型断言
public handleEntity(entity: Entity): void {
    if (entity.type === 'player') {
        console.log(`玩家等级: ${(entity as Player).level}`); // 类型断言
    } else {
        console.log(`敌人伤害: ${(entity as Enemy).damage}`); // 类型断言
    }
}
```

## 工具类型

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

interface GameConfig {
    playerName: string;
    maxHealth: number;
    difficulty: string;
    soundEnabled: boolean;
}

@ccclass('ConfigManager')
export class ConfigManager extends Component {
    // ✅ 优秀：Partial 用于可选属性
    public updateConfig(updates: Partial<GameConfig>): void {
        // 所有属性都是可选的
    }

    // ✅ 优秀：Required 用于强制属性
    public validateConfig(config: Required<GameConfig>): void {
        // 所有属性都是必需的
    }

    // ✅ 优秀：Readonly 用于不可变对象
    private readonly defaultConfig: Readonly<GameConfig> = {
        playerName: 'Player',
        maxHealth: 100,
        difficulty: 'normal',
        soundEnabled: true,
    };

    // ✅ 优秀：Pick 用于选择属性
    public getDisplayInfo(config: GameConfig): Pick<GameConfig, 'playerName' | 'difficulty'> {
        return {
            playerName: config.playerName,
            difficulty: config.difficulty,
        };
    }

    // ✅ 优秀：Omit 用于排除属性
    public getPublicConfig(config: GameConfig): Omit<GameConfig, 'soundEnabled'> {
        const { soundEnabled, ...publicConfig } = config;
        return publicConfig;
    }

    // ✅ 优秀：Record 用于键值映射
    private readonly difficultyMultipliers: Record<string, number> = {
        easy: 0.5,
        normal: 1.0,
        hard: 1.5,
        expert: 2.0,
    };
}
```

## Async/Await 模式

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

@ccclass('DataManager')
export class DataManager extends Component {
    // ✅ 优秀：Async/await 用于顺序操作
    public async loadGameData(): Promise<void> {
        try {
            const playerData = await this.fetchPlayerData();
            const levelData = await this.fetchLevelData(playerData.currentLevel);
            await this.initializeGame(playerData, levelData);
        } catch (error) {
            console.error('加载游戏数据失败:', error);
            throw error;
        }
    }

    // ✅ 优秀：Promise.all 用于并行操作
    public async loadAllData(): Promise<void> {
        try {
            const [playerData, configData, assetsData] = await Promise.all([
                this.fetchPlayerData(),
                this.fetchConfigData(),
                this.fetchAssetsData(),
            ]);

            this.initializeWithData(playerData, configData, assetsData);
        } catch (error) {
            console.error('加载数据失败:', error);
            throw error;
        }
    }

    // ✅ 优秀：Promise.allSettled 用于部分失败
    public async loadDataWithFallback(): Promise<void> {
        const results = await Promise.allSettled([
            this.fetchPlayerData(),
            this.fetchConfigData(),
            this.fetchAssetsData(),
        ]);

        results.forEach((result, index) => {
            if (result.status === 'fulfilled') {
                console.log(`数据 ${index} 加载成功:`, result.value);
            } else {
                console.error(`数据 ${index} 加载失败:`, result.reason);
            }
        });
    }

    // ✅ 优秀：async/await 的错误处理
    public async savePlayerData(data: PlayerData): Promise<boolean> {
        try {
            await this.validateData(data);
            await this.uploadData(data);
            return true;
        } catch (error) {
            if (error instanceof ValidationError) {
                console.error('无效数据:', error.message);
            } else if (error instanceof NetworkError) {
                console.error('网络错误:', error.message);
            } else {
                console.error('未知错误:', error);
            }
            return false;
        }
    }
}

// ❌ 差：Promise 链（回调地狱）
public loadGameData(): void {
    this.fetchPlayerData()
        .then(playerData => {
            return this.fetchLevelData(playerData.currentLevel);
        })
        .then(levelData => {
            return this.initializeGame(playerData, levelData); // playerData 不在作用域！
        })
        .catch(error => {
            console.error('加载失败:', error);
        });
}
```

## 总结：现代 TypeScript 清单

**使用这些模式编写更简洁、更易维护的代码：**

- [ ] 使用数组方法（map/filter/reduce）替代手动循环
- [ ] 回调和事件处理使用箭头函数
- [ ] 使用解构简化参数处理
- [ ] 使用展开运算符进行对象/数组操作
- [ ] 使用可选链（?.）安全访问属性
- [ ] 使用空值合并（??）设置默认值
- [ ] 使用类型守卫进行类型安全的收窄
- [ ] 使用工具类型（Partial、Required、Readonly、Pick、Omit、Record）
- [ ] 异步操作使用 Async/await
- [ ] 并行操作使用 Promise.all/allSettled

**现代 TypeScript 使代码更简洁、更易读、更类型安全。**
