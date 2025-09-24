<!--
 * @Date: 2025-05-08 09:23:02
 * @LastEditors: CZH
 * @LastEditTime: 2025-05-08 10:02:38
 * @FilePath: /html生成图片/readMe.md
-->

# 🖼️ HTML转图片工具

![GitHub stars](https://img.shields.io/github/stars/czhmisaka/Html2Img?style=social)
![GitHub last commit](https://img.shields.io/github/last-commit/czhmisaka/Html2Img)
![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)

一个基于Node.js和Puppeteer的高性能HTML转图片工具，提供REST API和简洁的Web界面，支持自定义截图参数和HTML净化功能。

## ✨ 功能特性

- **图片生成** - 将HTML内容转换为高质量PNG图片
- **尺寸定制** - 支持自定义截图宽度、高度和缩放比例
- **安全净化** - 内置HTML净化功能，防止XSS攻击
- **智能缓存** - 自动缓存生成的图片，24小时有效期
- **完善文档** - 集成Swagger UI的API文档
- **友好界面** - 简洁易用的Web操作界面

## 🌐 在线体验

访问演示站点: [http://118.25.84.228:15600/](http://118.25.84.228:15600/)

## 🛠️ 安装指南

## 🌊 docker一键部署脚本
国内服务器
```bash
bash <(curl -sSL https://fastly.jsdelivr.net/gh/czhmisaka/Html2Img/install.sh)
```

国外服务器
```bash
bash <(curl -sSL https://raw.githubusercontent.com/czhmisaka/Html2Img/main/install.sh)
```

```
使用示例
运行
bash install.sh build html2img .
停止删除
bash install.sh delete -f  html2img
```

## ⌛ 手动安装步骤
### 前置要求
- Node.js 22+
- npm 6+
- Puppeteer依赖的Chromium

### 环境准备
1. **安装Chromium/Chrome**：
   ```bash
   # Ubuntu/Debian
   sudo apt-get install chromium-browser

   # CentOS/RHEL
   sudo yum install chromium

   # macOS (通过Homebrew)
   brew install --cask google-chrome
   ```

2. **安装中文字体**：
   ```bash
   # Ubuntu/Debian
   sudo apt-get install fonts-wqy-microhei fonts-wqy-zenhei

   # CentOS/RHEL
   sudo yum install wqy-microhei-fonts wqy-zenhei-fonts

   # macOS (通过Homebrew)
   brew tap homebrew/cask-fonts
   brew install --cask font-wqy-microhei
   ```

3. **验证字体安装**：
   ```bash
   fc-list :lang=zh
   ```

1. 克隆仓库：
```bash
git clone https://github.com/czhmisaka/Html2Img.git
cd Html2Img/html-to-image
```

2. 安装依赖：
```bash
npm install
```

3. 启动服务：
```bash
npm start
```

服务默认运行在: [http://localhost:15600](http://localhost:15600)



## 📚 API文档

访问 `/docs` 路径查看交互式Swagger文档:  
[http://localhost:15600/docs](http://localhost:15600/docs)

### API端点说明

| 端点                 | 方法 | 描述                 |
| -------------------- | ---- | -------------------- |
| `/api/sanitize`      | POST | HTML内容净化         |
| `/api/screenshot`    | POST | 生成截图并直接返回   |
| `/api/image/{id}`    | GET  | 通过ID获取缓存图片   |
| `/api/screenshot-id` | POST | 生成截图并返回缓存ID |

## ⚙️ 配置参数

可通过环境变量配置服务：

```bash
# 服务端口
PORT=15600

# 缓存目录路径
CACHE_DIR=./cache

# 缓存有效期(秒)
CACHE_TTL=86400
```

## 📂 项目结构

```text
html-to-image/
├── index.js          # 服务主入口
├── routes/
│   └── api.js       # API路由定义
├── utils/
│   ├── cache.js     # 缓存管理
│   ├── puppeteer.js # 截图核心逻辑
│   └── sanitize.js  # HTML净化
├── public/          # 静态资源
│   └── index.html   # Web界面
└── cache/           # 图片缓存目录
```

## 🧪 测试

测试脚本位于 `/test` 目录：

```bash
cd test
./test_118.sh
```

## 🤝 贡献

欢迎通过以下方式参与项目：
- 提交Issue报告问题
- 发起Pull Request贡献代码
- 完善文档和测试用例

## 📜 许可证

本项目采用 [Apache License 2.0](LICENSE) 开源协议。
