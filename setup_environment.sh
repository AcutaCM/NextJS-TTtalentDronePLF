#!/bin/bash
# 无人机智能分析平台 - 一键环境配置脚本 (Linux/Mac)

set -e  # 遇到错误时停止执行

echo "
╔══════════════════════════════════════════════════════════════╗
║              无人机智能分析平台 - 一键环境配置               ║
║                                                              ║
║  此脚本将自动配置项目所需的所有环境                          ║
║  包括: Node.js依赖、Python环境、AI服务                      ║
╚══════════════════════════════════════════════════════════════╝
"

# 检查是否在正确目录
if [ ! -f "package.json" ]; then
    echo "❌ 错误: 请在项目根目录运行此脚本"
    echo "💡 提示: 请确保当前目录包含package.json文件"
    exit 1
fi

echo "🔍 检查系统环境..."

# 检查Node.js
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "📦 第一步: 检查Node.js环境"
echo "═══════════════════════════════════════════════════════════════"

if ! command -v node &> /dev/null; then
    echo "❌ Node.js未安装"
    echo "📥 请从以下地址下载安装Node.js 18或更高版本:"
    echo "   https://nodejs.org/zh-cn/download/"
    exit 1
else
    NODE_VERSION=$(node --version)
    echo "✅ Node.js已安装: $NODE_VERSION"
fi

if ! command -v npm &> /dev/null; then
    echo "❌ npm未安装"
    exit 1
else
    NPM_VERSION=$(npm --version)
    echo "✅ npm已安装: $NPM_VERSION"
fi

# 检查Python
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "🐍 第二步: 检查Python环境"
echo "═══════════════════════════════════════════════════════════════"

if ! command -v python3 &> /dev/null; then
    echo "❌ Python3未安装"
    echo "📥 请安装Python 3.8或更高版本"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "   macOS: brew install python3"
    else
        echo "   Ubuntu/Debian: sudo apt update && sudo apt install python3 python3-pip python3-venv"
        echo "   CentOS/RHEL: sudo yum install python3 python3-pip"
    fi
    exit 1
else
    PYTHON_VERSION=$(python3 --version)
    echo "✅ Python已安装: $PYTHON_VERSION"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "📦 第三步: 安装前端依赖"
echo "═══════════════════════════════════════════════════════════════"
echo "🔄 正在安装Node.js依赖..."
echo "💡 这可能需要几分钟时间，请耐心等待..."

if ! npm install; then
    echo "❌ npm install失败"
    echo "💡 尝试清理缓存后重新安装..."
    npm cache clean --force
    rm -rf node_modules package-lock.json
    if ! npm install; then
        echo "❌ 前端依赖安装失败，请检查网络连接"
        exit 1
    fi
fi
echo "✅ 前端依赖安装完成"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "🐍 第四步: 配置Python虚拟环境"
echo "═══════════════════════════════════════════════════════════════"

# 创建虚拟环境
if [ ! -d ".venv" ]; then
    echo "🔄 创建Python虚拟环境..."
    if ! python3 -m venv .venv; then
        echo "❌ 虚拟环境创建失败"
        exit 1
    fi
    echo "✅ 虚拟环境创建成功"
else
    echo "✅ 虚拟环境已存在"
fi

# 激活虚拟环境
echo "🔄 激活虚拟环境..."
source .venv/bin/activate

# 升级pip
echo "🔄 升级pip..."
python -m pip install --upgrade pip

# 安装Python依赖
echo "🔄 安装Python依赖..."
echo "💡 这可能需要几分钟时间，特别是OpenCV等大型库..."
if ! pip install -r requirements.txt; then
    echo "❌ Python依赖安装失败"
    echo "💡 尝试使用国内镜像源..."
    if ! pip install -i https://pypi.tuna.tsinghua.edu.cn/simple/ -r requirements.txt; then
        echo "❌ Python依赖安装失败，请检查网络连接"
        exit 1
    fi
fi
echo "✅ Python依赖安装完成"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "🧪 第五步: 环境测试"
echo "═══════════════════════════════════════════════════════════════"
echo "🔄 测试Python环境..."
if ! python python/test_env.py; then
    echo "⚠️ 环境测试发现问题，但核心功能可能仍可正常使用"
else
    echo "✅ 环境测试通过"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "🤖 第六步: AI服务配置（可选）"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "💡 AI服务配置是可选的，即使不配置AI，系统核心功能仍可正常使用"
echo ""
read -p "是否要配置本地AI服务？(y/n): " SETUP_AI

if [[ "$SETUP_AI" =~ ^[Yy]$ ]]; then
    echo ""
    echo "🔍 检查Ollama安装状态..."
    if ! command -v ollama &> /dev/null; then
        echo "❌ Ollama未安装"
        echo "📥 请从以下地址下载安装Ollama:"
        echo "   https://ollama.ai/download"
        echo ""
        echo "安装完成后请："
        echo "1. 重新运行此脚本"
        echo "2. 或手动执行: ollama serve 和 ollama pull qwen2.5-vl:7b"
        echo ""
    else
        echo "✅ Ollama已安装"
        echo ""
        echo "🔄 启动Ollama服务..."
        ollama serve &
        OLLAMA_PID=$!
        sleep 5
        
        echo "🔄 下载AI模型 qwen2.5-vl:7b..."
        echo "💡 这是一个约4GB的模型，下载可能需要较长时间..."
        if ! ollama pull qwen2.5-vl:7b; then
            echo "⚠️ 模型下载失败，可能是网络问题"
            echo "💡 可以稍后手动执行: ollama pull qwen2.5-vl:7b"
        else
            echo "✅ AI模型下载完成"
        fi
        
        echo "🧪 运行AI服务诊断..."
        if [ -f "diagnose_ollama.sh" ]; then
            chmod +x diagnose_ollama.sh
            ./diagnose_ollama.sh
        fi
        
        # 停止后台Ollama进程
        kill $OLLAMA_PID 2>/dev/null || true
    fi
else
    echo "⏭️ 跳过AI服务配置"
    echo "💡 系统将使用后备建议功能，核心功能不受影响"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "📝 第七步: 创建配置文件"
echo "═══════════════════════════════════════════════════════════════"

# 创建 .env.local 文件
if [ ! -f ".env.local" ]; then
    echo "🔄 创建环境配置文件..."
    cat > .env.local << 'EOF'
# 无人机智能分析平台配置文件

# AI模型配置
QWEN_BASE_URL=http://localhost:11434/v1
QWEN_MODEL=qwen2.5-vl:7b

# 无人机配置
DRONE_WEBSOCKET_URL=ws://localhost:8765

# API配置
NEXT_PUBLIC_API_URL=http://localhost:3000/api

# 可选：阿里云AI服务
# DASHSCOPE_API_KEY=your_api_key_here
EOF
    echo "✅ 环境配置文件创建完成"
else
    echo "✅ 环境配置文件已存在"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                        🎉 配置完成！                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ 前端环境: Node.js + npm 依赖已安装"
echo "✅ 后端环境: Python 虚拟环境和依赖已配置"
echo "✅ 配置文件: .env.local 已创建"
if [[ "$SETUP_AI" =~ ^[Yy]$ ]]; then
    echo "✅ AI服务: Ollama 和模型已配置"
else
    echo "⏭️ AI服务: 已跳过（可稍后配置）"
fi
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "🚀 启动项目"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "现在你可以启动项目了："
echo ""
echo "📱 启动前端:"
echo "   npm run dev"
echo ""
echo "🐍 启动后端:"
echo "   source .venv/bin/activate"
echo "   python python/drone_backend.py"
echo ""
echo "🤖 如果配置了AI服务:"
echo "   ollama serve"
echo ""
echo "🌐 前端访问地址: http://localhost:3000"
echo "📡 后端WebSocket: ws://localhost:8765"
echo "🧠 AI服务地址: http://localhost:11434"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "📚 重要文件"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📖 新手入门指南.md - 详细使用说明"
echo "🔧 TROUBLESHOOTING.md - 故障排除指南"
echo "📄 README_CN.md - 项目详细文档"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "💡 下一步建议"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "1. 阅读 '新手入门指南.md' 了解详细使用方法"
echo "2. 启动前端: npm run dev"
echo "3. 启动后端: source .venv/bin/activate && python python/drone_backend.py"
echo "4. 连接DJI Tello无人机进行测试"
echo "5. 如遇问题，查看 TROUBLESHOOTING.md"
echo ""

read -p "是否现在启动前端开发服务器？(y/n): " START_NOW
if [[ "$START_NOW" =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 启动前端开发服务器..."
    echo "💡 请在新的终端窗口运行以下命令启动后端:"
    echo "   source .venv/bin/activate && python python/drone_backend.py"
    echo ""
    npm run dev
else
    echo ""
    echo "👋 配置完成！请随时运行 npm run dev 启动项目"
fi

echo ""
echo "感谢使用无人机智能分析平台！"