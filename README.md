# RAX3000M NAND 256M Flash 固件云编译

CMCC RAX3000M（NAND 版，**已改 256M Flash**）的 ImmortalWrt 云编译仓库。

- 源码：`immortalwrt/immortalwrt` @ `openwrt-25.12`
- 设备：`cmcc_rax3000m`（MediaTek Filogic MT7981）
- 核心改动：把 ubi 分区从 **114MB 扩大到 250.5MB**

---

## 📁 文件说明

| 文件 | 作用 |
|------|------|
| `.github/workflows/build-rax3000m-256m.yml` | 编译工作流（手动触发，支持 SSH 调试） |
| `diy-part1.sh` | feeds 更新**前**执行：添加第三方源（默认全部注释，按需启用） |
| `diy-part2.sh` | feeds 更新**后**执行：**修改 DTS 分区为 256M** + 其他定制 |
| `rax3000m-256m.config` | 设备配置（`make defconfig` 自动展开成完整 `.config`） |

---

## 🚀 使用步骤

### 1. 创建 GitHub 仓库

新建一个仓库（Public 或 Private 均可，Private 也照样能用 Actions）。

### 2. 上传文件

**方式 A — 网页上传（简单）**

1. 解压本压缩包
2. 打开仓库 → `Add file` → `Upload files`
3. 把 **4 个文件/文件夹**一起拖进去（`.github` 文件夹要一起拖，里面是 workflow）
4. Commit

> ⚠️ 网页拖拽 `.github` 文件夹时确认它带上的是 `workflows/build-rax3000m-256m.yml` 这一层路径。
> 如果拖拽后路径不对，手动 `Add file` → `Create new file`，文件名填
> `.github/workflows/build-rax3000m-256m.yml`，把内容粘进去即可。

**方式 B — git 命令行**

```bash
cd rax3000m-256m-cloud-build
git init
git add .
git commit -m "init: RAX3000M 256M cloud build"
git branch -M main
git remote add origin https://github.com/<你的用户名>/<仓库名>.git
git push -u origin main
```

### 3. 触发编译

仓库 → **Actions** 标签 → 左侧选 `Build RAX3000M 256M Firmware (ImmortalWrt 25.x)`
→ 右侧 **Run workflow** → 选择分支 `main` → Run

- 首次运行需在仓库 **Settings → Actions → General → Workflow permissions**
  选 **Read and write permissions**（下载源码/上传产物需要）
- 编译约 **1-2 小时**（GitHub 免费 runner 6 小时上限，够用）
- 需要手动 menuconfig 调试时，勾选 `ssh` 输入项，会开一个 tmate 会话给你登进去

### 4. 下载固件

编译完成后在 Actions 运行页底部 **Artifacts** 里下载 `rax3000m-256m-immortalwrt-25.12`。

产物主要是：

| 文件 | 用途 |
|------|------|
| `...cmcc_rax3000m-initramfs-recovery.itb` | 过渡系统（U-Boot Web 先刷这个） |
| `...cmcc_rax3000m-squashfs-sysupgrade.itb` | 正式固件（临时系统里刷写） |

---

## 🔧 关键：分区为什么这么改

原厂/默认分区（128M Flash）：

```
partition@580000 {  reg = <0x580000 0x7200000>;  }   /* 114MB */
```

改成 256M Flash：

```
partition@580000 {  reg = <0x580000 0xFA80000>;  }   /* 250.5MB */
```

计算：`0x10000000 (256MB) - 0x580000 (起始偏移) = 0xFA80000`

固定分区占用（bl2 1M + env 0.5M + factory 2M + fip 2M = 5.5M）之后，剩余全部给 ubi。
UBI 自己是 NAND 坏块管理层，不需要额外预留。

`diy-part2.sh` 里**带校验**：sed 替换后如果没匹配上，会直接报错退出编译，
避免上游改格式后"静默失败"编出一个还是 114MB 分区的固件。

---

## ⚠️ 刷机前须知

1. **U-Boot 必须支持 256M 布局**（如 1715173329 的大分区版，支持 stock/expand 切换）。
   用 128M 的 U-Boot 刷 256M 固件会启动失败。
2. **BL2 / FIP 要匹配 256M**，128M 与 256M 不能混用。
3. 刷机流程：

```
① U-Boot Web (192.168.1.1) → 上传 initramfs-recovery.itb → Update
② 重启进临时系统
③ 系统 → 备份/升级 → 上传 sysupgrade.itb
```

4. 刷完验证分区是否生效：

```bash
cat /proc/mtd          # 看各分区大小
df -h | grep overlay   # 看 overlay 可用空间
```

---

## 📝 参考

- [硬路由 OpenWrt 从 23.05 升级到 24.10（RAX3000M 256M）](https://www.cnblogs.com/ReddotCleaner/articles/19120713)
- [1715173329 的 RAX3000M U-Boot（恩山）](https://www.right.com.cn/forum/thread-8328967-1-1.html)
- [ImmortalWrt 源码](https://github.com/immortalwrt/immortalwrt)
