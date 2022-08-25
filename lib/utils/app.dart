class AppUtils {
  /// The App will set this function for plugins switch between each other
  /// accountType(0:Substrate,1:evm)
  Future<void> Function(String network,
      {PageRouteParams? pageRoute, int accountType})? switchNetwork;
}

class PageRouteParams {
  PageRouteParams(this.path, {this.args});

  final String path;
  final Map? args;
}
