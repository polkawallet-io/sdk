var should = require('should');

var bip32Edd25519 = require('../index');
var eddsa = bip32Edd25519.eddsa;

describe('derive', function() {

    this.timeout(5 * 60 * 60 * 1000);

    it('general', function(done) {
        var seed = Buffer.from('e2282f95e0c16a0f2837553c9000c22c82d87e667b5ded17b26d15bdb60245f0e89067d412aa8c41caa4dfbbdcf8fd3095cb974c0104bc0a9309491f929681e1', 'hex');
        var xprv = bip32Edd25519.generateFromSeed(seed);
        console.log('xprv:', xprv.toString('hex'));

        var xpub = bip32Edd25519.toPublic(xprv);
        console.log('xpub:', xpub.toString('hex'));

        var total = 10000000;
        for (var i = 0; i < 100000; i++) {
            var index = parseInt(Math.random() * 100000);
            console.log('[' + i + '/' + total + '] ' + index);
            var derivedPrivateKey = bip32Edd25519.derivePrivate(xprv, index);
            var derivedPublicKey = bip32Edd25519.derivePublic(xpub, index);
            var toPublicKey = bip32Edd25519.toPublic(derivedPrivateKey);

            should.equal(derivedPublicKey.toString('hex'), toPublicKey.toString('hex'));

            const keyPair = eddsa.keyFromSecret(derivedPrivateKey.slice(0, 32));
            var publicKey = Buffer.from(keyPair.getPublic(true, true));
            should.equal(derivedPublicKey.slice(0, 32).toString('hex'), publicKey.toString('hex'));

            var message = Buffer.from('hello world');
            var sig = bip32Edd25519.sign(message, derivedPrivateKey);
            var verify = bip32Edd25519.verify(message, sig, derivedPublicKey);
            should.equal(verify, true, 'verify failed: index=' + index)
        }

        done();
    });

    it('derive', function(done) {
        var seed = Buffer.from('3660a6289d878f317fa7b180ce0b375178bd5ffe0ada03fca6905255fe25028166c802750d85f90bb0123b07608bbcfbc6b1be84519d68f37935e2a2a4b43cfe', 'hex');
        var path = 'm/53686/60791/4984';

        var xprv = bip32Edd25519.generateFromSeed(seed);
        console.log('xprv:', xprv.toString('hex'));

        var xpub = bip32Edd25519.toPublic(xprv);
        console.log('xpub:', xpub.toString('hex'));

        var indexes = path.split('/').slice(1);
        var xprv = bip32Edd25519.generateFromSeed(seed);
        var xpub = bip32Edd25519.toPublic(xprv);

        var derivedPrivateKey = xprv;
        var derivedPublicKey = xpub;

        for (var j = 0; j < indexes.length; j++) {
            derivedPrivateKey = bip32Edd25519.derivePrivate(derivedPrivateKey, parseInt(indexes[j]));
            derivedPublicKey = bip32Edd25519.derivePublic(derivedPublicKey, parseInt(indexes[j]));

            const keyPair = eddsa.keyFromSecret(derivedPrivateKey.slice(0, 32));
            var publicKey = Buffer.from(keyPair.getPublic(true, true));
            should.equal(derivedPublicKey.slice(0, 32).toString('hex'), publicKey.toString('hex'));

            var message = Buffer.from('hello world');
            var sig = bip32Edd25519.sign(message, derivedPrivateKey);
            var verify = bip32Edd25519.verify(message, sig, derivedPublicKey);
            should.equal(verify, true, 'verify failed')
        }

        done();
    });
});
