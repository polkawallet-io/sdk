// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balances.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$BalancesStore on BalancesStoreBase, Store {
  final _$nativeAtom = Atom(name: 'BalancesStoreBase.native');

  @override
  BalanceData get native {
    _$nativeAtom.reportRead();
    return super.native;
  }

  @override
  set native(BalanceData value) {
    _$nativeAtom.reportWrite(value, super.native, () {
      super.native = value;
    });
  }

  final _$tokensAtom = Atom(name: 'BalancesStoreBase.tokens');

  @override
  List<TokenBalanceData> get tokens {
    _$tokensAtom.reportRead();
    return super.tokens;
  }

  @override
  set tokens(List<TokenBalanceData> value) {
    _$tokensAtom.reportWrite(value, super.tokens, () {
      super.tokens = value;
    });
  }

  final _$extraTokensAtom = Atom(name: 'BalancesStoreBase.extraTokens');

  @override
  List<ExtraTokenData> get extraTokens {
    _$extraTokensAtom.reportRead();
    return super.extraTokens;
  }

  @override
  set extraTokens(List<ExtraTokenData> value) {
    _$extraTokensAtom.reportWrite(value, super.extraTokens, () {
      super.extraTokens = value;
    });
  }

  final _$BalancesStoreBaseActionController =
      ActionController(name: 'BalancesStoreBase');

  @override
  void setBalance(BalanceData data) {
    final _$actionInfo = _$BalancesStoreBaseActionController.startAction(
        name: 'BalancesStoreBase.setBalance');
    try {
      return super.setBalance(data);
    } finally {
      _$BalancesStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setTokens(List<TokenBalanceData> ls) {
    final _$actionInfo = _$BalancesStoreBaseActionController.startAction(
        name: 'BalancesStoreBase.setTokens');
    try {
      return super.setTokens(ls);
    } finally {
      _$BalancesStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setExtraTokens(List<ExtraTokenData> ls) {
    final _$actionInfo = _$BalancesStoreBaseActionController.startAction(
        name: 'BalancesStoreBase.setExtraTokens');
    try {
      return super.setExtraTokens(ls);
    } finally {
      _$BalancesStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
native: ${native},
tokens: ${tokens},
extraTokens: ${extraTokens}
    ''';
  }
}
