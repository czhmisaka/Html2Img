/*
 * @Date: 2025-05-07 22:02:29
 * @LastEditors: CZH
 * @LastEditTime: 2025-05-08 04:16:36
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
            args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
        });

        const page = await browser.newPage();
        await page.setViewport({
            width: options.width || 1920,
            height: 800, // 初始高度，加载后会调整
            deviceScaleFactor: options.scale || 1
        });

        await page.setContent(html, {
            waitUntil: 'networkidle0'
        });

        // 获取页面实际高度
        const bodyHeight = await page.evaluate(() => {
            return Math.max(
                document.body.scrollHeight,
                document.body.offsetHeight,
                document.documentElement.clientHeight,
                document.documentElement.scrollHeight,
                document.documentElement.offsetHeight
            );
        });

        // 调整viewport高度
        await page.setViewport({
            width: options.width || 1200,
            height: bodyHeight,
            deviceScaleFactor: options.scale || 1
        });

        const screenshotOptions = {
            type: options.type || 'png',
            ...(options.type === 'jpeg' ? { quality: options.quality || 80 } : {}),
            fullPage: options.fullPage !== undefined ? options.fullPage : true
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
