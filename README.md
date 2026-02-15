# OpenClaw Memory

自动化的 OpenClaw 记忆管理工具。安装后自动抓取会话记忆、整理归档、维护长期记忆。

## 安装

将此链接发送给 OpenClaw：

```
https://github.com/geq1fan/openclaw-memory
```

OpenClaw 会引导你完成配置：
1. 选择执行记忆任务的 agent
2. 设置运行频率
3. 自动添加定时任务

## 功能

| 任务 | 默认调度 | 功能 |
|------|---------|------|
| memory-writer | 每 2 小时 | 扫描会话 → 写入 daily 文件 |
| memory-janitor | 每天 4 次 | 压缩归档 + 维护 MEMORY.md |

## 安装流程（Agent 参考）

当用户发送此项目链接时，按以下步骤执行：

### 1. 确认安装

```
我将为你安装 openclaw-memory。这个工具会：
- 每 N 小时自动抓取会话记忆
- 每天多次整理记忆文件

是否继续？
```

### 2. 选择 Agent

```
请选择执行记忆任务的 agent：
1. kimi-agent（推荐）
2. glm-agent
3. gpt-agent
4. 其他（输入 agent id）
```

### 3. 配置运行时间

```
配置运行频率：

记忆抓取 (memory-writer)：
- 默认：每 2 小时
- 可自定义（如 "每 4 小时"）

记忆整理 (memory-janitor)：
- 默认：每天 4 次（3:10, 9:10, 15:10, 21:10）
- 可自定义（如 "每天早 8 点和晚 8 点"）
```

### 4. 安装文件

```bash
mkdir -p /root/.openclaw/workspace/memory/{scripts,weekly,archive}

# 复制文件（根据实际 skill 路径调整）
cp scripts/memory-scanner.py /root/.openclaw/workspace/memory/scripts/
cp prompts/writer.md /root/.openclaw/workspace/memory/MEMORY_WRITER_PROMPT.md
cp prompts/janitor.md /root/.openclaw/workspace/memory/MEMORY_JANITOR_PROMPT.md

echo '{"lastRunAtMs":0}' > /root/.openclaw/workspace/memory/.writer-state.json
touch /root/.openclaw/workspace/memory/.janitor-last-run
```

### 5. 添加 Cron Job

**memory-writer：**
```json
{
  "name": "memory-writer",
  "agentId": "<用户选择的 agent>",
  "enabled": true,
  "sessionTarget": "isolated",
  "wakeMode": "now",
  "schedule": { "kind": "every", "everyMs": 7200000 },
  "payload": {
    "kind": "agentTurn",
    "timeoutSeconds": 120,
    "message": "你是记忆抓取员。读取 memory/MEMORY_WRITER_PROMPT.md 并执行。完成后回复 ANNOUNCE_SKIP。"
  },
  "delivery": { "mode": "none" }
}
```

**memory-janitor：**
```json
{
  "name": "memory-janitor",
  "agentId": "<用户选择的 agent>",
  "enabled": true,
  "sessionTarget": "isolated",
  "wakeMode": "now",
  "schedule": { "kind": "cron", "expr": "10 3,9,15,21 * * *", "tz": "Asia/Shanghai" },
  "payload": {
    "kind": "agentTurn",
    "message": "记忆整理任务。1. 变更检测: find /root/.openclaw/workspace/memory/ -maxdepth 1 -name '*.md' -newer /root/.openclaw/workspace/memory/.janitor-last-run。无变更则结束。2. 有变更则读取 memory/MEMORY_JANITOR_PROMPT.md 并执行。3. touch /root/.openclaw/workspace/memory/.janitor-last-run。静默结束。"
  },
  "delivery": { "mode": "none" }
}
```

### 6. 确认安装

```
✅ openclaw-memory 安装完成！

配置：
- Agent: {agent}
- 记忆抓取: 每 {N} 小时
- 记忆整理: {时间描述}

查看状态: openclaw cron list
```

## 卸载

```
帮我卸载 openclaw-memory
```

Agent 执行：
1. 删除 cron job：memory-writer、memory-janitor
2. 可选删除文件

## 文件结构

```
/root/.openclaw/workspace/memory/
├── scripts/memory-scanner.py
├── weekly/
├── archive/
├── MEMORY_WRITER_PROMPT.md
├── MEMORY_JANITOR_PROMPT.md
├── .writer-state.json
└── .janitor-last-run
```

## 许可证

MIT
