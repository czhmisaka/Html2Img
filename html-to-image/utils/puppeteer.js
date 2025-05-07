/*
 * @Date: 2025-05-07 22:02:29
 * @LastEditors: CZH
 * @LastEditTime: 2025-05-08 00:00:30
 * @FilePath: /html生成图片/html-to-image/utils/puppeteer.js
 */
const puppeteer = require('puppeteer');

/**
 * 生成HTML截图
 * @param {string} html - HTML内容 
 * @param {object} options - 截图选项
 * @returns {Promise<Buffer>} 图片Buffer
 */
async function captureHTML(html, options = {}) {
    console.log('开始截图处理，HTML长度:', html.length);
    let browser;
    try {
        browser = await puppeteer.launch({
            headless: 'new',
            args: ['--no-sandbox', '--disable-setuid-sandbox']
        });

        const page = await browser.newPage();
        await page.setViewport({
            width: options.width || 1200,
            height: options.height || 800,
            deviceScaleFactor: options.scale || 1
        });

        await page.setContent(html, {
            waitUntil: 'networkidle0'
        });

        const screenshotOptions = {
            type: options.type || 'png',
            ...(options.type === 'jpeg' ? { quality: options.quality || 80 } : {}),
            fullPage: options.fullPage || false
        };

        return await page.screenshot(screenshotOptions);
    } catch (error) {
        console.error('截图生成错误详情:', error);
        throw error;
    } finally {
        if (browser) {
            await browser.close();
        }
    }
}

module.exports = captureHTML;
