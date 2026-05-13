#!/bin/bash
# Sublime Text 4 Build 4200 Mac 补丁脚本
# 用法: ./patch_sublime_mac.sh
# 需要 sudo 权限

set -e

SUBLIME_APP="/Applications/Sublime Text.app"
SUBLIME_BIN="$SUBLIME_APP/Contents/MacOS/sublime_text"
PATCH_OFFSET_HEX="00290500"
ORIGINAL_HEX="0F B6 51 05 83 F2 01"
PATCHED_HEX="C6 41 05 01 B2 00 90"

echo "=== Sublime Text 4 Mac 补丁工具 ==="
echo ""

# 检查 Sublime Text 是否在运行
if pgrep -q "sublime_text"; then
    echo "[!] Sublime Text 正在运行，正在退出..."
    osascript -e 'quit app "Sublime Text"' 2>/dev/null || true
    sleep 2
fi

# 检查二进制文件是否存在
if [ ! -f "$SUBLIME_BIN" ]; then
    echo "[!] 未找到: $SUBLIME_BIN"
    echo "[!] 请确认 Sublime Text 已安装在 /Applications"
    exit 1
fi

# 检查版本
BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$SUBLIME_APP/Contents/Info.plist" 2>/dev/null || echo "unknown")
echo "[*] 检测到 Sublime Text Build $BUILD"

if [ "$BUILD" != "4200" ]; then
    echo "[!] 警告: 此补丁针对 Build 4200，当前版本可能不兼容"
    read -p "    继续？(y/N) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# 检查是否已补丁
python3 -c "
with open('$SUBLIME_BIN', 'rb') as f:
    f.seek($PATCH_OFFSET_HEX, 0)
    data = f.read(7)
if data == bytes.fromhex('$PATCHED_HEX'):
    print('[*] 已经补丁过了，无需重复操作')
    exit(2)
elif data != bytes.fromhex('$ORIGINAL_HEX'):
    print('[!] 原始字节不匹配，可能版本不同或已被修改')
    print(f'    偏移 0x$PATCH_OFFSET_HEX 处: {data.hex(\" \").upper()}')
    print(f'    期望: $ORIGINAL_HEX')
    exit(1)
else:
    print('[*] 检测到原始字节，可以补丁')
" 2>/dev/null
RESULT=$?
if [ $RESULT -eq 2 ]; then
    exit 0
elif [ $RESULT -ne 0 ]; then
    exit 1
fi

# 备份
BACKUP="${SUBLIME_BIN}.backup_$(date +%Y%m%d)"
echo "[*] 备份原始文件到: $BACKUP"
sudo cp "$SUBLIME_BIN" "$BACKUP"

# 打补丁
echo "[*] 正在打补丁..."
python3 -c "
with open('$SUBLIME_BIN', 'rb') as f:
    data = bytearray(f.read())
offset = $PATCH_OFFSET_HEX
data[offset:offset+7] = bytes.fromhex('$PATCHED_HEX')
with open('$SUBLIME_BIN', 'wb') as f:
    f.write(data)
print('[+] 补丁写入成功')
"

# 重新签名
echo "[*] 正在重新签名..."
sudo codesign -f -s - "$SUBLIME_APP" 2>/dev/null

# 验证
echo "[*] 验证补丁..."
python3 -c "
with open('$SUBLIME_BIN', 'rb') as f:
    f.seek($PATCH_OFFSET_HEX, 0)
    data = f.read(7)
if data == bytes.fromhex('$PATCHED_HEX'):
    print('[+] 验证通过！补丁成功！')
else:
    print('[-] 验证失败！')
    exit(1)
"

echo ""
echo "=== 完成 ==="
echo "备份位置: $BACKUP"
echo "启动 Sublime Text 检查 Help -> About 中的注册状态"
