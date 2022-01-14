class AppUtils {
  /// The App will set this function for plugins switch between each other
  Future<void> Function(String network, {String? pageRoute})? switchNetwork;
}
