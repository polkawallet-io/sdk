import 'package:get_storage/get_storage.dart';

/// this is where we save keyPairs locally
class KeyringStorage {
  static final _storage = () => GetStorage('keyring');

  final keyPairs = [].val('keyPairs', getBox: _storage);
  final encryptedRawSeeds = {}.val('encryptedRawSeeds', getBox: _storage);
  final encryptedMnemonics = {}.val('encryptedMnemonics', getBox: _storage);
}
