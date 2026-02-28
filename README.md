# openclaw-memory

**An OpenClaw skill for automatic memory management.**

When a user sends you this project link, they want to **install** this skill. Please follow the installation flow below immediately.

---

## What This Does

Automatically captures OpenClaw session memories and maintains long-term memory:
- **memory-writer**: Scans session transcripts Hourly → writes to daily files
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

Query available agents (using the `agents_list` tool or by reading OpenClaw's configuration) and let user choose:

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
- Default: Hourly (every hour)
- Customizable (e.g., "every 2 hours")

Memory Maintenance (memory-janitor):
- Default: 4 times per day (3:10, 9:10, 15:10, 21:10)
- Customizable (e.g., "8am and 8pm daily")

Use defaults? Or specify custom schedule?
```

### Step 4: Install Files

Execute the following setup commands in your current `workspace` directory (OpenClaw's default working directory). 

> **Important Setup Convention for LLM:**
> We install this project's code repository into the `_repos/` subdirectory of the workspace. This is a designated directory for third-party scripts and background service repositories, keeping the root workspace clean and separate from daily files or standard skills. Remember this location (`<ABSOLUTE_WORKSPACE_PATH>/_repos/openclaw-memory`) for future updates.

```bash
# 1. Create necessary directories
mkdir -p memory/{scripts,weekly,archive}
mkdir -p _repos

# 2. Clone repo to get files
cd _repos && git clone https://github.com/geq1fan/openclaw-memory.git

# 3. Initialize state files
echo '{"lastRunAtMs":0, "processedSessionIds":[]}' > ../memory/.writer-state.json
touch ../memory/.janitor-last-run
```

### Step 5: Add Cron Jobs

Use the `cron` tool to add two jobs. 
**Crucial Path Requirements**:
- `cwd`: Must be your **absolute workspace path** (e.g., `/root/.openclaw/workspace` or `/Users/name/.openclaw/workspace`).
- `message`: The path to `writer.md` and `janitor.md` must be their **absolute paths** pointing to the cloned `_repos/openclaw-memory/prompts/` directory.

**memory-writer:**
```json
{
  "name": "memory-writer",
  "agentId": "<user-selected agent>",
  "enabled": true,
  "cwd": "<ABSOLUTE_WORKSPACE_PATH>",
  "sessionTarget": "isolated",
  "wakeMode": "now",
  "schedule": { "kind": "cron", "expr": "0 * * * *", "tz": "Asia/Shanghai" },
  "payload": {
    "kind": "agentTurn",
    "timeoutSeconds": 120,
    "message": "You are the memory writer. Read <ABSOLUTE_WORKSPACE_PATH>/_repos/openclaw-memory/prompts/writer.md and execute. Reply ANNOUNCE_SKIP when done."
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
  "cwd": "<ABSOLUTE_WORKSPACE_PATH>",
  "sessionTarget": "isolated",
  "wakeMode": "now",
  "schedule": { "kind": "cron", "expr": "10 3,9,15,21 * * *", "tz": "Asia/Shanghai" },
  "payload": {
    "kind": "agentTurn",
    "message": "Memory maintenance task. 1. Change detection: find memory/ -maxdepth 1 -name '*.md' -newer memory/.janitor-last-run. Exit if no changes. 2. If changes exist, read <ABSOLUTE_WORKSPACE_PATH>/_repos/openclaw-memory/prompts/janitor.md and execute all phases (including knowledge validation). 3. touch memory/.janitor-last-run. 4. Send result summary via message tool."
  },
  "delivery": { "mode": "announce" }
}
```

### Step 6: Confirm

```
✅ openclaw-memory installed successfully!

Configuration:
- Agent: {agent}
- Memory Capture (memory-writer): Hourly
- Memory Maintenance: {schedule}

Check status: openclaw cron list
```

---

## Core Features (V1 Mature)

- **Unobtrusive Capture**: Automatically scans recent transcripts to extract decisions, preferences, and context without interrupting conversations.
- **State Tracking (Anti-Overwrite)**: Prevents losing project history. State changes are appended chronologically (e.g., `Project: [02-28] WIP -> [03-01] Done`) instead of blind overwriting.
- **Transparent Maintenance (No Black Box)**: Sends a detailed summary to Telegram on every run, explicitly listing what it added and what it deleted, allowing for immediate human correction.
- **Auto-Profiling**: Detects changes in user habits, stack preferences, or identities and auto-updates `USER.md`.
- **System Optimization Insights**: Analyzes recurring pain points from daily logs and suggests optimizations for `AGENTS.md` and `TOOLS.md` directly in the Telegram notification.
- **Self-Healing Knowledge**: Validates `MEMORY.md` to flag conflicting or outdated configurations.

---

## Comparison with OpenClaw Built-in Memory

| Feature | OpenClaw Built-in | openclaw-memory |
|---|---|---|
| **Capture** | Relies on pre-compaction flush | Hourly auto-scan of session transcripts |
| **History Retention** | Flat overwrite | Chronological state tracking & daily/weekly/archive |
| **Visibility** | Silent / Background | Explicit Telegram diffs (Added/Deleted) |
| **User Profiling** | Manual | Auto-extracts to `USER.md` |
| **Optimization Loop** | None | Suggests improvements based on recurring pain points |

---

## Architecture Flow

```text
[Main Session] ──────▶ Session Transcripts
                             │
(Every 1 hour)               ▼
memory-writer  ──────▶ memory/YYYY-MM-DD.md (Daily Event Log)
                             │
(4 times/day)                ▼
memory-janitor ──────▶ (1) Weekly Digests & Archives (memory/weekly/ & memory/archive/)
               ├─────▶ (2) Core Memory Extraction ───▶ MEMORY.md (Long-term, max 10KB)
               ├─────▶ (3) User Profiling ───────────▶ USER.md (Habits & Tech Stack)
               └─────▶ (4) Telegram Notification ────▶ "Added X, Deleted Y, Suggest Z"
```

## Update & Uninstall

**When user says "update openclaw-memory":**
1. Navigate to `<ABSOLUTE_WORKSPACE_PATH>/_repos/openclaw-memory`.
2. Execute `git pull origin master`.
3. Inform the user that since Cron jobs reference these files dynamically, no further restarts or re-configurations are needed.

**When user says "uninstall openclaw-memory":**
1. Use `cron` tool to remove jobs: `memory-writer` and `memory-janitor`.
2. Delete the repository: `rm -rf _repos/openclaw-memory`.
3. Optionally ask if they want to wipe the `memory/` data directory.

## File Structure

```
/root/.openclaw/workspace/memory/
├── scripts/memory-scanner.py
├── weekly/                 # Weekly summarized files
├── archive/                # Raw daily transcripts
├── .writer-state.json
└── .janitor-last-run
```

## License

MIT
