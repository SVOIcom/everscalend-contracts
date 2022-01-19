pragma ton-solidity >= 0.39.0;

struct fraction {
    uint256 nom;
    uint256 denom;
}

library FPO {
    uint256 constant bits224 = 2**224;
    uint256 constant bits192 = 2**192;
    uint256 constant bits160 = 2**160;
    uint256 constant bits128 = 2**128;
    uint256 constant bits96 = 2**96;
    uint256 constant bits64 = 2**64;
    uint256 constant bits32 = 2**32;

    function fMul(fraction a, fraction b) internal pure returns (fraction) {
        return fraction(a.nom*b.nom, a.denom*b.denom);
    }

    function fNumMul(fraction a, uint256 b) internal pure returns (fraction) {
        return fraction(a.nom * b, a.denom);
    }

    function fNumDiv(fraction a, uint256 b) internal pure returns (fraction) {
        return fraction(a.nom, a.denom * b);
    }

    function fDiv(fraction a, fraction b) internal pure returns(fraction) {
        return fraction(a.nom * b.denom, a.denom * b.nom);
    }

    function fAdd(fraction a, fraction b) internal pure returns (fraction) {
        return fraction (a.nom * b.denom + b.nom * a.denom, a.denom * b.denom);
    }

    function fNumAdd(fraction a, uint256 b) internal pure returns (fraction) {
        return fraction (a.nom + b*a.denom, a.denom);
    }

    function fSub(fraction a, fraction b) internal pure returns (fraction) {
        return fraction(a.nom * b.denom - b.nom * a.denom, a.denom * b.denom);
    }

    function isLarger(fraction a, fraction b) internal pure returns (bool) {
        return a.nom * b.denom > b.nom * a.denom;
    }

    function toNum(fraction a) internal pure returns(uint256) {
        return a.nom / a.denom;
    }

    function eq(fraction a, fraction b) internal pure returns(bool) {
        return ((a.nom == b.nom) && (a.denom == b.denom));
    }

    function getMin(fraction a, fraction b) internal pure returns(fraction) {
        if (a.nom * b.denom < b.nom * a.denom) {
            return a;
        } else {
            return b;
        }
    }

    function lessThan(fraction a, fraction b) internal pure returns(bool) {
        return a.nom * b.denom < b.nom * a.denom;
    }

    function simplify(fraction a) internal pure returns(fraction) {
        // loosing ¯\_(ツ)_/¯ % of presicion at most
        if (a.nom / a.denom > 100e9) {
            return fraction(a.nom / a.denom, 1);
        } else {
            // using bitshift for simultaneos division
            // leaving up to 64 bits of information if nom & denom > 2^64
            if ( (a.nom >= bits224) && (a.denom >= bits224) ) {
                return fraction(a.nom / bits160, a.denom / bits160);
            }

            if ( (a.nom >= bits192) && (a.denom >= bits192) ) {
                return fraction(a.nom / bits128, a.denom / bits128);
            }

            if ( (a.nom >= bits160) && (a.denom >= bits160) ) {
                return fraction(a.nom / bits96, a.denom / bits96);
            }

            if ( (a.nom >= bits128) && (a.denom >= bits128) ) {
                return fraction(a.nom / bits64, a.denom / bits64);
            }

            if ( (a.nom >= bits96) && (a.denom >= bits96) ) {
                return fraction(a.nom / bits32, a.denom / bits32);
            }

            return a;
        }
    }
}

library UFO {
    function numMul(uint256 a, fraction b) internal pure returns (uint256) {
        return a*b.nom/b.denom;
    }

    function numFMul(uint256 a, fraction b) internal pure returns (fraction) {
        return fraction(a * b.nom, b.denom);
    }

    function numFDiv(uint256 a, fraction b) internal pure returns (fraction) {
        return fraction(a * b.denom, b.nom);
    }

    function numAdd(uint256 a, fraction b) internal pure returns (uint256) {
        return (a*b.denom + b.nom) / b.denom;
    }

    function numSub(uint256 a, fraction b) internal pure returns (uint256) {
        return (a * b.denom - b.nom)/b.denom;
    }

    function toF(uint256 num) internal pure returns(fraction) {
        return fraction(num, 1);
    }
}
