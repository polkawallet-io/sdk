import 'package:get_storage/get_storage.dart';

/// this is where we save keyPairs locally
class KeyringStorage {
  GetStorage _storage = GetStorage('keyring');

  final keyPairs = [].val('keyPairs');
}
