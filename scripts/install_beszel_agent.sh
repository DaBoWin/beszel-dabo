#!/bin/bash

# 默认值
DEFAULT_PORT="45876"
DEFAULT_KEY="ssh-ed25519 A"
DEFAULT_AGENT_PATH="/root/docker/beszel"
DEFAULT_AGENT_EXEC="$DEFAULT_AGENT_PATH/beszel-agent"

# 交互式输入端口、SSH Key 和安装路径
echo "Enter the port (default is $DEFAULT_PORT):"
read -r PORT
PORT=${PORT:-$DEFAULT_PORT}  # 如果没有输入，使用默认值
echo "Press Enter to continue..."
read -r

echo "Enter the SSH Key (default is $DEFAULT_KEY):"
read -r KEY
KEY=${KEY:-$DEFAULT_KEY}  # 如果没有输入，使用默认值
echo "Press Enter to continue..."
read -r

echo "Enter the agent installation path (default is $DEFAULT_AGENT_PATH):"
read -r AGENT_PATH
AGENT_PATH=${AGENT_PATH:-$DEFAULT_AGENT_PATH}  # 如果没有输入，使用默认值
echo "Press Enter to continue..."
read -r

# 设置 Agent 执行路径
AGENT_EXEC="$AGENT_PATH/beszel-agent"

# 检查并创建 Agent 安装路径
echo "Checking if agent path exists: $AGENT_PATH"
if [ ! -d "$AGENT_PATH" ]; then
  echo "Directory $AGENT_PATH does not exist. Creating it..."
  mkdir -p "$AGENT_PATH"  # 创建目录
  if [ $? -eq 0 ]; then
    echo "Directory $AGENT_PATH created successfully."
  else
    echo "Failed to create directory $AGENT_PATH. Exiting."
    exit 1
  fi
fi

# 下载 Beszel Agent
echo "Downloading Beszel Agent..."
curl -sL "https://github.com/henrygd/beszel/releases/latest/download/beszel-agent_$(uname -s)_$(uname -m | sed 's/x86_64/amd64/' | sed 's/armv7l/arm/' | sed 's/aarch64/arm64/').tar.gz" | tar -xz -O beszel-agent | tee ./beszel-agent >/dev/null && chmod +x beszel-agent
mv beszel-agent $AGENT_EXEC

# 设置文件执行权限
echo "Setting execute permissions for $AGENT_EXEC..."
chmod +x $AGENT_EXEC

# 创建 systemd 服务文件
echo "Creating systemd service file..."
cat <<EOF > /etc/systemd/system/beszel-agent.service
[Unit]
Description=Beszel Agent
After=network.target

[Service]
Environment="PORT=$PORT"  # 端口
Environment="KEY=$KEY"  # SSH Key
ExecStart=$AGENT_EXEC  # Agent 执行路径
Restart=always
User=root
WorkingDirectory=$AGENT_PATH  # 工作目录

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 配置并启动服务
echo "Reloading systemd and starting the service..."
sudo systemctl daemon-reload
sudo systemctl start beszel-agent
sudo systemctl enable beszel-agent

# 检查服务状态
echo "Checking service status..."
sudo systemctl status beszel-agent
