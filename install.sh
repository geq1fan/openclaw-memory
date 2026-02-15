#!/bin/bash
set -e

WORKSPACE="/root/.openclaw/workspace"
MEMORY_DIR="$WORKSPACE/memory"
SCRIPTS_DIR="$MEMORY_DIR/scripts"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🦞 OpenClaw Memory Installer"
echo "=============================="

# 检查 OpenClaw workspace 是否存在
if [ ! -d "$WORKSPACE" ]; then
    echo "❌ OpenClaw workspace 不存在: $WORKSPACE"
    echo "   请确保 OpenClaw 已正确安装"
    exit 1
fi

# 创建目录结构
echo "📁 创建目录结构..."
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$MEMORY_DIR/weekly"
mkdir -p "$MEMORY_DIR/archive"

# 复制脚本
echo "📝 复制脚本文件..."
cp "$REPO_DIR/scripts/memory-scanner.py" "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR/memory-scanner.py"

# 复制 prompt 文件
echo "📄 复制 prompt 文件..."
cp "$REPO_DIR/prompts/writer.md" "$MEMORY_DIR/MEMORY_WRITER_PROMPT.md"
cp "$REPO_DIR/prompts/janitor.md" "$MEMORY_DIR/MEMORY_JANITOR_PROMPT.md"

# 创建初始状态文件（如果不存在）
if [ ! -f "$MEMORY_DIR/.writer-state.json" ]; then
    echo '{"lastRunAtMs":0}' > "$MEMORY_DIR/.writer-state.json"
fi

# 创建 janitor 运行标记文件
touch "$MEMORY_DIR/.janitor-last-run"

echo "✅ 文件安装完成"
echo ""

# 注册 cron job
echo "⏰ 注册定时任务..."

# 读取 cron 配置
WRITER_CRON=$(cat "$REPO_DIR/cron/openclaw.json" | python3 -c "import json,sys; jobs=json.load(sys.stdin)['jobs']; writer=[j for j in jobs if j['name']=='memory-writer'][0]; print(json.dumps(writer))")
JANITOR_CRON=$(cat "$REPO_DIR/cron/openclaw.json" | python3 -c "import json,sys; jobs=json.load(sys.stdin)['jobs']; janitor=[j for j in jobs if j['name']=='memory-janitor'][0]; print(json.dumps(janitor))")

# 检查是否已存在
EXISTING_WRITER=$(openclaw cron list --json 2>/dev/null | python3 -c "import json,sys; jobs=json.load(sys.stdin).get('jobs',[]); print('1' if any(j.get('name')=='memory-writer' for j in jobs) else '0')" 2>/dev/null || echo "0")
EXISTING_JANITOR=$(openclaw cron list --json 2>/dev/null | python3 -c "import json,sys; jobs=json.load(sys.stdin).get('jobs',[]); print('1' if any(j.get('name')=='memory-janitor' for j in jobs) else '0')" 2>/dev/null || echo "0")

if [ "$EXISTING_WRITER" = "1" ]; then
    echo "   memory-writer 已存在，跳过"
else
    echo "$WRITER_CRON" | openclaw cron add - 2>/dev/null || echo "   ⚠️  无法通过 CLI 添加 memory-writer，请手动配置"
fi

if [ "$EXISTING_JANITOR" = "1" ]; then
    echo "   memory-janitor 已存在，跳过"
else
    echo "$JANITOR_CRON" | openclaw cron add - 2>/dev/null || echo "   ⚠️  无法通过 CLI 添加 memory-janitor，请手动配置"
fi

echo ""
echo "🎉 安装完成！"
echo ""
echo "定时任务："
echo "  - memory-writer: 每 2 小时抓取会话记忆"
echo "  - memory-janitor: 每天 4 次整理记忆文件"
echo ""
echo "查看状态: openclaw cron list"
