<p align="center">
  <img src="brand/cra-segments-icon.svg" alt="Cra 标志" width="128" height="128">
</p>

<h1 align="center">Cra</h1>

<p align="center">
  一款把标签页放在侧栏里的原生 macOS 浏览器。<br>
  免费、开源，为习惯 Arc 的人保留熟悉的浏览方式。
</p>

<p align="center">
  <a href="https://github.com/VictorKildahl/cra/releases/latest/download/Cra.dmg"><b>下载上游 macOS 版</b></a> ·
  <a href="https://github.com/VictorKildahl/cra/releases/latest/download/Cra-Intel.dmg">Intel Mac 版</a> ·
  <a href="https://apps.apple.com/app/id6834101298">iPhone 版（App Store）</a> ·
  <a href="https://crabrowser.app">官方网站</a> ·
  <a href="https://crabrowser.app/release-notes">更新日志</a> ·
  <a href="https://crabrowser.app/help">使用帮助</a> ·
  <a href="https://discord.gg/nQMSBTgFRy">Discord 社区</a>
</p>

<p align="center">
  <a href="https://github.com/VictorKildahl/cra/releases/latest"><img alt="上游最新版本" src="https://img.shields.io/github/v/release/VictorKildahl/cra?label=release"></a>
  <img alt="支持 macOS 14 及以上版本，兼容 Apple 芯片和 Intel 处理器" src="https://img.shields.io/badge/macOS-14%2B%20·%20Apple%20silicon%20%26%20Intel-lightgrey">
  <a href="LICENSE"><img alt="MIT 许可证" src="https://img.shields.io/github/license/VictorKildahl/cra"></a>
</p>

<p align="center">
  <img src="docs/screenshots/cra.jpg" alt="Cra 界面：侧栏中有收藏、空间、固定标签页和文件夹，窗口中并排显示两个网页" width="760">
</p>

本仓库维护 Cra 的 macOS 简体中文界面。要使用这里的译文，请按下文的[源码构建](#源码构建)步骤编译。

按上游项目的说明，Arc 将于 2026 年 12 月 22 日停止服务。Cra 保留了 Arc 的空间、收藏和命令栏，固定标签页记得最初的网址，“今天”里的标签页可以自动归档。分屏、小窗和熟悉的键盘快捷键也都在。一次导入 Arc 侧栏，就能接着上次的进度继续浏览。

Cra 用 Swift、AppKit 和 SwiftUI 编写。底层使用 Chrome 的浏览器框架，并将 Cra 自己的功能集成到框架中，因此网站和 Chrome 扩展可以像在 Chrome 中一样运行。

<a id="install"></a>

## 安装上游发行版

<p align="center">
  <a href="https://github.com/VictorKildahl/cra/releases/latest/download/Cra.dmg"><img alt="下载上游 Mac 版" src="docs/assets/download.png" width="272" height="60"></a>
</p>

打开 DMG，把 Cra 拖入“应用程序”文件夹。上游发行版带有开发者签名、经过 Apple 公证，支持自动更新。使用 Intel Mac 时，请下载 [Cra-Intel.dmg](https://github.com/VictorKildahl/cra/releases/latest/download/Cra-Intel.dmg)。

两种 Mac 都可以通过 Homebrew 安装上游版：

```sh
brew install --cask victorkildahl/tap/cra
```

<a id="coming-from-arc"></a>

## 从 Arc 迁移

| Arc 功能 | Cra 支持情况 |
|---|---|
| 空间 | ✅ |
| 固定标签页 | ✅ |
| “今天”标签页与自动归档 | ✅ |
| 收藏 | ✅ |
| 文件夹 | ✅ |
| 命令栏 | ✅ |
| Little Arc 小窗 | ✅ |
| 分屏 | ✅ |
| 画中画 | ✅ |
| 开发者模式 | ✅ |
| 资料库 | ✅ 集中管理媒体、下载、画板、空间、Boost 和归档。截图会自动出现在资料库按钮的下载列表里，可以直接拖到网页上。 |
| 链接分流（Air Traffic Control） | ✅ |
| 实时文件夹 | ✅ |
| 个人资料 | ✅ |
| 无痕窗口 | ✅ |
| Arc 键盘快捷键 | ✅ |
| 从 Arc 导入 | ✅ |
| 画板（Easels） | ✅ |
| Boost | ✅ |
| 链接预览（Peek） | ✅ |
| Netflix、Disney+、Spotify 等受 DRM 保护的流媒体 | 通过 Safari 引擎和 Apple FairPlay 播放。已验证登录后能播放 [Disney+ 和 Prime Video](docs/protected-media.md#confirmed-playing)。其他网站遇到 [Widevine 播放失败](docs/protected-media.md#widevine-that-fails)时，也会自动切换到 Safari 引擎并保留登录状态。 |
| 笔记（Notes） | Cra 未收录此功能。Arc 本身也已停止支持新建笔记。 |
| Arc Max | 支持针对当前页面提问、即时链接、整理标签页、整理标签页标题、整理下载项和 5 秒预览。这些功能使用 Mac 本机的 Apple Intelligence，只有即时链接会把查询词发送给搜索引擎。 |

后续计划见[项目路线图](https://crabrowser.app/roadmap)。

<a id="import"></a>

## 导入浏览数据

首次启动时可以导入，以后也可以从“Cra › 从 Arc 或 Dia 导入…”打开导入向导。

| 来源 | 可导入的内容 |
|---|---|
| Arc | 空间、固定标签页、文件夹、收藏、归档、密码和登录状态。 |
| Yab、Ardia | 空间、固定标签页、文件夹、收藏、登录状态和扩展，还支持从 Ardia 导入密码。有独立登录状态的空间会对应一个 Cra 个人资料。 |
| Phi | 空间、固定标签页、文件夹、收藏、密码、登录状态和扩展。不同 Phi 个人资料中的空间会对应到各自的 Cra 个人资料。 |
| Crest | 空间、收藏、固定标签页、文件夹、打开和已归档的标签页、密码、登录状态和扩展。Crest 的各个空间有独立的登录状态，因此从第二个空间起，每个空间都会分配独立的 Cra 个人资料。 |
| Dia、Chrome、Brave、Edge、Opera、Vivaldi、Chromium、Helium | 标签页、书签、历史记录、密码、登录状态和扩展。 |
| Zen、Firefox | 打开的标签页、书签和历史记录。Zen 还支持导入空间、常驻标签页（Essentials）和固定标签页。 |
| Safari | 通过 Safari 的“文件 › 导出浏览数据”导出的书签、历史记录和密码。 |

同名空间会合并，已有标签页会跳过。导入向导中的每一步都可以跳过。

<a id="keyboard"></a>

## 键盘快捷键

Cra 沿用 Arc 的默认快捷键，可在“设置 › 快捷键”中逐项修改。

| 快捷键 | 操作 |
|---|---|
| <kbd>⌘</kbd> <kbd>T</kbd> | 新建标签页（打开命令栏） |
| <kbd>⌘</kbd> <kbd>L</kbd> | 编辑网址 |
| <kbd>⌘</kbd> <kbd>W</kbd> | 关闭标签页 |
| <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>T</kbd> | 重新打开已关闭的标签页 |
| <kbd>⌘</kbd> <kbd>D</kbd> | 固定或取消固定标签页 |
| <kbd>⌘</kbd> <kbd>S</kbd> | 显示或隐藏侧栏 |
| <kbd>⌃</kbd> <kbd>1</kbd>…<kbd>9</kbd> | 切换到对应的空间 |
| <kbd>⌘</kbd> <kbd>1</kbd>…<kbd>9</kbd> | 切换到对应的标签页 |
| <kbd>⌃</kbd> <kbd>Tab</kbd> | 切换到最近使用的标签页 |
| <kbd>⌃</kbd> <kbd>⇧</kbd> <kbd>=</kbd> | 分屏 |
| <kbd>⌥</kbd> <kbd>⌘</kbd> <kbd>N</kbd> | 新建小窗 |
| <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>N</kbd> | 新建无痕窗口 |
| <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>C</kbd> | 复制网址 |
| <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>K</kbd> | 清空“今天” |
| <kbd>⌘</kbd> <kbd>Y</kbd> | 查看历史记录和归档 |
| <kbd>⌃</kbd> <kbd>D</kbd> | 开发者模式 |
| <kbd>⌥</kbd> <kbd>⌘</kbd> <kbd>I</kbd> | 开发者工具 |

与 Chrome 一样，Cra 会让网页优先处理浏览器未保留的快捷键。例如，在 Google 文档里按 ⌘F 会打开文档内查找。[完整快捷键列表](https://crabrowser.app/shortcuts)

<a id="privacy-and-security"></a>

## 隐私与安全

使用 Cra 无需注册账号。匿名每日使用统计和崩溃报告均须手动开启，内容不含访问过的网站。[查看统计和报告包含哪些数据](docs/sharing.md)

空间、标签页和归档以明文 JSON 格式保存在 `~/Library/Application Support/Cra`。内置拦截器可阻止向超过 22,000 个广告和跟踪域名发起的请求。

网页在 Chromium 沙盒中运行，并启用站点隔离。密码和 Cookie 使用存放在 macOS 钥匙串中的密钥加密。上游每小时检查 Chrome 安全修复，并通过签名更新分发。防护范围见[安全说明](https://crabrowser.app/security)。如发现漏洞，请按[安全报告指南](SECURITY.md)私下反馈。

<a id="support-cra"></a>

## 支持 Cra

Cra 免费、开源，没有投资方，也不投放广告。赞助用于 Chromium 更新、Apple 代码签名和日常维护。所有人都可以免费使用全部功能。

<p align="center">
  <a href="https://github.com/sponsors/VictorKildahl"><img alt="通过 GitHub 赞助上游作者" src="docs/assets/sponsor.png" width="272" height="60"></a>
</p>

<p align="center"><a href="https://crabrowser.app/support">查看赞助款的用途</a></p>

<a id="iphone"></a>

### iPhone 版

Cra 的 iPhone 版是受 Arc Search 启发的开源浏览器。iPhone 和 iPad 用户可以从 [App Store](https://apps.apple.com/app/id6834101298) 免费下载，也可以从 [TestFlight](https://testflight.apple.com/join/e7SdnNEr) 提前试用新版本。需要 iOS 17 或更高版本。“为我浏览”（Browse for Me）和摘要功能使用 iPhone 本机的 Apple Intelligence。[官方网站介绍](https://crabrowser.app/iphone) · [iOS 源码](iOS) · [iOS 功能进度](docs/ios-parity.md)

<a id="build-from-source"></a>

## 源码构建

macOS 版需要 Xcode 16 或更高版本。在仓库根目录执行：

```sh
scripts/build.sh          # 首次运行会下载引擎，应用生成在 build/Cra.app
scripts/run.sh            # 必要时先构建，再打开应用
scripts/dev.sh            # 启动调试版 CraDev.app，保存代码后自动重新构建并启动
```

构建脚本会下载已集成 Cra 功能的 Chrome 框架。要从 Chrome 源码编译引擎，可运行 `scripts/build-chromium.sh`。[引擎说明](docs/chromium-engine.md)

iPhone 版需要安装 iOS 平台支持的 Xcode 26。运行 `scripts/ios.sh build` 即可构建，无需 Chromium。提交改动前可阅读[贡献指南](CONTRIBUTING.md)。代码布局、脚本接口和测试实例见[开发文档](docs/development.md)。

<a id="licence"></a>

## 许可证

Cra 采用 [MIT 许可证](LICENSE)。Arc 是 The Browser Company 的商标。Cra 是独立项目，与该公司无隶属关系。

### macOS 自建更新源

正式版从 `https://browser-update.orevx.com/cra/` 下的 Sparkle 清单检查更新。Apple 芯片和 Intel 各有「新版」与「稳定版」两个清单。用 `scripts/release.sh` 生成分发文件，签名私钥通过 `CRA_SPARKLE_KEY_FILE` 指定，CI 也可使用 `SPARKLE_PRIVATE_KEY`。

默认沿用自建源当前的稳定版。某架构首次发布时，其稳定版清单为空，本次版本同时进入两个渠道。先把 ZIP、DMG、架构对应的 appcast 和 web-features 检查结果归档到站点的 `downloads/cra/<版本>/`，再更新 `cra/` 下的四个清单。以后可设置 `CRA_SITE_ROOT` 指向站点根目录，用 `scripts/promote.sh <版本> --dry-run` 预览稳定版清单，去掉 `--dry-run` 即可写入。
