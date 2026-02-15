# openclaw-memory

**An OpenClaw skill for automatic memory management.**

When a user sends you this project link, they want to **install** this skill. Please follow the installation flow below immediately.

---

## What This Does

Automatically captures OpenClaw session memories and maintains long-term memory:
- **memory-writer**: Scans session transcripts every 2 hours → writes to daily files
- **memory-janitor**: Compresses/archives old logs → maintains MEMORY.md + **validates knowledge**

### Knowledge Validation (New)

memory-janitor automatically detects issues in MEMORY.md:

| Issue | Detection |
|-------|-----------|
| ⚠️ Outdated | Config changed, version updated, path moved |
| 🔄 Duplicate | Same info appears multiple times |
| ❓ Orphaned | Isolated names/terms without context |
| ⚡ Conflicting | Contradicts other entries |

Problems are marked as comments in MEMORY.md for user review.

## Installation Flow

**When user sends this project link, execute these steps:**

### Step 1: Confirm Installation

Ask the user:

```
I'll install openclaw-memory for you. It will:
- Capture session memories automatically (every N hours)
- Organize and archive old memory files (daily)

Continue with installation?
```

### Step 2: Select Agent

Query available agents and let user choose:

```bash
# Get agent list
cat /root/.openclaw/config.json | jq '.agents[].id'
```

```
Select an agent for memory tasks:
1. {agent-1}
2. {agent-2}
3. {agent-3}
```

### Step 3: Configure Schedule

Ask user to configure or accept defaults:

```
Configure run frequency:

Memory Capture (memory-writer):
- Default: every 2 hours
- Customizable (e.g., "every 4 hours")

Memory Maintenance (memory-janitor):
- Default: 4 times per day (3:10, 9:10, 15:10, 21:10)
- Customizable (e.g., "8am and 8pm daily")

Use defaults? Or specify custom schedule?
```

### Step 4: Install Files

```bash
mkdir -p /root/.openclaw/workspace/memory/{scripts,weekly,archive}

# Clone repo to get files
cd /tmp && git clone https://github.com/geq1fan/openclaw-memory.git

# Copy files
cp /tmp/openclaw-memory/scripts/memory-scanner.py /root/.openclaw/workspace/memory/scripts/
cp /tmp/openclaw-memory/prompts/writer.md /root/.openclaw/workspace/memory/MEMORY_WRITER_PROMPT.md
cp /tmp/openclaw-memory/prompts/janitor.md /root/.openclaw/workspace/memory/MEMORY_JANITOR_PROMPT.md

# Initialize state
echo '{"lastRunAtMs":0}' > /root/.openclaw/workspace/memory/.writer-state.json
touch /root/.openclaw/workspace/memory/.janitor-last-run
```

### Step 5: Add Cron Jobs

Use the `cron` tool to add two jobs:

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

### Step 6: Confirm

```
✅ openclaw-memory installed successfully!

Configuration:
- Agent: {agent}
- Memory Capture: every {N} hours
- Memory Maintenance: {schedule}

Check status: openclaw cron list
```

---

## Comparison with OpenClaw Built-in Memory

| | OpenClaw Built-in | openclaw-memory |
|---|---|---|
| Session Capture | Relies on agent/compaction flush | Auto-scans session transcripts |
| Archive/Organize | No | daily → weekly → archive |
| Long-term Memory | Manual maintenance | Auto-compresses MEMORY.md |
| Trigger | Pre-compaction | Scheduled cron |

---

## Architecture

```
Session Transcripts ──▶ memory-scanner ──▶ daily files
                                              │
                                              ▼
MEMORY.md ◀── memory-janitor ◀── weekly/archive
```

---

## Uninstall

When user says "uninstall openclaw-memory":
1. Remove cron jobs: `memory-writer`, `memory-janitor`
2. Optionally remove files from `/root/.openclaw/workspace/memory/`

---

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
