#!/bin/bash

# Enhanced Linux System Optimization Script
# This script optimizes Linux systems for containerized environments like Kubernetes

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Language detection
if [[ "$LANG" == *"zh_CN"* ]]; then
    LANG_MODE="zh"
else
    LANG_MODE="en"
fi

# Function to print messages in both languages
print_msg() {
    local level=$1
    local en_msg=$2
    local zh_msg=$3
    
    case $level in
        "info")
            if [ "$LANG_MODE" = "zh" ]; then
                echo -e "${GREEN}[INFO] $zh_msg${NC}"
            else
                echo -e "${GREEN}[INFO] $en_msg${NC}"
            fi
            ;;
        "success")
            if [ "$LANG_MODE" = "zh" ]; then
                echo -e "${GREEN}[SUCCESS] $zh_msg${NC}"
            else
                echo -e "${GREEN}[SUCCESS] $en_msg${NC}"
            fi
            ;;
        "error")
            if [ "$LANG_MODE" = "zh" ]; then
                echo -e "${RED}[ERROR] $zh_msg${NC}"
            else
                echo -e "${RED}[ERROR] $en_msg${NC}"
            fi
            ;;
        "warn")
            if [ "$LANG_MODE" = "zh" ]; then
                echo -e "${YELLOW}[WARN] $zh_msg${NC}"
            else
                echo -e "${YELLOW}[WARN] $en_msg${NC}"
            fi
            ;;
    esac
}

print_msg "info" "Starting Linux system optimization..." "开始Linux系统优化..."

# Function to disable firewalld
function disable_firewalld() {
    if systemctl status firewalld | grep Active | grep -q running >/dev/null 2>&1; then
        systemctl stop firewalld >/dev/null 2>&1
        systemctl disable firewalld >/dev/null 2>&1
        print_msg "success" "Firewalld service has been stopped and disabled." "Firewalld服务已停止并禁用。"
    else
        print_msg "info" "Firewalld is not running or not installed." "Firewalld未运行或未安装。"
    fi
}

# Function to disable UFW (Uncomplicated Firewall)
function disable_ufw() {
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            ufw --force disable >/dev/null 2>&1
            print_msg "success" "UFW has been disabled." "UFW已被禁用。"
        else
            print_msg "info" "UFW is already disabled or inactive." "UFW已禁用或未激活。"
        fi
    else
        print_msg "info" "UFW is not installed on this system." "系统未安装UFW。"
    fi
}

# Function to disable SELinux
function disable_selinux() {
    if command -v getenforce >/dev/null 2>&1; then
        current_status=$(getenforce)
        if [ "$current_status" = "Enforcing" ] || [ "$current_status" = "Permissive" ]; then
            # Temporarily disable SELinux
            setenforce 0 >/dev/null 2>&1
            print_msg "success" "SELinux has been temporarily disabled." "SELinux已临时禁用。"
            
            # Permanently disable SELinux
            if [ -f /etc/selinux/config ]; then
                sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
                print_msg "success" "SELinux has been permanently disabled. Reboot required for full effect." "SELinux已永久禁用。需要重启系统才能完全生效。"
            fi
        else
            print_msg "info" "SELinux is already disabled." "SELinux已禁用。"
        fi
    else
        print_msg "info" "SELinux is not installed on this system." "系统未安装SELinux。"
    fi
}

# Function to disable swap
function disable_swap() {
    if swapoff -a; then
        sed -i '/swap/s/^/#/' /etc/fstab
        print_msg "success" "Swap has been disabled." "交换分区已禁用。"
    else
        print_msg "info" "No swap found or swap already disabled." "未发现交换分区或交换分区已禁用。"
    fi
}

# Function to check kernel version
function check_kernel_version() {
    print_msg "info" "Checking kernel version..." "检查内核版本..."
    current_kernel=$(uname -r)
    kernel_version=$(echo $current_kernel | awk -F. '{print $1}')
    
    print_msg "info" "Current kernel version: $current_kernel" "当前内核版本: $current_kernel"
    
    if [ "$kernel_version" -lt "4" ]; then 
        print_msg "warn" "Kernel version must be higher than 4.0. Please upgrade the kernel to 4.0+ as soon as possible." "内核版本必须高于4.0。请尽快升级内核至4.0+版本。"
        print_msg "warn" "Some containerization features may not work properly with kernel < 4.0" "内核版本低于4.0可能导致某些容器化功能无法正常工作"
    else
        print_msg "success" "Kernel version is compatible (>= 4.0)." "内核版本兼容 (>= 4.0)。"
    fi
}

# Function to optimize Linux kernel parameters
function optimize_linux() {
    print_msg "info" "Optimizing kernel parameters..." "优化内核参数..."
    
    cat > /etc/sysctl.conf << EOF
# Network bridge settings for container networking
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
net.ipv4.conf.all.forwarding=1

# Neighbor table settings
net.ipv4.neigh.default.gc_thresh1=4096
net.ipv4.neigh.default.gc_thresh2=6144
net.ipv4.neigh.default.gc_thresh3=8192
net.ipv4.neigh.default.gc_interval=60
net.ipv4.neigh.default.gc_stale_time=120

# Performance monitoring (reference: https://github.com/prometheus/node_exporter#disabled-by-default)
kernel.perf_event_paranoid=-1

# Sysctls for k8s node configuration
net.ipv4.tcp_slow_start_after_idle=0
net.core.rmem_max=16777216
fs.inotify.max_user_watches=524288
kernel.softlockup_all_cpu_backtrace=1
kernel.softlockup_panic=0
kernel.watchdog_thresh=30

# File system limits
fs.file-max=2097152
fs.inotify.max_user_instances=8192
fs.inotify.max_queued_events=16384
vm.max_map_count=262144
fs.may_detach_mounts=1

# Network performance tuning
net.core.netdev_max_backlog=16384
net.ipv4.tcp_wmem=4096 12582912 16777216
net.core.wmem_max=16777216
net.core.somaxconn=32768
net.ipv4.tcp_max_syn_backlog=8096
net.ipv4.tcp_rmem=4096 12582912 16777216

# Disable IPv6 (if not needed)
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1

# Memory and debugging settings
kernel.yama.ptrace_scope=0
vm.swappiness=0
kernel.core_uses_pid=1

# Security settings
net.ipv4.conf.default.accept_source_route=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.promote_secondaries=1
net.ipv4.conf.all.promote_secondaries=1

# File system protection
fs.protected_hardlinks=1
fs.protected_symlinks=1

# Source route verification (see https://help.aliyun.com/knowledge_detail/39428.html)
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.default.arp_announce=2
net.ipv4.conf.lo.arp_announce=2
net.ipv4.conf.all.arp_announce=2

# TCP optimization (see https://help.aliyun.com/knowledge_detail/41334.html)
net.ipv4.tcp_max_tw_buckets=5000
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_synack_retries=2
kernel.sysrq=1
EOF

    # Apply sysctl settings
    sysctl -p >/dev/null 2>&1
    print_msg "success" "Kernel parameters optimized successfully." "内核参数优化成功。"
}

# Function to optimize system limits
function optimize_limits() {
    print_msg "info" "Optimizing system limits..." "优化系统限制..."
    
    cat > /etc/security/limits.conf <<EOF

# Increased file descriptor limits for containerized workloads
* soft nofile 1024000
* hard nofile 1024000
* soft nproc 1024000
* hard nproc 1024000
EOF

    print_msg "success" "System limits optimized successfully." "系统限制优化成功。"
}





# Main execution
print_msg "info" "========================================" "========================================"
print_msg "info" "Linux System Optimization Script" "Linux系统优化脚本"
print_msg "info" "========================================" "========================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_msg "error" "This script must be run as root. Please use sudo." "此脚本必须以root权限运行，请使用sudo。"
    exit 1
fi

# Execute optimization functions
disable_firewalld
disable_ufw
disable_selinux
disable_swap
check_kernel_version
optimize_linux
optimize_limits

print_msg "info" "========================================" "========================================"
print_msg "success" "System optimization completed!" "系统优化完成！"
print_msg "info" "========================================" "========================================"
print_msg "warn" "Please reboot the system to ensure all changes take effect." "请重启系统以确保所有更改生效。"
print_msg "warn" "Especially important for SELinux changes to be fully applied." "特别是SELinux更改需要重启才能完全生效。"