# Sublime Text 4 Mac Patcher

Sublime Text 4 (Build 4200) macOS 补丁工具。
sublime mac 注册/register/破解

## 原理

修改 `sublime_text` 二进制中的 license 验证逻辑：

```
原始: movzx edx, [rcx+5]; xor edx, 1  (检查标志位并取反)
补丁: mov BYTE PTR [rcx+5], 1; mov dl, 0  (强制设为已注册)
```

| | 原始字节 | 补丁字节 |
|---|---|---|
| x86_64 | `0F B6 51 05 83 F2 01` | `C6 41 05 01 B2 00 90` |
| 偏移 | `0x00290500` (Mac) | `0x00046B80` (Windows) |

> 感谢 [@Fadi002](https://gist.github.com/Fadi002/51a505cece648915bc2f32f3b7e6b71d) 提供的原始 Windows 补丁方案

## 环境要求

- macOS（Intel Mac 原生支持；Apple Silicon Mac 需通过 Rosetta 2 运行）
- Sublime Text 4 Build 4200
- Python 3（macOS 自带）
- sudo 权限

> Apple Silicon Mac 用户：补丁针对 x86_64 指令。Sublime Text 是 Universal Binary，
> Apple Silicon 下原生运行 arm64 版本，该字节模式不存在于 arm64 段。
> 如需使用此补丁，需以 Rosetta 2 模式运行：
> ```bash
> # 右键 Sublime Text.app → 显示简介 → 勾选"使用 Rosetta 打开"
> # 或命令行：
> arch -x86_64 "/Applications/Sublime Text.app/Contents/MacOS/sublime_text"
> ```

## 使用方法

### 方式一：脚本（推荐）

```bash
git clone https://github.com/yourname/sublime-text-mac-patcher.git
cd sublime-text-mac-patcher
bash patch_sublime.sh
```

脚本会自动：
1. 检测 Sublime Text 版本
2. 验证字节是否匹配
3. 备份原始文件（带日期）
4. 打补丁
5. 重新代码签名

### 方式二：一行命令

```bash
sudo perl -pi -e 's/\x0F\xB6\x51\x05\x83\xF2\x01/\xC6\x41\x05\x01\xB2\x00\x90/' \
  "/Applications/Sublime Text.app/Contents/MacOS/sublime_text" && \
  sudo codesign -f -s - "/Applications/Sublime Text.app"
```

## 验证

打开 Sublime Text → Help → About Sublime Text

- 菜单中出现「删除注册信息」= 补丁成功
- 状态栏可能仍显示 `(UNREGISTERED)`，这是正常的，功能不受限制

## 还原

```bash
# 从备份恢复
sudo cp "/Applications/Sublime Text.app/Contents/MacOS/sublime_text.backup_YYYYMMDD" \
  "/Applications/Sublime Text.app/Contents/MacOS/sublime_text"
sudo codesign -f -s - "/Applications/Sublime Text.app"
```

## 注意事项

- 仅适用于 Build 4200，其他版本偏移地址不同
- Sublime Text 更新后补丁会失效，需重新执行
- 补丁会破坏原代码签名，需用 ad-hoc 签名重新签名
- 仅供学习交流，请支持正版

## 相关项目

- [Windows/Linux 补丁 (Gist)](https://gist.github.com/Fadi002/51a505cece648915bc2f32f3b7e6b71d)
