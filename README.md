# 摩斯输入法 (Morse Keyboard)

一个 iOS 自定义键盘：打字自动转摩斯电码。26 个字母 + 数字 + 标点，共 40 个字符，标准国际摩斯码表。

## 功能

- 点字母键输出对应摩斯码（如 `q` → `.--. `），码后自动补空格分隔
- 第一行字母键**长按**输入对应数字（q~p → 1~0）
- `v` 长按输入 `/`（单词分隔符），`b`/`n`/`m` 长按输入 `,` `.` `?`
- ⌫ 单击删除一个完整摩斯码单元；**长按连续删除**
- 长按「↵」进入光标自由移动模式（拖动手指移动光标）
- 「译」键：选中一段摩斯码后点击，在键盘顶栏预览翻译结果
- 换行：单击「↵」

## 自己动手安装（需要一台 Mac）

1. App Store 安装 [Xcode](https://apps.apple.com/cn/app/xcode/id497799835)（免费）
2. 克隆本仓库，双击打开 `demo2.xcodeproj`
3. 左侧点蓝色工程图标 → 分别选中 `Demo2` 和 `Demo2Keyboard` 两个 target → **Signing & Capabilities** → 勾选 Automatically manage signing，Team 选你自己的
4. iPhone 用数据线连 Mac，Xcode 顶部设备栏选中你的手机，按 ▶ 运行
5. 首次运行手机提示不受信任：`设置 → 通用 → VPN与设备管理` → 信任你的证书
6. `设置 → 通用 → 键盘 → 键盘 → 添加新键盘…` → 选第三方里的 **摩斯键盘**

> 免费 Apple ID 签名有效期 7 天，过期后重新运行一次第 4 步即可。

## 技术栈

- 纯 Swift + UIKit，无第三方依赖
- xcodegen 管理工程文件（`project.yml`），仓库内已含生成的 `.xcodeproj` 可直接打开
- Keyboard Extension 通过 `UITextDocumentProxy` 与宿主 App 交互

## 目录结构

```
├── project.yml              # 工程定义（xcodegen）
├── demo2/                   # 主 App（安装引导页）
└── Demo2Keyboard/           # 键盘扩展
    ├── KeyboardViewController.swift   # 键盘 UI 与交互
    └── MorseCode.swift                # 摩斯码表
```

祝大家玩得开心😆
