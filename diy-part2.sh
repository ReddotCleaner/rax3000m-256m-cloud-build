#!/bin/bash
# diy-part2.sh — 在更新 feeds 之后执行
# 功能：修改 DTS 分区（适配 256M Flash）+ 可选定制
set -e

# ============================================================
# 【核心】将 ubi 分区从 114MB 改为 250.5MB，适配 256M Flash
# ============================================================
DTS_NAND="target/linux/mediatek/dts/mt7981b-cmcc-rax3000m-nand.dtso"
DTS_FALLBACK="target/linux/mediatek/dts/mt7981b-cmcc-rax3000m.dts"

# 不同分支文件名不同：24.10/25.12 用 .dtso，23.05 用 .dts
if [ -f "$DTS_NAND" ]; then
  DTS="$DTS_NAND"
elif [ -f "$DTS_FALLBACK" ]; then
  echo "⚠️  未找到 $DTS_NAND，回退到 $DTS_FALLBACK"
  DTS="$DTS_FALLBACK"
else
  echo "❌ ERROR: 找不到 RAX3000M 的 DTS 文件，请检查源码分支" >&2
  ls target/linux/mediatek/dts/ | grep -i rax3000 >&2 || true
  exit 1
fi

echo "=== 目标 DTS: $DTS ==="

# 原始 128M Flash:  reg = <0x580000 0x7200000>   (114MB)
# 目标 256M Flash:  reg = <0x580000 0xFA80000>   (250.5MB)
#   计算: 0x10000000(256M) - 0x580000(起始偏移) = 0xFA80000
sed -i 's/reg = <0x580000 0x7200000>;/reg = <0x580000 0xFA80000>;/' "$DTS"

# ---- 校验：替换必须真的生效 ----
# 若上游改了分区定义格式，sed 会"静默失败"，编出来的固件仍是 114MB 分区，
# 刷进去才发现空间没变大。这里直接让编译失败，比编出错误固件安全。
if ! grep -q 'reg = <0x580000 0xFA80000>;' "$DTS"; then
  echo "❌ ERROR: ubi 分区替换失败！" >&2
  echo "    当前文件里的分区定义：" >&2
  grep -n 'partition@580000' -A 4 "$DTS" >&2 || true
  echo "    请检查上游是否修改了 DTS 分区格式。" >&2
  exit 1
fi

echo "=== ✅ ubi 分区已扩大为 250.5MB ==="
grep -A5 'partition@580000' "$DTS"

# ============================================================
# 可选定制（按需取消注释）
# ============================================================

# 修改默认 LAN IP（避免跟光猫/上级路由冲突）
# sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate

# 修改默认主题（需要 feeds 有 argon 主题）
# sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 修改主机名
# sed -i 's/ImmortalWrt/RAX3000M-256M/g' package/base-files/files/bin/config_generate

echo "=== diy-part2.sh 执行完毕 ==="
