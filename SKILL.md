---
name: openclaw-memory
description: "OpenClaw automatic memory management skill. Installs memory capture, archiving, and long-term memory maintenance. Install by sending this skill's README link to OpenClaw, then answer a few questions to configure."
---

## Features

- **Memory Capture** - Automatically scans OpenClaw session transcripts, extracts key conversations to daily files
- **Memory Maintenance** - Compresses and archives old memories, maintains high signal-to-noise MEMORY.md
- **User Sync** - Extracts user preference changes from conversations, updates USER.md

## Installation Flow

When user sends this skill's link or expresses installation intent, follow these steps:

### Step 1: Confirm Installation

```
I will install openclaw-memory skill for you. This skill will:
- Capture session memories every N hours
- Organize memory files multiple times per day (compress, archive, sync)

Continue?
```

### Step 2: Select Agent

```
Choose an agent for memory tasks:
1. kimi-agent (recommended)
2. glm-agent
3. gpt-agent
4. Other (enter agent id)
```

### Step 3: Configure Schedule

```
Configure run frequency:

Memory Capture (memory-writer):
- Default: every 2 hours
- You can enter custom interval (e.g., "every 4 hours", "hourly")

Memory Maintenance (memory-janitor):
- Default: 4 times per day (3:10, 9:10, 15:10, 21:10)
- You can enter custom cron expression or description
```

### Step 4: Install Files

Execute commands to copy files:

```bash
# Create directories
mkdir -p /root/.openclaw/workspace/memory/scripts
mkdir -p /root/.openclaw/workspace/memory/weekly
mkdir -p /root/.openclaw/workspace/memory/archive

# Copy scripts (from skill directory)
cp <skill-dir>/scripts/memory-scanner.py /root/.openclaw/workspace/memory/scripts/
cp <skill-dir>/prompts/writer.md /root/.openclaw/workspace/memory/MEMORY_WRITER_PROMPT.md
cp <skill-dir>/prompts/janitor.md /root/.openclaw/workspace/memory/MEMORY_JANITOR_PROMPT.md

# Create initial state files
echo '{"lastRunAtMs":0}' > /root/.openclaw/workspace/memory/.writer-state.json
touch /root/.openclaw/workspace/memory/.janitor-last-run
```

### Step 5: Add Cron Jobs

Based on user's configuration, use `cron` tool to add two scheduled tasks:

**memory-writer:**
```json
{
  "name": "memory-writer",
  "agentId": "<user-selected agent>",
  "enabled": true,
  "sessionTarget": "isolated",
  "wakeMode": "now",
  "schedule": {
    "kind": "every",
    "everyMs": <user-selected interval, default 7200000>
  },
  "payload": {
    "kind": "agentTurn",
    "timeoutSeconds": 120,
    "message": "You are the memory writer. Read memory/MEMORY_WRITER_PROMPT.md and follow instructions exactly. Reply ANNOUNCE_SKIP when done."
  },
  "delivery": {
    "mode": "none"
  }
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
  "schedule": {
    "kind": "cron",
    "expr": "<user-selected expression, default '10 3,9,15,21 * * *'>",
    "tz": "Asia/Shanghai"
  },
  "payload": {
    "kind": "agentTurn",
    "message": "Memory maintenance task. Steps:\n1. Change detection: find /root/.openclaw/workspace/memory/ -maxdepth 1 -name '*.md' -newer /root/.openclaw/workspace/memory/.janitor-last-run 2>/dev/null | head -10\nIf no changes, exit silently.\n2. If changes exist, read memory/MEMORY_JANITOR_PROMPT.md and execute.\n3. After completion: touch /root/.openclaw/workspace/memory/.janitor-last-run\n4. Exit silently."
  },
  "delivery": {
    "mode": "none"
  }
}
```

### Step 6: Confirm Installation

```
openclaw-memory installed successfully!

Configuration:
- Agent: {agent}
- Memory Capture: every {N} hours
- Memory Maintenance: {schedule description}

Files: /root/.openclaw/workspace/memory/
Check status: openclaw cron list
```

## Uninstall

User can uninstall by saying:

```
Help me uninstall openclaw-memory skill
```

Execute:
1. Remove cron jobs: `memory-writer`, `memory-janitor`
2. Optional: Remove scripts and prompt files from memory directory

## File Structure

```
/root/.openclaw/workspace/memory/
├── scripts/
│   └── memory-scanner.py
├── weekly/
├── archive/
├── MEMORY_WRITER_PROMPT.md
├── MEMORY_JANITOR_PROMPT.md
├── .writer-state.json
└── .janitor-last-run
```

## Cron Tasks

| Task | Default Schedule | Function |
|------|-----------------|----------|
| memory-writer | Every 2 hours | Scan sessions -> Write daily files |
| memory-janitor | 4x per day | Compress/archive + Maintain MEMORY.md |

## Customization

After installation, user can modify:

```
Change memory-writer frequency to every 4 hours
```

Agent should use `cron update` to modify configuration.
