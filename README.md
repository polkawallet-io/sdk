# sdk
polkawallet SDK for integrating substrate-based blockchain as a plugin.

# Building a polkawallet_plugin dart package.

## 1. Create your plugin repo

create a dart package
```shell
flutter create --template=package polkwalllet_plugin_acala
cd polkwalllet_plugin_acala/
```
add dependencies in pubspec.yaml
```yaml
dependencies:
  polkawallet_sdk:
    git:
      url: https://github.com/polkawallet-io/sdk.git
      ref: master
```
and install the dependencies.
```shell
flutter pub get
```

## 2. Build your polkadot-js wrapper

The App use a `polkadot-js/api` instance running in a hidden webView
to connect to remote node.

Examples:
 - kusama/polkadot: [https://github.com/polkawallet-io/js_api](https://github.com/polkawallet-io/js_api)
 - acala-network: [https://github.com/polkawallet-io/polkawallet_plugin_acala/tree/master/lib/js_service_acala](https://github.com/polkawallet-io/polkawallet_plugin_acala/tree/master/lib/js_service_acala)

## 3. Implement your plugin class

Modify the plugin entry file(eg. polkwalllet_plugin_acala.dart),
create a `PluginFoo` class extending `PolkawalletPlugin`:
```
class PluginAcala extends PolkawalletPlugin {
  /// define your own plugin
}
```

#### 3.1. override `PolkawalletPlugin.basic`
```dart
  @override
  final basic = PluginBasicData(
    name: 'acala',
    ss58: 42,
    primaryColor: Colors.deepPurple,
    icon:
        Image.asset('packages/polkawallet_plugin_acala/assets/images/logo.png'),
    iconDisabled: Image.asset(
        'packages/polkawallet_plugin_acala/assets/images/logo_gray.png'),
  );
```

#### 3.2. override `PolkawalletPlugin.tokenIcons`
Define the icon widgets so the Polkawallet App can display tokens
of your para-chain with token icons.
```
  @override
  final Map<String, Widget> tokenIcons = {
    'KSM': Image.asset(
        'packages/polkawallet_plugin_kusama/assets/images/tokens/KSM.png'),
    'DOT': Image.asset(
        'packages/polkawallet_plugin_kusama/assets/images/tokens/DOT.png'),
  };
```

#### 3.3. override `PolkawalletPlugin.nodeList`

```dart
const node_list = [
  {
    'name': 'Mandala TC5 Node 1 (Hosted by OnFinality)',
    'ss58': 42,
    'endpoint': 'wss://node-6714447553777491968.jm.onfinality.io/ws',
  },
];
```
```dart
  @override
  List<NetworkParams> get nodeList {
    return node_list.map((e) => NetworkParams.fromJson(e)).toList();
  }
```

#### 3.4. override `PolkawalletPlugin.getNavItems(BuildContext, Keyring)`
Define your custom navigation-item in `BottomNavigationBar` of Polkawallet App.
The `HomeNavItem.content` is the page content widget displayed while your navItem was selected.
```
  @override
  List<HomeNavItem> getNavItems(BuildContext context, Keyring keyring) {
    return [
      HomeNavItem(
        text: 'Acala',
        icon: Image(
            image: AssetImage('assets/images/acala_dark.png',
                package: 'polkawallet_plugin_acala')),
        iconActive: Image(
            image: AssetImage('assets/images/acala_indigo.png',
                package: 'polkawallet_plugin_acala')),
        content: AcalaEntry(this, keyring),
      )
    ];
  }
```

#### 3.5. override `PolkawalletPlugin.getRoutes(Keyring)`
Define navigation route for your plugin pages.
```
  @override
  Map<String, WidgetBuilder> getRoutes(Keyring keyring) {
    return {
      TxConfirmPage.route: (_) =>
          TxConfirmPage(this, keyring, _service.getPassword),
      CurrencySelectPage.route: (_) => CurrencySelectPage(this),
      AccountQrCodePage.route: (_) => AccountQrCodePage(this, keyring),

      TokenDetailPage.route: (_) => TokenDetailPage(this, keyring),
      TransferPage.route: (_) => TransferPage(this, keyring),

      // other pages
      // ...
    };
  }
```

#### 3.6. override `PolkawalletPlugin.loadJSCode()` method
Load the `polkadot-js/api` wrapper you built in step 2.
```
  @override
  Future<String> loadJSCode() => rootBundle.loadString(
      'packages/polkawallet_plugin_acala/lib/js_service_acala/dist/main.js');
```