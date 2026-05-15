# .agents/skills

共享的 AI 编码技能库和配置同步工具。请放置到`C:\Users\<用户名>\.agents\`下

## 目录结构

```
skills/
├── AGENTS_BAK.md          # 全局 AGENTS 配置文件（主文件）
├── link-agents.bat        # 一键创建硬链接（双击即可）
│
├── cocos-creator-2x-cn/
├── cocos-creator-3x-cn/
├── code-guard-review-cn/
├── layaair-1x-cn/
├── layaair-2x-cn/
├── layaair-3x-cn/
└── unity-2022-cn/
```

## link-agents.bat 是什么

`.codex\AGENTS.md` 和 `.claude\CLAUDE.md` 均为 `AGENTS_BAK.md` 的**硬链接**，指向同一份文件。

双击 `link-agents.bat` 会在用户根目录自动创建这两个硬链接：

```
AGENTS_BAK.md (主文件)
   ├── .codex\AGENTS.md   (硬链接 ←→)
   └── .claude\CLAUDE.md (硬链接 ←→)
```

修改任意一个文件，三个位置同步生效。

##在新电脑上恢复

1. 将整个 `.agents` 文件夹拷贝到新电脑的用户目录 `C:\Users\<用户名>\`
2. 双击 `C:\Users\<用户名>\.agents\skills\link-agents.bat`
3. 完成。两个硬链接自动创建。

> 注意：硬链接只能在**同一磁盘分区**内创建，跨盘无效。

## 文件说明

| 文件 | 用途 |
|---|---|
| `AGENTS_BAK.md` | 全局 AGENTS 规则，Codex/Claude 共享 |
| `link-agents.bat` | 硬链接创建脚本，修复后直接双击运行 |
| `cocos-creator-*/` | Cocos Creator 各版本中文注释规范 |
| `unity-2022-cn/` | Unity 2022 中文注释规范 |
| `code-guard-review-cn/` | CodeGuard 代码审查规范 |
| `layaair-*/` | LayaAir 各版本规范 |

