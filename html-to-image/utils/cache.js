/*
 * @Date: 2025-05-08 03:35:12
 * @LastEditors: CZH
 * @LastEditTime: 2025-05-08 03:35:32
 * @FilePath: /html生成图片/html-to-image/utils/cache.js
 */
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const CACHE_DIR = path.join(__dirname, '../cache');
const CACHE_TTL = 24 * 60 * 60 * 1000; // 24小时

// 确保缓存目录存在
if (!fs.existsSync(CACHE_DIR)) {
    fs.mkdirSync(CACHE_DIR, { recursive: true });
}

/**
 * 生成缓存ID (基于内容和选项的MD5哈希)
 * @param {string} html 
 * @param {object} options 
 * @returns {string} 缓存ID
 */
function generateCacheId(html, options = {}) {
    const hash = crypto.createHash('md5');
    hash.update(html);
    hash.update(JSON.stringify(options));
    return hash.digest('hex');
}

/**
 * 获取缓存文件路径
 * @param {string} id 
 * @returns {string} 文件路径
 */
function getCachePath(id) {
    return path.join(CACHE_DIR, `${id}.png`);
}

/**
 * 检查缓存是否存在且未过期
 * @param {string} id 
 * @returns {boolean}
 */
function hasCache(id) {
    const filePath = getCachePath(id);
    if (!fs.existsSync(filePath)) return false;

    const stats = fs.statSync(filePath);
    return Date.now() - stats.mtimeMs < CACHE_TTL;
}

/**
 * 保存图片到缓存
 * @param {string} id 
 * @param {Buffer} image 
 */
function saveToCache(id, image) {
    fs.writeFileSync(getCachePath(id), image);
}

/**
 * 从缓存读取图片
 * @param {string} id 
 * @returns {Buffer}
 */
function getFromCache(id) {
    return fs.readFileSync(getCachePath(id));
}

module.exports = {
    generateCacheId,
    hasCache,
    saveToCache,
    getFromCache,
    getCachePath
};
