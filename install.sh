#!/bin/bash
# OpenClaw Memory 命令行安装脚���
# 推荐方式：发送 README 链接给 OpenClaw，由 agent 引导安装

set -e

WORKSPACE="/root/.openclaw/workspace"
MEMORY_DIR="$WORKSPACE/memory"
SCRIPTS_DIR="$MEMORY_DIR/scripts"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🦞 OpenClaw Memory Installer"
echo "=============================="
echo ""

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

# 复制文件
echo "📝 复制文件..."
cp "$REPO_DIR/scripts/memory-scanner.py" "$SCRIPTS_DIR/"
cp "$REPO_DIR/prompts/writer.md" "$MEMORY_DIR/MEMORY_WRITER_PROMPT.md"
cp "$REPO_DIR/prompts/janitor.md" "$MEMORY_DIR/MEMORY_JANITOR_PROMPT.md"

# 创建初始状态文件
if [ ! -f "$MEMORY_DIR/.writer-state.json" ]; then
    echo '{"lastRunAtMs":0}' > "$MEMORY_DIR/.writer-state.json"
fi
touch "$MEMORY_DIR/.janitor-last-run"

echo ""
echo "✅ 文件安装完成！"
echo ""
echo "⏰ 下一步：添加定时任务"
echo ""
echo "请在 OpenClaw 主会话中执行："
echo "  '帮我配置 openclaw-memory 的定时任务'"
echo ""
echo "或手动添加："
echo "  参考 SKILL.md 中的 cron 配置"
