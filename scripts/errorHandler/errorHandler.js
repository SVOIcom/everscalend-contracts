/**
 * Parse error and try to extract address
 * @param {Object} err 
 * @returns {String}
 */
function tryToExtractAddress(err) {
    if (
        err && err.code == 414
    ) {
        if (err.data && err.data.exit_code == 51) {
            return err.data.account_address;
        }
    }

    if (
        err && err.code == 507
    ) {
        if (err.data.local_error.data.exit_code == 51) {
            return err.data.local_error.data.account_address;
        }
    }
    return '';
}

module.exports = tryToExtractAddress;