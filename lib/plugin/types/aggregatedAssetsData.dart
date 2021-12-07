class AggregatedAssetsData {
  String? category;
  List<AggregatedAssetsItemData>? assets;
  double? value;

  String toString() {
    return '{'
        '\n  category: $category,'
        '\n  value: $value,'
        '\n  assets: ['
        '${assets?.map((e) => e.toString()).join(',')},'
        '\n  ],'
        '\n}';
  }
}

class AggregatedAssetsItemData {
  String? token;
  double? amount;
  double? value;

  String toString() {
    return '  {'
        '\n    token: $token,'
        '\n    amount: $amount,'
        '\n    value: $value,'
        '\n  }';
  }
}
