# 官方内核配置 · ImmortalWrt 25.12.2 · mediatek/filogic · kernel 6.12.103

## 这是什么

ImmortalWrt **25.12.2 官方发布版实际使用的内核配置**（从官方 `config.buildinfo` 编译复现得到）。
用途：做「**官方内核 + 单设备精简包**」固件 —— 把这份配置钉进"只编 cmcc_rax3000m"的编译，
内核 vermagic 就与官方一致，于是**官方 release 源的 `kmod-*` 可以直接 `apk add`**。

## 来源（可复现）

| 项 | 值 |
|---|---|
| 源码 | `immortalwrt/immortalwrt` @ tag **v25.12.2**（feeds 按 commit 锁定）|
| 输入 `.config` | `https://downloads.immortalwrt.org/releases/25.12.2/targets/mediatek/filogic/config.buildinfo` |
| 生成方式 | `make tools/compile toolchain/compile target/linux/compile` |
| 生成时间 | 2026-10-03（GitHub Actions run **37113163588** 阶段A）|
| 校验 | `./verify.sh` |

## 判定规则（来自 OpenWrt 源码）

```make
# include/kernel-defaults.mk:129
grep '=[ym]' $(LINUX_DIR)/.config.set | LC_ALL=C sort | $(MKHASH) md5 > $(LINUX_DIR)/.vermagic
# include/kernel.mk:216
EXTRA_DEPENDS := kernel (=$(LINUX_VERSION)~$(LINUX_VERMAGIC)-r$(LINUX_RELEASE))
```

即 kmod 的兼容串 = **内核配置里所有 `=y`/`=m` 行排序后的 md5**。

## 校验结果

```
本目录 kernel.config.set 复算  ->  b5b7729ffbba3ecdd83f339de8fadfb8
官方 kmods 目录名              ->  6.12.103-1-b5b7729ffbba3ecdd83f339de8fadfb8
=> 逐字节一致 ✅
```

## 文件

| 文件 | 说明 |
|---|---|
| `kernel.config` | 最终内核 `.config`（编译用，218 KB）|
| `kernel.config.set` | 合并后含全部符号的配置（hash 计算用，288 KB）|
| `vermagic` | 兼容串（= 官方 kmods 目录里的 hash）|
| `INFO.txt` | 生成/校验信息 |
| `verify.sh` | 一条命令复算并比对 |

## 用法：钉进单设备编译

```bash
# 先让 OpenWrt 自己生成/准备一次（为了 stamp 文件存在）
LINDIR=$(ls -d build_dir/target-*/linux-mediatek_filogic/linux-6.12.* | head -1)
cp official-kernel-config/kernel.config.set "$LINDIR/.config.set"
cp official-kernel-config/kernel.config     "$LINDIR/.config"
cp official-kernel-config/kernel.config     "$LINDIR/.config.prev"
cp official-kernel-config/vermagic          "$LINDIR/.vermagic"
touch "$LINDIR/.configured"* "$LINDIR/.prepared"*   # 关键：防止 OpenWrt 重新合并内核配置
```

`.github/workflows/build-256m-official-pinned.yml` 默认会直接使用本目录（`use_committed_config=true`），
因此**以后重新编译不需要再跑那 2h54m 的"阶段A"**。
