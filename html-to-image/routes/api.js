/*
 * @Date: 2025-05-07 22:02:56
 * @LastEditors: CZH
 * @LastEditTime: 2025-05-07 23:34:16
 * @FilePath: /html生成图片/html-to-image/routes/api.js
 */
const express = require('express');
const router = express.Router();
const sanitizeHTML = require('../utils/sanitize');
const captureHTML = require('../utils/puppeteer');

/**
 * @swagger
 * /api/sanitize:
 *   post:
 *     summary: HTML净化接口
 *     description: 对输入的HTML进行净化处理，移除不安全的内容
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               html:
 *                 type: string
 *                 description: 需要净化的HTML内容
 *               options:
 *                 type: object
 *                 description: 净化选项配置
 *             required:
 *               - html
 *     responses:
 *       200:
 *         description: 净化后的HTML
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 result:
 *                   type: string
 *                   description: 净化后的HTML内容
 *       400:
 *         description: 参数错误
 *       500:
 *         description: 服务器错误
 */
router.post('/sanitize', async (req, res) => {
    try {
        const { html, options } = req.body;
        if (!html) {
            return res.status(400).json({ error: 'HTML内容不能为空' });
        }

        const sanitized = sanitizeHTML(html, options || {});
        res.json({ result: sanitized });
    } catch (error) {
        res.status(500).json({ error: 'HTML净化失败' });
    }
});

/**
 * @swagger
 * /api/screenshot:
 *   post:
 *     summary: 生成截图接口
 *     description: 将HTML转换为PNG图片
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               html:
 *                 type: string
 *                 description: 需要截图的HTML内容
 *               options:
 *                 type: object
 *                 description: 截图选项配置
 *             required:
 *               - html
 *     responses:
 *       200:
 *         description: PNG图片数据
 *         content:
 *           image/png:
 *             schema:
 *               type: string
 *               format: binary
 *       400:
 *         description: 参数错误
 *       500:
 *         description: 服务器错误
 */
router.post('/screenshot', async (req, res) => {
    try {
        const { html, options } = req.body;
        if (!html) {
            return res.status(400).json({ error: 'HTML内容不能为空' });
        }

        const image = await captureHTML(html, options || {});
        res.set('Content-Type', 'image/png');
        res.send(image);
    } catch (error) {
        res.status(500).json({ error: '截图生成失败' });
    }
});

module.exports = router;
