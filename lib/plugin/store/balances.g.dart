// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balances.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$BalancesStore on BalancesStoreBase, Store {
  late final _$nativeAtom =
      Atom(name: 'BalancesStoreBase.native', context: context);

  @override
  BalanceData? get native {
    _$nativeAtom.reportRead();
    return super.native;
  }

  @override
  set native(BalanceData? value) {
    _$nativeAtom.reportWrite(value, super.native, () {
      super.native = value;
    });
  }

  late final _$tokensAtom =
      Atom(name: 'BalancesStoreBase.tokens', context: context);

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

  late final _$isTokensFromCacheAtom =
      Atom(name: 'BalancesStoreBase.isTokensFromCache', context: context);

  @override
  bool get isTokensFromCache {
    _$isTokensFromCacheAtom.reportRead();
    return super.isTokensFromCache;
  }

  @override
  set isTokensFromCache(bool value) {
    _$isTokensFromCacheAtom.reportWrite(value, super.isTokensFromCache, () {
      super.isTokensFromCache = value;
    });
  }

  late final _$extraTokensAtom =
      Atom(name: 'BalancesStoreBase.extraTokens', context: context);

  @override
  List<ExtraTokenData>? get extraTokens {
    _$extraTokensAtom.reportRead();
    return super.extraTokens;
  }

  @override
  set extraTokens(List<ExtraTokenData>? value) {
    _$extraTokensAtom.reportWrite(value, super.extraTokens, () {
      super.extraTokens = value;
    });
  }

  late final _$BalancesStoreBaseActionController =
      ActionController(name: 'BalancesStoreBase', context: context);

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
  void setTokens(List<TokenBalanceData> ls, {bool isFromCache = false}) {
    final _$actionInfo = _$BalancesStoreBaseActionController.startAction(
        name: 'BalancesStoreBase.setTokens');
    try {
      return super.setTokens(ls, isFromCache: isFromCache);
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
isTokensFromCache: ${isTokensFromCache},
extraTokens: ${extraTokens}
    ''';
  }
}
