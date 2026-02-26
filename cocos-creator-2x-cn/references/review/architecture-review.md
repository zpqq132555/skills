# 架构审查清单（Cocos Creator 2.4）

## 目录

- [组件架构](#组件架构)
- [事件系统架构](#事件系统架构)
- [资源管理架构](#资源管理架构)
- [场景与生命周期](#场景与生命周期)
- [可试玩广告架构](#可试玩广告架构)

---

## 组件架构

### 审查要点

| # | 审查项 | 合格标准 | 严重程度 |
|---|--------|----------|----------|
| A1 | 单一职责 | 每个组件只处理一个职责 | 🔴 高 |
| A2 | 组件通信 | 通过事件或公共 API 通信，不直接访问其他组件的私有成员 | 🔴 高 |
| A3 | 引用获取 | `getComponent` 仅在 `onLoad`/`start` 中调用，结果缓存到成员变量 | 🟡 中 |
| A4 | 节点查找 | `cc.find` / `getChildByName` 仅在初始化时使用，不在 update 中 | 🔴 高 |
| A5 | @property 使用 | 只暴露需要编辑器调整的属性，不暴露内部实现细节 | 🟡 中 |
| A6 | 继承层级 | 组件继承层级不超过 2 层，优先使用组合 | 🟡 中 |
| A7 | 命名规范 | 组件类名与文件名一致，使用 PascalCase | 🟢 低 |

### 代码示例

```typescript
// ✅ 优秀架构：单一职责 + 事件通信
@ccclass
export default class HealthSystem extends cc.Component {
    private currentHealth: number = 100;
    private maxHealth: number = 100;

    // 公共 API
    public takeDamage(amount: number): void {
        this.currentHealth = Math.max(0, this.currentHealth - amount);

        // 通过事件通知其他系统
        this.node.emit("health-changed", this.currentHealth, this.maxHealth);

        if (this.currentHealth <= 0) {
            this.node.emit("entity-died");
        }
    }
}

@ccclass
export default class HealthBar extends cc.Component {
    @property(cc.ProgressBar)
    private bar: cc.ProgressBar = null;

    @property(cc.Node)
    private targetNode: cc.Node = null;

    protected onEnable(): void {
        this.targetNode.on("health-changed", this.onHealthChanged, this);
    }

    protected onDisable(): void {
        this.targetNode.off("health-changed", this.onHealthChanged, this);
    }

    private onHealthChanged(current: number, max: number): void {
        this.bar.progress = current / max;
    }
}

// ❌ 差：上帝组件 + 紧耦合
@ccclass
export default class GodComponent extends cc.Component {
    update(dt: number): void {
        // 一个组件做了所有事情
        this.movePlayer(dt);
        this.checkCollisions();
        this.updateUI();
        this.spawnEnemies(dt);
        this.playSound();
        this.saveGame();
    }
}
```

---

## 事件系统架构

### 审查要点

| # | 审查项 | 合格标准 | 严重程度 |
|---|--------|----------|----------|
| E1 | 事件配对 | `on` 在 `onEnable`，`off` 在 `onDisable` | 🔴 高 |
| E2 | this 绑定 | 使用第三个参数绑定 this，不使用 `.bind()` | 🔴 高 |
| E3 | 事件命名 | 使用常量或枚举定义事件名，不使用魔法字符串 | 🟡 中 |
| E4 | 全局事件 | 全局事件使用单例 EventTarget，不污染 cc.director/cc.game | 🟡 中 |
| E5 | 事件粒度 | 事件携带必要数据，接收方不需要反查发送方 | 🟢 低 |

### 事件名常量化

```typescript
// ✅ 统一事件常量
export const GameEvent = {
    // 游戏流程
    GAME_START: "game:start",
    GAME_OVER: "game:over",
    GAME_PAUSE: "game:pause",
    GAME_RESUME: "game:resume",

    // 玩家
    PLAYER_DAMAGE: "player:damage",
    PLAYER_DEATH: "player:death",
    PLAYER_SCORE: "player:score",

    // UI
    UI_SHOW_PANEL: "ui:show-panel",
    UI_HIDE_PANEL: "ui:hide-panel",

    // 广告（可试玩）
    AD_INSTALL_CLICK: "ad:install-click",
} as const;

// ✅ 使用常量
eventManager.emit(GameEvent.GAME_START);
eventManager.on(GameEvent.PLAYER_SCORE, this.onScoreChanged, this);

// ❌ 差：魔法字符串
eventManager.emit("game_start");
eventManager.on("playerScore", this.onScoreChanged, this);
```

---

## 资源管理架构

### 审查要点

| # | 审查项 | 合格标准 | 严重程度 |
|---|--------|----------|----------|
| R1 | 预加载 | 游戏开始前预加载必要资源，显示加载进度 | 🔴 高 |
| R2 | 引用计数 | 动态加载的资源使用 addRef/decRef 管理 | 🔴 高 |
| R3 | 释放时机 | 场景切换时释放不再需要的资源 | 🔴 高 |
| R4 | 错误处理 | 所有加载回调都处理 err 参数 | 🟡 中 |
| R5 | 路径管理 | 资源路径使用常量定义，不散落在代码中 | 🟡 中 |
| R6 | 持久节点 | 跨场景节点使用 `cc.game.addPersistRootNode` | 🟡 中 |

### 资源路径常量化

```typescript
// ✅ 集中定义资源路径
export const AssetPath = {
    // Prefab
    PREFAB_PLAYER: "prefabs/Player",
    PREFAB_ENEMY: "prefabs/Enemy",
    PREFAB_BULLET: "prefabs/Bullet",
    PREFAB_EFFECT: "prefabs/HitEffect",

    // 音频
    AUDIO_BGM: "audio/bgm_main",
    AUDIO_HIT: "audio/sfx_hit",

    // 图集
    ATLAS_UI: "atlas/ui",
    ATLAS_GAME: "atlas/game",

    // 场景
    SCENE_HOME: "Home",
    SCENE_GAME: "Game",
} as const;
```

---

## 场景与生命周期

### 审查要点

| # | 审查项 | 合格标准 | 严重程度 |
|---|--------|----------|----------|
| S1 | 初始化顺序 | 关键初始化在 `onLoad` 中，依赖其他组件的初始化在 `start` 中 | 🔴 高 |
| S2 | 清理完整 | `onDestroy` 中释放所有资源、清除所有定时器 | 🔴 高 |
| S3 | 场景切换 | 切换前清理旧场景状态，loading 时禁止用户操作 | 🟡 中 |
| S4 | 启动顺序 | 使用 `executionOrder` 控制组件执行顺序（如果需要） | 🟡 中 |

### 生命周期与清理

```typescript
@ccclass
export default class WellManagedComponent extends cc.Component {
    private loadedPrefab: cc.Prefab = null;
    private audioId: number = -1;
    private tweenAction: cc.Tween<cc.Node> = null;

    protected onLoad(): void {
        // ✅ 1. 获取组件引用
        // ✅ 2. 加载动态资源
        cc.resources.load("prefabs/Effect", cc.Prefab, (err, prefab) => {
            if (err) {
                cc.error("加载失败:", err.message);
                return;
            }
            this.loadedPrefab = prefab;
            this.loadedPrefab.addRef();
        });
    }

    protected onEnable(): void {
        // ✅ 3. 注册事件
        this.node.on(cc.Node.EventType.TOUCH_START, this.onTouch, this);
    }

    protected onDisable(): void {
        // ✅ 4. 注销事件
        this.node.off(cc.Node.EventType.TOUCH_START, this.onTouch, this);
    }

    protected onDestroy(): void {
        // ✅ 5. 释放动态加载的资源
        if (this.loadedPrefab) {
            this.loadedPrefab.decRef();
            this.loadedPrefab = null;
        }

        // ✅ 6. 停止所有定时器
        this.unscheduleAllCallbacks();

        // ✅ 7. 停止所有 tween
        cc.Tween.stopAllByTarget(this.node);

        // ✅ 8. 停止音效
        if (this.audioId >= 0) {
            cc.audioEngine.stop(this.audioId);
            this.audioId = -1;
        }
    }

    private onTouch(event: cc.Event.EventTouch): void { }
}
```

---

## 可试玩广告架构

### 审查要点

| # | 审查项 | 合格标准 | 严重程度 |
|---|--------|----------|----------|
| P1 | 包体大小 | 最终构建 < 5MB（理想 < 2MB） | 🔴 高 |
| P2 | 首帧时间 | 3 秒内可交互 | 🔴 高 |
| P3 | DrawCall | 运行时 DrawCall < 15（理想 < 10） | 🔴 高 |
| P4 | 安装按钮 | 全局可点击触发安装，明确的 CTA 按钮 | 🔴 高 |
| P5 | 游戏时长 | 15-30 秒完整体验周期 | 🟡 中 |
| P6 | 无网络依赖 | 所有资源内嵌，不使用远程加载 | 🔴 高 |
| P7 | 平台兼容 | 支持 iOS + Android WebView，无平台特定 API | 🟡 中 |

### 可试玩广告入口模式

```typescript
@ccclass
export default class PlayableEntry extends cc.Component {
    @property(cc.Node)
    private ctaButton: cc.Node = null;

    @property(cc.Node)
    private gameLayer: cc.Node = null;

    private gameTimer: number = 0;
    private readonly GAME_DURATION: number = 20;

    protected onLoad(): void {
        // ✅ 全局触摸拦截（兜底安装跳转）
        this.node.on(cc.Node.EventType.TOUCH_START, this.onGlobalTouch, this);

        // ✅ CTA 按钮
        this.ctaButton.on(cc.Node.EventType.TOUCH_START, this.onInstall, this);
    }

    protected update(dt: number): void {
        this.gameTimer += dt;
        if (this.gameTimer >= this.GAME_DURATION) {
            this.showEndCard();
        }
    }

    private showEndCard(): void {
        // 显示结束画面和安装提示
        this.gameLayer.active = false;
        this.ctaButton.active = true;
    }

    private onInstall(): void {
        // 调用平台安装接口
        if (typeof (window as any).install !== "undefined") {
            (window as any).install();
        } else if (typeof (window as any).openAppStore !== "undefined") {
            (window as any).openAppStore();
        }
    }

    private onGlobalTouch(): void {
        // 可选：特定阶段点击也触发安装
    }

    protected onDestroy(): void {
        this.node.off(cc.Node.EventType.TOUCH_START, this.onGlobalTouch, this);
        this.ctaButton.off(cc.Node.EventType.TOUCH_START, this.onInstall, this);
    }
}
```
