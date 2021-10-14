var BN = require('bn.js');
var hash = require('hash.js');
var elliptic = require('elliptic');
var utils = elliptic.utils;
var EDDSA = require('./elliptic_eddsa_variant');
var eddsa = new EDDSA('ed25519');

function sha512(data) {
    var digest = hash.sha512().update(data).digest();
    return Buffer.from(digest);
}

function hmac512(key, data) {
    var digest = hash.hmac(hash.sha512, key).update(data).digest();
    return Buffer.from(digest);
}

function makeEd25519Extended(secret) {
    var extended = sha512(secret);
    extended[0] &= 248;
    extended[31] &= 63;
    extended[31] |= 64;
    return extended;
}

function generateFromSeed(seed) {
    var iter = 1;
    while (true) {
        var s = 'Root Seed Chain ' + iter;
        var block = hmac512(seed, s);
        var extended = makeEd25519Extended(block.slice(0, 32));
        if ((extended[31] & 0x20) === 0) {
            return Buffer.concat([extended, block.slice(32, 64)])
        }
        iter++;
    }
}

function fromSeed2(seed) {
    var s = 'ed25519 cardano seed';
    var block = hmac512(s, seed);

    var extended = sha512(block.slice(0, 32));
    extended[0] &= 248;
    extended[31] &= 0x1f;
    extended[31] |= 64;

    return Buffer.concat([extended, block.slice(32, 64)])
}

function derivePrivate(xprv, index) {
    var kl = xprv.slice(0, 32);
    var kr = xprv.slice(32, 64);
    var cc = xprv.slice(64, 96);

    var data;
    var z, i;
    if (index < 0x80000000) {
        data = Buffer.allocUnsafe(1 + 32 + 4);
        data.writeUInt32LE(index, 1 + 32);

        var pk = toPublic(kl);
        pk.copy(data, 1);

        data[0] = 0x02;
        z = hmac512(cc, data);
        data[0] = 0x03;
        i = hmac512(cc, data);
    }
    else {
        data = Buffer.allocUnsafe(1 + 64 + 4);
        data.writeUInt32LE(index, 1 + 64);
        kl.copy(data, 1);
        kr.copy(data, 1 + 32);

        data[0] = 0x00;
        z = hmac512(cc, data);
        data[0] = 0x01;
        i = hmac512(cc, data);
    }

    var chainCode = i.slice(32, 64);
    var zl = z.slice(0, 32);
    var zr = z.slice(32, 64);

    // left = kl + 8 * trunc28(zl)
    // right = zr + kr
    var left = new BN(kl, 16, 'le').add(new BN(zl.slice(0, 28), 16, 'le').mul(new BN(8))).toArrayLike(Buffer, 'le', 32);
    var right = new BN(kr, 16, 'le').add(new BN(zr, 16, 'le')).toArrayLike(Buffer, 'le').slice(0, 32);

    // just padding
    if (right.length !== 32) {
        right = Buffer.from(right.toString('hex') + '00', 'hex')
    }

    return Buffer.concat([left, right, chainCode]);
}

function derivePublic(xpub, index) {
    var pk = xpub.slice(0, 32);
    var cc = xpub.slice(32, 64);

    var data = Buffer.allocUnsafe(1 + 32 + 4);
    data.writeUInt32LE(index, 1 + 32);

    var z, i;
    if (index < 0x80000000) {
        pk.copy(data, 1);
        data[0] = 0x02;
        z = hmac512(cc, data);
        data[0] = 0x03;
        i = hmac512(cc, data);
    }
    else {
        throw new Error('can not derive public key with harden')
    }

    var chainCode = i.slice(32, 64);
    var zl = z.slice(0, 32);

    // left = 8 * trunc28(zl)
    var left = new BN(zl.slice(0, 28), 16, 'le').mul(new BN(8));

    var p = eddsa.g.mul(left);
    var pp = eddsa.decodePoint(pk.toString('hex'));
    var point = pp.add(p);

    return Buffer.concat([Buffer.from(eddsa.encodePoint(point)), chainCode]);
}

function toPublic(xprv) {
    if (xprv.length !== 32 && xprv.length !== 96) {
        throw new Error('invalid xprv')
    }

    var key = eddsa.keyFromSecret(xprv.slice(0, 32).toString('hex'));
    var pk = Buffer.from(key.pubBytes());
    if (xprv.length > 64) {
        return Buffer.concat([pk, xprv.slice(64, 96)])
    }
    return pk;
}

function sign(message, xprv) {
    if (typeof xprv !== 'string') {
        xprv = xprv.toString('hex')
    }
    var keyPair = eddsa.keyFromSecret(utils.parseBytes(xprv).slice(0, 32));
    var sig = keyPair.sign(message);
    return Buffer.from(sig.toBytes());
}

function verify(message, sig, xpub) {
    if (typeof xpub !== 'string') {
        xpub = xpub.toString('hex')
    }
    return eddsa.verify(message, sig.toString('hex'), utils.parseBytes(xpub).slice(0, 32));
}

module.exports = {
    fromSeed2: fromSeed2,
    fromSeed: generateFromSeed,
    generateFromSeed: generateFromSeed,
    derivePrivate: derivePrivate,
    derivePublic: derivePublic,
    toPublic: toPublic,
    eddsa: eddsa,
    sign: sign,
    verify: verify
};
