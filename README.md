# OpenClaw Memory

自动化的 AI Agent 记忆管理工具。让 OpenClaw 拥��长期记忆，跨会话保持上下文。

## 功能

- **记忆抓取** - 自动扫描 OpenClaw 会话记录，提取关键对话写入 daily 文件
- **记忆整理** - 自动压缩、归档旧记忆，维护高信噪比的长期记忆 (MEMORY.md)
- **用户同步** - 从对话中提取用户偏好变化，自动更新 USER.md

## 快速安装

```bash
# 1. 克隆到 OpenClaw workspace
cd /root/.openclaw/workspace/_repos
git clone https://github.com/geq1fan/openclaw-memory.git
cd openclaw-memory

# 2. 运行安装脚本
./install.sh
```

安装完成后，OpenClaw 会自动：
- 每 2 小时抓取一次会话记忆
- 每天整理一次记忆文件（压缩、归档、同步）

## 手动安装

如果不想用安装脚本，可以手动执行：

```bash
# 1. 复制脚本
cp scripts/memory-scanner.py /root/.openclaw/workspace/memory/scripts/

# 2. 复制 prompt 文件
cp prompts/*.md /root/.openclaw/workspace/memory/

# 3. 创建目录结构
mkdir -p /root/.openclaw/workspace/memory/{weekly,archive}

# 4. 添加 cron job (需要 OpenClaw 网关 API)
# 参见 cron/openclaw.json 中的配置
```

## 文件结构

安装后的目录结构：

```
/root/.openclaw/workspace/memory/
├── scripts/
│   └── memory-scanner.py    # 会话扫描脚本
├── weekly/                   # 周度摘要
├── archive/                  # 归档的 daily 文件
├── MEMORY_WRITER_PROMPT.md  # 记忆抓取员指令
├── MEMORY_JANITOR_PROMPT.md # 记忆整理员指令
└── .writer-state.json       # 抓取游标状态
```

## Cron 任务

安装后会创建两个定时任务：

| 任务 | 调度 | 功能 |
|------|------|------|
| memory-writer | 每 2 小时 | 扫描会话 → 写入 daily 文件 |
| memory-janitor | 每天 4 次 (3:10, 9:10, 15:10, 21:10) | 压缩归档 + 维护 MEMORY.md |

## 卸载

```bash
# 删除 cron job
openclaw cron remove memory-writer
openclaw cron remove memory-janitor

# 删除文件 (可选)
rm -rf /root/.openclaw/workspace/memory/scripts/memory-scanner.py
rm -f /root/.openclaw/workspace/memory/MEMORY_WRITER_PROMPT.md
rm -f /root/.openclaw/workspace/memory/MEMORY_JANITOR_PROMPT.md
```

## 自定义

### 修改抓取频率

编辑 cron 配置：

```bash
openclaw cron update memory-writer --schedule '{"kind":"every","everyMs":3600000}'
```

### 修改整理时间

```bash
openclaw cron update memory-janitor --schedule '{"kind":"cron","expr":"0 4,10,16,22 * * *","tz":"Asia/Shanghai"}'
```

## 许可证

MIT
