#!/bin/bash

# anytls 一键安装脚本 (Ubuntu 24位)

set -e

echo "======================================"
echo "anytls 一键安装脚本 (Ubuntu 24位)"
echo "======================================"
echo ""

# 检测系统架构
ARCH=$(uname -m)
echo "✓ 检测到系统架构: $ARCH"

# 根据架构选择下载链接
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    DOWNLOAD_URL="https://github.com/anytls/anytls-go/releases/download/v0.0.11/anytls_0.0.11_linux_arm64.zip"
    ZIP_FILE="anytls_0.0.11_linux_arm64.zip"
    echo "✓ 将使用 ARM64 版本"
elif [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
    DOWNLOAD_URL="https://github.com/anytls/anytls-go/releases/download/v0.0.11/anytls_0.0.11_linux_amd64.zip"
    ZIP_FILE="anytls_0.0.11_linux_amd64.zip"
    echo "✓ 将使用 AMD64 版本"
else
    echo "✗ 错误: 不支持的架构 $ARCH"
    exit 1
fi

# 创建目录
echo ""
echo "1. 创建工作目录..."
if [ ! -d "anytls" ]; then
    mkdir -p anytls
    echo "✓ anytls 目录已创建"
else
    echo "✓ anytls 目录已存在"
fi

cd anytls

# 下载 anytls
echo ""
echo "2. 下载 anytls..."
if [ ! -f "$ZIP_FILE" ]; then
    wget -q --show-progress "$DOWNLOAD_URL" || wget "$DOWNLOAD_URL"
    echo "✓ 下载完成"
else
    echo "✓ $ZIP_FILE 已存在，跳过下载"
fi

# 检查并安装 unzip
echo ""
echo "3. 检查依赖..."
if ! command -v unzip &> /dev/null; then
    echo "  安装 unzip..."
    sudo apt update -qq && sudo apt install -y unzip > /dev/null 2>&1
    echo "✓ unzip 安装完成"
else
    echo "✓ unzip 已安装"
fi

# 解压文件
echo ""
echo "4. 解压安装包..."
if [ ! -f "anytls-server" ]; then
    unzip -o -q "$ZIP_FILE" 2>/dev/null || unzip -o "$ZIP_FILE"
    chmod +x anytls-server
    echo "✓ 解压完成并设置权限"
else
    echo "✓ anytls-server 已存在，跳过解压"
fi

# 检查 screen 是否安装
echo ""
echo "5. 检查 screen..."
if ! command -v screen &> /dev/null; then
    echo "  安装 screen..."
    sudo apt install -y screen > /dev/null 2>&1
    echo "✓ screen 安装完成"
else
    echo "✓ screen 已安装"
fi

# 检查并停止现有进程
echo ""
echo "6. 检查现有进程..."
if pgrep -f "anytls-server" > /dev/null 2>&1; then
    echo "⚠  anytls-server 已在运行"
    read -p "   是否要重新启动? (y/n): " answer
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        pkill -f "anytls-server" 2>/dev/null
        sleep 1
        echo "✓ 已停止现有进程"
    else
        echo "✓ 保持现有进程运行"
        exit 0
    fi
else
    echo "✓ 无现有进程"
fi

# 启动 anytls
echo ""
echo "7. 启动 anytls-server..."
screen -dmS anytls ./anytls-server -l 0.0.0.0:5443 -p dandan0x1
sleep 2

# 启动 anytls
echo ""
echo "8. 启动 bbr..."
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
lsmod | grep bbr

# 验证启动结果
echo ""
echo "======================================"
if pgrep -f "anytls-server" > /dev/null 2>&1; then
    echo "✓ anytls 安装并启动成功!"
    echo ""
    echo "服务器信息:"
    echo "  监听地址: 0.0.0.0:5443"
    echo "  访问地址: https://$(hostname -I | awk '{print $1}'):5443"
    echo "  本地访问: https://127.0.0.1:5443"
    echo "  访问密码: dandan0x1"
    echo ""
    echo "管理命令:"
    echo "  查看会话: screen -r anytls"
    echo "  分离会话: 按 Ctrl+A 然后按 D"
    echo "  停止服务: pkill -f anytls-server"
else
    echo "✗ 启动失败，请检查错误信息"
    exit 1
fi
echo "======================================"

