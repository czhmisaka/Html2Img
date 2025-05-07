/*
 * @Date: 2025-05-07 22:02:04
 * @LastEditors: CZH
 * @LastEditTime: 2025-05-07 22:02:18
 * @FilePath: /html生成图片/html-to-image/utils/sanitize.js
 */
const cheerio = require('cheerio');

/**
 * 净化HTML内容
 * @param {string} html - 原始HTML
 * @param {object} options - 净化选项
 * @returns {string} 净化后的HTML
 */
function sanitizeHTML(html, options = {}) {
    const $ = cheerio.load(html);

    // 默认移除所有script标签
    $('script').remove();

    // 可选移除内联事件处理
    if (options.removeEventHandlers) {
        $('*').each(function () {
            const elem = $(this);
            Object.keys(elem[0].attribs)
                .filter(attr => attr.startsWith('on'))
                .forEach(attr => elem.removeAttr(attr));
        });
    }

    // 可选移除特定标签
    if (options.removeTags) {
        options.removeTags.forEach(tag => $(tag).remove());
    }

    return $.html();
}

module.exports = sanitizeHTML;
