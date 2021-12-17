import 'package:mobx/mobx.dart';
import 'package:polkawallet_sdk/api/types/balanceData.dart';

part 'balances.g.dart';

class BalancesStore = BalancesStoreBase with _$BalancesStore;

abstract class BalancesStoreBase with Store {
  @observable
  BalanceData? native;

  @observable
  List<TokenBalanceData> tokens = [];

  @observable
  bool isTokensFromCache = false;

  @observable
  List<ExtraTokenData>? extraTokens;

  @action
  void setBalance(BalanceData data) {
    native = data;
  }

  @action
  void setTokens(List<TokenBalanceData> ls, {bool isFromCache = false}) {
    final data = ls;
    if (!isFromCache) {
      tokens.toList().forEach((old) {
        final newDataIndex = ls.indexWhere(
            (token) => token.symbol == old.symbol || token.symbol == old.id);
        if (newDataIndex < 0) {
          data.add(old);
        }
      });
    }

    data.removeWhere((e) => e.symbol!.contains('-') && e.amount == '0');
    data.sort((a, b) => a.symbol!.contains('-')
        ? 1
        : b.symbol!.contains('-')
            ? -1
            : a.symbol!.compareTo(b.symbol!));

    tokens = data;
    isTokensFromCache = isFromCache;
  }

  @action
  void setExtraTokens(List<ExtraTokenData> ls) {
    extraTokens = ls;
  }
}

class ExtraTokenData {
  ExtraTokenData({this.title, this.tokens});
  final String? title;
  final List<TokenBalanceData>? tokens;
}

/// none-native token data
/// 1. [id] foreign asset id (Acala tokens module).
/// 2. [name] <kUSD> for Karura USD.
/// 3. [symbol] <KUSD> for Karura USD.
/// 4. [fullName] <Karura US Dollar> for Karura USD.
/// 5. [type] <Token | DexShare | ForeignAsset> for Karura tokens.
class TokenBalanceData {
  TokenBalanceData({
    this.id,
    this.name,
    this.symbol,
    this.type = 'Token',
    this.minBalance,
    this.fullName,
    this.decimals,
    this.amount,
    this.locked,
    this.reserved,
    this.detailPageRoute,
    this.price,
  });

  final String? id;
  final String? name;
  final String? symbol;
  final String type;
  final String? minBalance;
  final String? fullName;
  final int? decimals;
  String? amount;
  final String? locked;
  final String? reserved;

  String? detailPageRoute;
  final double? price;
}
