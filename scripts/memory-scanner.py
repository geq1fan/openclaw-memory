#!/usr/bin/env python3
"""
memory-scanner: 扫描所有 OpenClaw agent 的 session transcripts，提取用户/助手对话。
输出 JSON 格式的对话摘要供 memory-writer agent 使用。

用法:
  python3 memory-scanner.py [--since TIMESTAMP_MS] [--min-size 10240]
"""

import json
import os
import sys
import argparse
from datetime import datetime, timezone, timedelta

AGENTS_DIR = "/root/.openclaw/agents"
STATE_FILE = "/root/.openclaw/workspace/memory/.writer-state.json"

def load_state():
    try:
        with open(STATE_FILE) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {"lastRunAtMs": 0, "sessions": {}}

def parse_transcript(filepath):
    """Parse a .jsonl transcript, extract user/assistant messages."""
    messages = []
    session_id = None
    session_ts = None
    
    try:
        with open(filepath, encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    d = json.loads(line)
                except json.JSONDecodeError:
                    continue
                
                msg_type = d.get("type", "")
                
                if msg_type == "session":
                    session_id = d.get("id", "")
                    session_ts = d.get("timestamp", "")
                
                elif msg_type == "message":
                    msg = d.get("message", {})
                    role = msg.get("role", "")
                    timestamp = d.get("timestamp", "")
                    
                    if role == "user":
                        content = msg.get("content", "")
                        if isinstance(content, list):
                            texts = [c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text"]
                            content = " ".join(texts)
                        elif isinstance(content, dict):
                            content = content.get("text", str(content))
                        
                        if content and len(content.strip()) > 0:
                            messages.append({
                                "role": "user",
                                "content": content.strip()[:500],
                                "timestamp": timestamp
                            })
                    
                    elif role == "assistant":
                        content = msg.get("content", "")
                        if isinstance(content, list):
                            texts = []
                            for c in content:
                                if isinstance(c, dict):
                                    if c.get("type") == "text":
                                        texts.append(c.get("text", ""))
                            content = " ".join(texts)
                        elif isinstance(content, dict):
                            content = content.get("text", "")
                        
                        if content and len(content.strip()) > 0:
                            messages.append({
                                "role": "assistant",
                                "content": content.strip()[:500],
                                "timestamp": timestamp
                            })
    except Exception as e:
        return None, str(e)
    
    return {
        "session_id": session_id,
        "session_ts": session_ts,
        "file": os.path.basename(filepath),
        "file_size": os.path.getsize(filepath),
        "message_count": len(messages),
        "user_message_count": sum(1 for m in messages if m["role"] == "user"),
        "messages": messages
    }, None

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--since", type=int, default=0, help="Only scan files modified after this timestamp (ms)")
    parser.add_argument("--min-size", type=int, default=10240, help="Min file size to consider (bytes)")
    parser.add_argument("--max-messages", type=int, default=100, help="Max messages per session to output")
    args = parser.parse_args()
    
    state = load_state()
    since_ms = args.since or state.get("lastRunAtMs", 0)
    
    # 防护：游标不能超过当前时间，避免 agent 写入未来时间戳导致永久跳过
    now_ms = int(datetime.now(timezone.utc).timestamp() * 1000)
    if since_ms > now_ms:
        since_ms = now_ms - 7200000  # 回退 2 小时
    
    if since_ms > 0:
        since_time = since_ms / 1000.0
    else:
        since_time = (datetime.now(timezone.utc) - timedelta(hours=24)).timestamp()
    
    results = []
    scanned = 0
    skipped_small = 0
    skipped_old = 0
    errors = 0
    agents_found = []
    
    if not os.path.isdir(AGENTS_DIR):
        print(json.dumps({"error": f"Agents dir not found: {AGENTS_DIR}"}))
        sys.exit(1)
    
    # Scan all agent directories
    for agent_name in sorted(os.listdir(AGENTS_DIR)):
        sessions_dir = os.path.join(AGENTS_DIR, agent_name, "sessions")
        if not os.path.isdir(sessions_dir):
            continue
        
        agents_found.append(agent_name)
        
        for fname in os.listdir(sessions_dir):
            if not fname.endswith(".jsonl"):
                continue
            
            fpath = os.path.join(sessions_dir, fname)
            fstat = os.stat(fpath)
            
            if fstat.st_size < args.min_size:
                skipped_small += 1
                continue
            
            if fstat.st_mtime < since_time:
                skipped_old += 1
                continue
            
            scanned += 1
            data, err = parse_transcript(fpath)
            
            if err:
                errors += 1
                continue
            
            if data["user_message_count"] == 0:
                continue
            
            # Add agent_id to the result
            data["agent_id"] = agent_name
            data["messages"] = data["messages"][-args.max_messages:]
            results.append(data)
    
    results.sort(key=lambda x: x.get("session_ts", ""))
    
    output = {
        "scan_time": datetime.now(timezone.utc).isoformat(),
        "since_ms": since_ms,
        "agents_scanned": agents_found,
        "stats": {
            "total_files": scanned + skipped_small + skipped_old,
            "scanned": scanned,
            "skipped_small": skipped_small,
            "skipped_old": skipped_old,
            "errors": errors,
            "sessions_with_content": len(results)
        },
        "sessions": results
    }
    
    print(json.dumps(output, ensure_ascii=False, indent=2))

    # 扫描完成后自动更新游标，不再依赖 agent 手动写入
    if scanned > 0 or len(results) == 0:
        new_state = {"lastRunAtMs": now_ms}
        try:
            with open(STATE_FILE, "w") as f:
                json.dump(new_state, f)
        except Exception:
            pass

if __name__ == "__main__":
    main()
