# 包体大小优化（<5MB 目标）

## 纹理压缩（影响最大）

**目标：可试玩广告总包体 <5MB**

纹理压缩是影响包体大小的最大因素。为所有平台启用压缩。

### 构建设置配置

```json
// 项目设置 → 构建 → Web Mobile
{
    "textureCompression": {
        "web-mobile": "auto",     // 自动选择最佳压缩
        "web-desktop": "auto",
        "android": "etc1",        // Android 使用 ETC1
        "ios": "pvrtc"            // iOS 使用 PVRTC
    },
    "packAutoAtlas": true,       // 自动生成图集
    "md5Cache": false,           // 禁用以减小输出
    "inlineSpriteFrames": true   // 减少文件数量
}
```

### 纹理尺寸指南

```typescript
// ✅ 优秀：可试玩广告的最佳纹理尺寸

// 角色精灵：最大 512x512（通常 256x256 就够了）
// UI 元素：最大 256x256
// 背景：最大 1024x1024（或使用平铺的小纹理）
// 特效：128x128 或 256x256
// 图标：64x64 或 128x128

// ❌ 错误：纹理尺寸过大
// - 小角色精灵使用 2048x2048
// - 在该显示分辨率下看不到的高分辨率图片
// 根据显示分辨率使用合适的尺寸
```

## 资源优化优先级

### 1. 纹理（包体的 50-60%）

```typescript
// ✅ 优秀：精灵图集配置
// 将多个小纹理合并到单个图集中
// - 角色动画：单个图集
// - UI 元素：单个图集
// - 特效：单个图集

// 自动图集设置（项目设置）：
// - 最大宽度：2048
// - 最大高度：2048
// - 间距：2
// - 允许旋转：true
// - 强制正方形：false

// ❌ 错误：单独的纹理文件
// 每个单独的纹理 = 单独的 HTTP 请求 + 更差的压缩
```

### 2. 音频（包体的 20-30%）

```typescript
// ✅ 优秀：音频优化
// - 格式：MP3 或 OGG（不要用 WAV）
// - 背景音乐：最大 128kbps，短循环（<30 秒）
// - 音效：64kbps，非常短（<2 秒）

// ❌ 错误：未压缩的音频
// - WAV 文件：比压缩格式大 10-20 倍
// - 长音乐轨道：使用短循环
// - 高码率：可试玩广告不需要 320kbps
```

### 3. 代码（包体的 5-10%）

```typescript
// ✅ 优秀：代码压缩
// rollup.config.js 或 webpack.config.js
export default {
    mode: 'production',
    optimization: {
        minimize: true,
        minimizer: [
            new TerserPlugin({
                terserOptions: {
                    compress: {
                        drop_console: true,      // 移除 console.log
                        drop_debugger: true,     // 移除 debugger
                        dead_code: true,         // 移除不可达代码
                        unused: true             // 移除未使用的变量
                    },
                    mangle: { toplevel: true }   // 缩短变量名
                }
            })
        ]
    }
};

// ✅ 优秀：只导入需要的模块
import { Vec3, Node } from 'cc'; // 具体导入

// ❌ 错误：导入整个模块
import * as cc from 'cc'; // 导入所有内容（更大的包体）
```

### 4. 字体（包体的 5-10%）

```typescript
// ✅ 优秀：可试玩广告使用位图字体
// - 将字符预渲染到纹理
// - 只包含需要的字符："0123456789,."
// - 比 TTF 字体小得多

// 创建位图字体：
// 1. 使用 BMFont 工具或在线生成器
// 2. 只包含需要的字符
// 3. 导出为 .fnt + .png
// 4. 导入到 Cocos Creator 作为 BitmapFont

// ❌ 错误：TTF 字体
// - 文件大小较大（数百 KB）
// - 系统字体因平台而异
// - 可试玩广告使用位图字体
```

## 最小包体的构建配置

```json
// 项目设置 → 构建 → Web Mobile

{
    // 包体设置
    "inlineSpriteFrames": true,      // 减少文件数量
    "md5Cache": false,               // 禁用文件名中的 MD5
    "mainBundleCompressionType": "default",
    "mainBundleIsRemote": false,

    // 代码优化
    "debug": false,                  // 禁用调试模式
    "sourceMaps": false,             // 禁用 source maps
    "separateEngine": false,         // 引擎包含在包体中

    // 纹理优化
    "packAutoAtlas": true,           // 自动生成图集
    "textureCompression": "auto",    // 启用压缩

    // 功能排除
    "excludeScenes": [],             // 移除未使用的场景
    "useBuiltinServer": false        // 可试玩广告不需要服务器
}
```

## 删除未使用的资源

```typescript
// ✅ 优秀：定期清理资源

// 1. 使用 Cocos Creator 的"查找引用"功能
// - 右键资源 → 查找引用
// - 未找到引用则删除

// 2. 检查构建输出
// - 每次构建后查看构建文件夹大小
// - 识别最大的文件
// - 删除未使用的资源

// 3. 构建前删除调试资源
// - 测试关卡
// - 调试精灵和纹理
// - 仅开发使用的工具
// - 临时资源

// ❌ 错误：保留所有资源"以防万一"
// - 未使用的纹理增加不必要的大小
// - 开发过程中定期清理
```

## 真实案例：包体分解

```typescript
// 目标：<5MB 可试玩广告包体
// 典型优化后的分解：

// 纹理：2.5MB（50%）
// - 角色精灵：800KB（精灵图集，ETC1 压缩）
// - UI 元素：600KB（精灵图集，ETC1 压缩）
// - 背景：700KB（1024x1024，压缩，或平铺）
// - 特效：400KB（精灵图集，压缩）

// 代码：400KB（8%）
// - Cocos 引擎：200KB（压缩，tree-shaken）
// - 游戏逻辑：200KB（压缩，移除死代码）

// 音频：1.5MB（30%）
// - 背景音乐：1MB（MP3，128kbps，60 秒循环）
// - 音效：500KB（MP3，64kbps，10 个短音效）

// 其他：600KB（12%）
// - 位图字体：200KB（只包含需要的字符）
// - 配置文件：100KB（JSON，压缩）
// - 其他资源：300KB

// 总计：5.0MB（在广告网络限制内）

// ❌ 反面案例：未优化（12MB+）
// - 纹理：8MB（无压缩，单独文件）
// - 音频：3MB（WAV 文件，长轨道）
// - 代码：800KB（无压缩，开发模式）
// - 字体：400KB（TTF 字体）
// 总计：12.2MB（被广告网络拒绝！）
```

## 监控包体大小

```bash
# ✅ 优秀：定期监控大小

# 1. 检查构建输出大小
du -sh build/web-mobile/

# 2. 按资源类型分解
du -sh build/web-mobile/assets/
du -sh build/web-mobile/src/

# 3. 查找最大的文件
find build/web-mobile -type f -exec du -h {} \; | sort -rh | head -20

# 4. 在 CI/CD 中设置大小预算
# 包体 >5MB 时构建失败
# 包体 >4.5MB 时告警（预警阈值）
```

## 延迟加载模式（可选）

```typescript
import { _decorator, Component, resources, Prefab } from 'cc';
const { ccclass } = _decorator;

@ccclass('LazyLoader')
export class LazyLoader extends Component {
    // ✅ 优秀：按需加载关卡
    // 对于多关卡的可试玩广告，只加载当前关卡

    private levelPrefabs: Map<number, Prefab> = new Map();

    public async loadLevel(levelId: number): Promise<void> {
        if (this.levelPrefabs.has(levelId)) {
            return; // 已加载
        }

        const path = `levels/level_${levelId}`;
        return new Promise((resolve, reject) => {
            resources.load(path, Prefab, (err, prefab) => {
                if (err) {
                    reject(err);
                    return;
                }
                this.levelPrefabs.set(levelId, prefab);
                resolve();
            });
        });
    }

    // ✅ 良好：卸载前一关卡
    public async switchLevel(fromLevel: number, toLevel: number): Promise<void> {
        const prevPrefab = this.levelPrefabs.get(fromLevel);
        if (prevPrefab) {
            prevPrefab.decRef();
            this.levelPrefabs.delete(fromLevel);
        }
        await this.loadLevel(toLevel);
    }
}

// ❌ 错误：开始时加载所有关卡
// - 增加初始包体大小
// - 更长的加载时间
// - 只加载第一关需要的内容
```

## 包体优化清单

**🔴 严重（影响最大）：**
- [ ] 启用纹理压缩（auto 或平台特定）
- [ ] 使用精灵图集（合并纹理）
- [ ] 减小纹理尺寸（角色最大 512x512）
- [ ] 压缩音频（MP3/OGG，64-128kbps）
- [ ] 删除未使用的资源

**🟡 重要：**
- [ ] 启用代码压缩（drop_console、死代码移除）
- [ ] 使用位图字体（非 TTF）
- [ ] 生产环境禁用 source maps
- [ ] 导入特定模块（tree shaking）
- [ ] 删除调试/测试资源
