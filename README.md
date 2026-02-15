# OpenClaw Memory

自动化的 AI Agent 记忆管理 skill。

## 快速安装

将此链接发送给 OpenClaw：

```
https://github.com/geq1fan/openclaw-memory
```

OpenClaw 会引导你完成安装：
1. 选择用于记忆任务的 agent
2. 配置运行频率
3. 自动添加定时任务

## 功能

- **记忆抓取** - 自动扫描会话记录，提取关键对话
- **记忆整理** - 压缩归档旧记忆，维护长期记忆 (MEMORY.md)
- **用户同步** - 从对话中提取偏好变化，更新 USER.md

## 默认配置

| 任务 | 调度 | 功能 |
|------|------|------|
| memory-writer | 每 2 小时 | 扫描会话 → 写入 daily 文件 |
| memory-janitor | 每天 4 次 | 压缩归档 + 维护 MEMORY.md |

## 手动安装

如果想手动安装，请参考 [SKILL.md](./SKILL.md)。

## 卸载

```
帮我卸载 openclaw-memory skill
```

## 许可证

MIT
