#!/bin/sh
WORKDIR="/etc/hosts.d"
[ -d "$WORKDIR" ] || mkdir -p "$WORKDIR"
URL="https://raw.hellogithub.com/hosts"
TEMP_FILE="$WORKDIR/hosts_github520.tmp"
FINAL_FILE="$WORKDIR/hosts_github520"

echo "[$(date)] >>> 开始执行 GitHub520 Hosts 维护任务 <<<"

echo "[$(date)] 正在检查并安全锚定 Dnsmasq UCI 配置..."
if ! uci get dhcp.@dnsmasq[0].addnhosts 2>/dev/null | grep -q "$FINAL_FILE"; then
    uci add_list dhcp.@dnsmasq[0].addnhosts="$FINAL_FILE"
    uci commit dhcp
fi

echo "[$(date)] 正在下载最新的 GitHub520 数据..."
if wget -q -O "$TEMP_FILE" "$URL"; then
    VALID_LINES=$(grep -c '^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' "$TEMP_FILE")
    if [ -s "$TEMP_FILE" ] && [ "$VALID_LINES" -gt 10 ]; then
        if ! cmp -s "$TEMP_FILE" "$FINAL_FILE"; then
            mv "$TEMP_FILE" "$FINAL_FILE"
            /etc/init.d/dnsmasq reload
            echo "[$(date)] 成功：Hosts 已更新 ($VALID_LINES 条映射)，Dnsmasq 已平滑热重载。"
        else
            echo "[$(date)] 提示：本地 Hosts 已是最新，跳过覆盖。"
            rm -f "$TEMP_FILE"
        fi
    else
        echo "[$(date)] 错误：下载内容不合法，放弃更新。"
        rm -f "$TEMP_FILE"
    fi
else
    echo "[$(date)] 错误：下载失败，网络请求超时。"
    rm -f "$TEMP_FILE"
fi
echo "[$(date)] >>> 维护任务结束 <<<"
