#!/bin/zsh
# 保存为 build_debug_local.sh

cd /Users/bytedance/Code/FlowDown

# 清理之前的构建
rm -rf build/

# 构建macOS Catalyst debug版本（无签名）
echo "开始构建macOS Catalyst debug版本..."
xcodebuild -workspace FlowDown.xcworkspace \
    -scheme FlowDown-Catalyst \
    -configuration Debug \
    -destination 'platform=macOS,variant=Mac Catalyst' \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    -derivedDataPath build/DerivedData \
    build

# 查找构建结果
APP_PATH=$(find build/DerivedData -name "*.app" -type d | head -n 1)

if [[ -n "$APP_PATH" ]]; then
    echo "✅ 构建成功！"
    echo "应用路径: $APP_PATH"
    
    # 复制到当前目录方便使用
    cp -R "$APP_PATH" ./FlowDown-debug.app
    echo "已复制到: ./FlowDown-debug.app"
    
    # 尝试运行应用
    echo "正在启动应用..."
    open "./FlowDown-debug.app"
else
    echo "❌ 构建失败，请检查错误信息"
    exit 1
fi