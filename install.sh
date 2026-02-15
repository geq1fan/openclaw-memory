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

echo ""
echo "✅ 文件安装完成！"
echo ""
echo "⏰ 下一步：注册定时任务"
echo ""
echo "请将以下内容发送给 OpenClaw（在主会话中）："
echo ""
echo "---"
echo "帮我添加两个 cron job，配置如下："
cat "$REPO_DIR/cron/openclaw.json"
echo "---"
echo ""
echo "或者手动添加："
echo "  1. 读取 cron/openclaw.json"
echo "  2. 在 OpenClaw 主会话中说：'帮我添加这两个 cron job'"
