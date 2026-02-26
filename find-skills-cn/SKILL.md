---
name: find-skills-cn
description: 帮助用户在提出诸如“如何做 X”、“寻找处理 X 的技能”、“是否有能够……的技能”之类的问题，或者表达出想要扩展功能的意愿时，发现并安装相应的代理技能。当用户正在寻找可能以可安装技能形式存在的功能时，应使用此技能。
---

# 寻找 Skills

此技能可助您在开放型代理技能生态系统中发现并安装各类技能。

## 何时使用此技能

当用户出现以下情况时，请使用此技能：

- 提问“如何做 X”，其中 X 可能是已有技能可以处理的常见任务
- 说“寻找处理 X 的技能”或“是否有能够处理 X 的技能”
- 提问“你能做 X 吗”，其中 X 是一个特定的能力
- 表达出想要扩展代理能力的意愿
- 想要搜索工具、模板或工作流
- 提到他们希望在特定领域（设计、测试、部署等）获得帮助

## 什么是 Skills CLI？

Skills CLI (`npx skills`) 是开放型代理技能生态系统的包管理工具。技能是模块化的包，通过专门的知识、工作流和工具扩展代理的能力。

**主要命令：**

- `npx skills find [query]` - 交互式或按关键字搜索技能
- `npx skills add <package>` - 从 GitHub 或其他来源安装技能
- `npx skills check` - 检查技能更新
- `npx skills update` - 更新所有已安装的技能

**浏览技能:** https://skills.sh/

## 如何帮助用户寻找技能

### 第一步：了解他们的需求

当用户请求帮助时，识别以下内容：

1. 领域（例如，React、测试、设计、部署）
2. 具体任务（例如，编写测试、创建动画、审查 PR）
3. 该任务是否足够常见，以至于可能存在相应的技能

### 第二步：搜索技能

使用相关查询运行 find 命令：

```bash
npx skills find [query]
```

例如：

- 用户问 "如何让我的 React 应用更快？" → `npx skills find react performance`
- 用户问 "你能帮我审查 PR 吗？" → `npx skills find pr review`
- 用户问 "我需要创建一个变更日志" → `npx skills find changelog`

命令将返回类似的结果：

```
Install with npx skills add <owner/repo@skill>

vercel-labs/agent-skills@vercel-react-best-practices
└ https://skills.sh/vercel-labs/agent-skills/vercel-react-best-practices
```

### 第三步：向用户展示选项

当找到相关技能时，向用户展示以下信息：

1. 技能名称及其功能
2. 用户可以运行的安装命令
3. 在 skills.sh 上了解更多信息的链接

示例响应：

```
I found a skill that might help! The "vercel-react-best-practices" skill provides
React and Next.js performance optimization guidelines from Vercel Engineering.

To install it:
npx skills add vercel-labs/agent-skills@vercel-react-best-practices

Learn more: https://skills.sh/vercel-labs/agent-skills/vercel-react-best-practices
```

### 第四步：提供安装选项

如果用户希望继续，可以为他们安装技能：

```bash
npx skills add <owner/repo@skill> -g -y
```

`-g` 标志表示全局安装（用户级别），`-y` 跳过确认提示。

## 常见技能类别

在搜索时，可以考虑以下常见类别：

| 类别            | 示例查询                                  |
| --------------- | ---------------------------------------- |
| Web 开发        | react, nextjs, typescript, css, tailwind |
| 测试            | testing, jest, playwright, e2e           |
| DevOps          | deploy, docker, kubernetes, ci-cd        |
| 文档            | docs, readme, changelog, api-docs        |
| 代码质量        | review, lint, refactor, best-practices   |
| 设计            | ui, ux, design-system, accessibility     |
| 生产力          | workflow, automation, git                |

## 高效搜索技巧

1. **使用具体的关键词**: "react testing" 比单独使用 "testing" 更好
2. **尝试替代术语**: 如果 "deploy" 不行，试试 "deployment" 或 "ci-cd"
3. **检查热门来源**: 许多技能来自 `vercel-labs/agent-skills` 或 `ComposioHQ/awesome-claude-skills`

## 当未找到技能时

如果没有相关技能存在：

1. 承认没有找到现有技能
2. 提供直接使用你的通用能力来帮助完成任务
3. 建议用户可以使用 `npx skills init` 创建自己的技能

示例：

```
I searched for skills related to "xyz" but didn't find any matches.
I can still help you with this task directly! Would you like me to proceed?

If this is something you do often, you could create your own skill:
npx skills init my-xyz-skill
```
