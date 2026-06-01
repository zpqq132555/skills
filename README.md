# skills

这是一个给 Codex、Claude 等 AI 编码助手使用的本地技能仓库。

它的作用很简单：把常用的技能说明、项目规则和引擎专项指导放在一个固定位置，方便你在新电脑恢复、跨项目复用，或者和自己的 AI 工作流一起同步管理。

## 这个项目适合谁

- 想把常用 AI 技能统一收纳的人
- 想在新电脑上快速恢复技能目录的人
- 想给多个 AI 工具复用同一套规则的人
- 正在做 Cocos Creator、LayaAir、Unity 等项目，需要中文专项技能说明的人

## 快速开始

### 1. 放到固定目录

推荐把这个仓库放到：

```text
C:\Users\<用户名>\.agents\skills
```

如果你的 `.agents` 目录还没有创建，手动新建即可。

### 2. 按需保留技能目录

仓库里的每个子目录都是一个独立技能。你可以全部保留，也可以只留下自己会用到的部分。

### 3. 只有在你想共用一套规则时，再使用 `AGENTS_BAK.md`

`AGENTS_BAK.md` 可以理解为一份统一维护的“通用规则底稿”。

如果你希望 Codex 或 Claude 读取同一套规则，再把它分发到对应工具的配置位置，例如：

```text
AGENTS_BAK.md -> .codex\AGENTS.md
AGENTS_BAK.md -> .claude\CLAUDE.md
```

具体使用哪种分发方式，可以按你自己的工作流决定。

## 仓库里都有什么

### 根目录文件

| 文件 | 作用 |
|---|---|
| `README.md` | 说明这个仓库怎么用 |
| `AGENTS_BAK.md` | 一份可复用的通用规则底稿，给多个 AI 工具共用 |

### 技能目录

| 目录 | 用途 |
|---|---|
| `cocos-creator-v2/` | Cocos Creator 2.x 开发指导 |
| `cocos-creator-v3/` | Cocos Creator 3.x 开发指导 |
| `code-guard-review-cn/` | 代码审查与结构质量检查 |
| `layaair-v1/` | LayaAir 1.x 开发指导 |
| `layaair-v2/` | LayaAir 2.x 开发指导 |
| `layaair-v3/` | LayaAir 3.x 开发指导 |
| `unity-2022/` | Unity 2022 开发指导 |

## 关于 `link-agents.bat`

这个脚本以前用于把 `AGENTS_BAK.md` 分发到其他工具的配置文件，现在已经从仓库中移除。

如果你仍然需要类似能力，可以选择手动复制配置文件，或使用 [WinLink](https://github.com/zpqq132555/WinLink) 这类专门的链接工具。

## 在新电脑上恢复

1. 把整个 `skills` 目录复制到新电脑的 `C:\Users\<用户名>\.agents\`
2. 如果需要统一规则，按你习惯的方式分发 `AGENTS_BAK.md`
3. 完成，无需再执行额外脚本

## 常见问题

### 一定要全部技能都装上吗？

不需要。这个仓库本质上是你自己的技能集合，按需保留即可。
