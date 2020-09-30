import 'package:mobx/mobx.dart';
import 'package:polkawallet_sdk/api/types/balanceData.dart';

part 'balances.g.dart';

class BalancesStore = BalancesStoreBase with _$BalancesStore;

abstract class BalancesStoreBase with Store {
  @observable
  BalanceData native;

  @observable
  List<TokenBalanceData> tokens;

  @observable
  List<ExtraTokenData> extraTokens;

  @action
  void setBalance(BalanceData data) {
    native = data;
  }

  @action
  void setTokens(List<TokenBalanceData> ls) {
    tokens = ls;
  }

  @action
  void setExtraTokens(List<ExtraTokenData> ls) {
    extraTokens = ls;
  }
}

class ExtraTokenData {
  ExtraTokenData({this.title, this.tokens});
  final String title;
  final List<TokenBalanceData> tokens;
}

class TokenBalanceData {
  TokenBalanceData({this.name, this.symbol, this.amount, this.assetPageRoute});

  final String name;
  final String symbol;
  final String amount;

  final String assetPageRoute;
}
