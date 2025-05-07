/*
 * @Date: 2025-05-07 22:03:27
 * @LastEditors: CZH
 * @LastEditTime: 2025-05-08 03:36:24
 * @FilePath: /html生成图片/html-to-image/index.js
 */
const express = require('express');
const cors = require('cors');
const swaggerJSDoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const apiRouter = require('./routes/api');

const app = express();
const PORT = 15600;

// Swagger配置
const swaggerOptions = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'HTML转图片API',
            version: '1.0.0',
            description: '将HTML转换为图片的API服务',
        },
        servers: [
            {
                url: `http://localhost:${PORT}`,
            },
        ],
    },
    apis: ['./routes/*.js'], // 包含API注释的文件路径
};

const swaggerSpec = swaggerJSDoc(swaggerOptions);

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.static('public'));
app.use('/cache', express.static('cache'));

// Swagger UI路由
app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// 路由
app.use('/api', apiRouter);

// 错误处理
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: '服务器内部错误' });
});

// 启动服务器
app.listen(PORT, () => {
    console.log(`服务运行在 http://localhost:${PORT}`);
});

module.exports = app;
