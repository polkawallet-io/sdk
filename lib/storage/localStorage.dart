import 'package:get_storage/get_storage.dart';

const String sdk_storage_key = 'polka_wallet_sdk';
const String sdk_evm_storage_key = 'polka_wallet_sdk_evm';

/// this is where we save keyPairs locally
class KeyringStorage {
  static final _storage = () => GetStorage(sdk_storage_key);

  final keyPairs = [].val('keyPairs', getBox: _storage);
  final contacts = [].val('contacts', getBox: _storage);
  final ReadWriteValue<String?> currentPubKey =
      ''.val('currentPubKey', getBox: _storage);
  final encryptedRawSeeds = {}.val('encryptedRawSeeds', getBox: _storage);
  final encryptedMnemonics = {}.val('encryptedMnemonics', getBox: _storage);
}

class KeyringEVMStorage {
  static final _storage = () => GetStorage(sdk_evm_storage_key);

  final keyPairs = [].val('keyPairs', getBox: _storage);
  final contacts = [].val('contacts', getBox: _storage);
  final ReadWriteValue<String?> currentAddress =
      ''.val('currentAddress', getBox: _storage);
  final encryptedPrivateKeys = {}.val('encryptedPrivateKeys', getBox: _storage);
  final encryptedMnemonics = {}.val('encryptedMnemonics', getBox: _storage);
}
