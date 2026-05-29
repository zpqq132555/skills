# 架构审查 — LayaAir 3.x

> 审查 LayaAir 3.x 项目架构时的检查清单。

---

## 1. 项目结构检查

### ✅ 推荐结构
```
src/
├── Main.ts              # 入口组件脚本（@regClass）
├── config/              # 全局配置
├── manager/             # 单例管理器
├── scene/               # 场景运行时脚本
├── script/              # 通用 Script 组件
├── common/              # 公共工具
└── ui/                  # UI 相关组件
assets/
├── Scene.ls             # 场景文件
├── resources/           # 动态加载资源
├── atlas/               # 图集配置
└── prefab/              # 预制体
```

### 检查项
- [ ] 入口文件使用 `@regClass()` 装饰器
- [ ] 场景文件使用 `.ls` 格式
- [ ] 资源文件放在 `assets/resources/` 下以支持动态加载
- [ ] 预制体放在 `assets/prefab/` 下
- [ ] 脚本按功能分类（manager/scene/script/ui）

---

## 2. 组件脚本检查

### 装饰器
- [ ] 所有 Script 子类都有 `@regClass()`
- [ ] 所有 IDE 可见属性都有 `@property()`
- [ ] `@property` 的 type 与 TypeScript 类型一致
- [ ] 类使用 `export` 导出

### 生命周期
- [ ] `onAwake` 只做一次性初始化
- [ ] `onEnable` + `onDisable` 事件配对
- [ ] `onDestroy` 清理定时器和引用
- [ ] 对象池场景使用 `onEnable` 重置状态（而非 `onAwake`）
- [ ] `onUpdate` 中无临时对象分配

---

## 3. 事件系统检查

- [ ] 所有 `on()` 都有对应的 `off()`
- [ ] 事件注册在 `onEnable`，注销在 `onDisable`
- [ ] `onDestroy` 中用 `offAllCaller(this)` 兜底
- [ ] 不在 `onUpdate` 中注册事件
- [ ] 不使用匿名函数注册事件（无法注销）
- [ ] 自定义事件使用有意义的字符串名称

---

## 4. 资源管理检查

- [ ] 使用 Promise/async-await 加载（而非 Handler）
- [ ] 加载有错误处理（try-catch 或 null 检查）
- [ ] 场景销毁时释放加载的资源
- [ ] 大资源使用加载进度提示
- [ ] 预制体通过 `@property({ type: Laya.Prefab })` 绑定

---

## 5. 性能检查

- [ ] 静态 UI 容器开启 `cacheAs = "bitmap"`
- [ ] 不需要交互的节点 `mouseEnabled = false`
- [ ] 使用 `visible = false` 隐藏节点（而非 `alpha = 0`）
- [ ] 高频对象使用对象池（子弹、特效、敌人）
- [ ] `onUpdate` 中预缓存引用，无每帧 `new` 操作
- [ ] 临时向量 / 矩阵预分配复用
- [ ] 定时器在不需要时及时清理

---

## 6. 单例管理器模式

```typescript
const { regClass } = Laya;

@regClass()
export class GameManager extends Laya.Script {
    private static _instance: GameManager;
    public static get instance(): GameManager { return GameManager._instance; }

    onAwake(): void {
        if (GameManager._instance) {
            this.owner.destroy();
            return;
        }
        GameManager._instance = this;
    }

    onDestroy(): void {
        if (GameManager._instance === this) {
            GameManager._instance = null;
        }
    }
}
```

---

## 7. 场景管理模式

- [ ] 使用 `Laya.Scene.open()` 切换场景
- [ ] 场景参数通过 `onOpened(param)` 接收
- [ ] UI 场景叠加使用 `closeOther=false`
- [ ] 场景间通信通过全局事件总线
- [ ] 场景销毁时执行 `Laya.Scene.gc()`
