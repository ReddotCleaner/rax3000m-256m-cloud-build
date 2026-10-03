#!/bin/sh
# 复算内核配置 hash 并与官方值比对
# 用法: ./verify.sh
D=$(cd "$(dirname "$0")" && pwd)
OURS=$(grep '=[ym]' "$D/kernel.config.set" | LC_ALL=C sort | md5sum | cut -d' ' -f1)
OFFI=$(cat "$D/vermagic" 2>/dev/null | head -c 64)
echo "ours     = $OURS"
echo "official = $OFFI"
if [ "$OURS" = "$OFFI" ]; then echo "✅ 一致：本配置生成的内核与官方 25.12.2 内核 vermagic 相同（官方 kmod 可直装）"; exit 0; fi
echo "❌ 不一致：不要用这份配置（会导致官方 kmod 装不上）"; exit 1
