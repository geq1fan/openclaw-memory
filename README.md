# OpenClaw Memory

OpenClaw automatic memory management tool. Captures session memories, archives old logs, maintains long-term memory.

## Installation

Send this link to OpenClaw:

```
https://github.com/geq1fan/openclaw-memory
```

OpenClaw will guide you through:
1. Select an agent for memory tasks
2. Configure run frequency
3. Automatically add cron jobs

## Features

| Task | Default Schedule | Function |
|------|-----------------|----------|
| memory-writer | Every 2 hours | Scan sessions -> Write daily files |
| memory-janitor | 4x per day | Compress/archive + Maintain MEMORY.md |

## Installation Flow (Agent Reference)

When user sends this project link, follow these steps:

### 1. Confirm Installation

```
I will install openclaw-memory for you. This tool will:
- Capture session memories every N hours
- Organize memory files multiple times per day

Continue?
```

### 2. Select Agent

First query available agents:

```bash
# Option 1: Read OpenClaw config
cat /root/.openclaw/config.json | jq '.agents[].id'

# Option 2: Use agents_list tool (if available)
```

Then show options:

```
Select an agent for memory tasks:
1. {agent-1}
2. {agent-2}
3. {agent-3}
```

### 3. Configure Schedule

```
Configure run frequency:

Memory Capture (memory-writer):
- Default: every 2 hours
- Customizable (e.g., "every 4 hours")

Memory Maintenance (memory-janitor):
- Default: 4 times per day (3:10, 9:10, 15:10, 21:10)
- Customizable (e.g., "8am and 8pm daily")
```

### 4. Install Files

```bash
mkdir -p /root/.openclaw/workspace/memory/{scripts,weekly,archive}

# Copy files (adjust paths based on actual skill location)
cp scripts/memory-scanner.py /root/.openclaw/workspace/memory/scripts/
cp prompts/writer.md /root/.openclaw/workspace/memory/MEMORY_WRITER_PROMPT.md
cp prompts/janitor.md /root/.openclaw/workspace/memory/MEMORY_JANITOR_PROMPT.md

echo '{"lastRunAtMs":0}' > /root/.openclaw/workspace/memory/.writer-state.json
touch /root/.openclaw/workspace/memory/.janitor-last-run
```

### 5. Add Cron Jobs

**memory-writer:**
```json
{
  "name": "memory-writer",
  "agentId": "<user-selected agent>",
  "enabled": true,
  "sessionTarget": "isolated",
  "wakeMode": "now",
  "schedule": { "kind": "every", "everyMs": 7200000 },
  "payload": {
    "kind": "agentTurn",
    "timeoutSeconds": 120,
    "message": "You are the memory writer. Read memory/MEMORY_WRITER_PROMPT.md and execute. Reply ANNOUNCE_SKIP when done."
  },
  "delivery": { "mode": "none" }
}
```

**memory-janitor:**
```json
{
  "name": "memory-janitor",
  "agentId": "<user-selected agent>",
  "enabled": true,
  "sessionTarget": "isolated",
  "wakeMode": "now",
  "schedule": { "kind": "cron", "expr": "10 3,9,15,21 * * *", "tz": "Asia/Shanghai" },
  "payload": {
    "kind": "agentTurn",
    "message": "Memory maintenance task. 1. Change detection: find /root/.openclaw/workspace/memory/ -maxdepth 1 -name '*.md' -newer /root/.openclaw/workspace/memory/.janitor-last-run. Exit if no changes. 2. If changes exist, read memory/MEMORY_JANITOR_PROMPT.md and execute. 3. touch /root/.openclaw/workspace/memory/.janitor-last-run. Exit silently."
  },
  "delivery": { "mode": "none" }
}
```

### 6. Confirm Installation

```
openclaw-memory installed successfully!

Configuration:
- Agent: {agent}
- Memory Capture: every {N} hours
- Memory Maintenance: {schedule description}

Check status: openclaw cron list
```

## Uninstall

```
Help me uninstall openclaw-memory
```

Agent should:
1. Remove cron jobs: memory-writer, memory-janitor
2. Optionally remove files

## File Structure

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

## License

MIT
