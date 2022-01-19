const { Locklift } = require('locklift/locklift');

const { loadConfig } = require('./_load_config');

/**
 * @type {Locklift}
 */
let locklift = undefined;

/**
 * 
 * @param {String} configPath 
 * @param {String} network 
 * @returns { Locklift }
 */
module.exports = async(configPath, network) => {
    if (!locklift) {
        locklift = new Locklift(await loadConfig(configPath), network);
        await locklift.setup();
    }
    return locklift;
}