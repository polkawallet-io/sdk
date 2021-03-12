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
  polkawallet_sdk: ^0.1.2
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
 - acala: [https://github.com/polkawallet-io/polkawallet_plugin_acala/tree/master/lib/js_service_acala](https://github.com/polkawallet-io/polkawallet_plugin_acala/tree/master/lib/js_service_acala)
 - laminar: [https://github.com/polkawallet-io/polkawallet_plugin_laminar/tree/master/lib/polkawallet_plugin_laminar](https://github.com/polkawallet-io/polkawallet_plugin_laminar/tree/master/lib/polkawallet_plugin_laminar)

## 3. Implement your plugin class

Modify the plugin entry file(eg. polkwalllet_plugin_acala.dart),
create a `PluginFoo` class extending `PolkawalletPlugin`:
```dart
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
    gradientColor: Colors.blue,
    // The `bg.png` will be displayed as texture on a block with theme color,
    // so it should have a transparent or dark background color.
    backgroundImage: AssetImage('packages/polkawallet_plugin_acala/assets/images/bg.png'),
    icon:
        Image.asset('packages/polkawallet_plugin_acala/assets/images/logo.png'),
    // The `logo_gray.png` should have a gray color `#9e9e9e`.
    iconDisabled: Image.asset(
        'packages/polkawallet_plugin_acala/assets/images/logo_gray.png'),
    isTestNet: false,
  );
```

#### 3.2. override `PolkawalletPlugin.tokenIcons`
Define the icon widgets so the Polkawallet App can display tokens
of your para-chain with token icons.
```dart
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
```dart
  @override
  List<HomeNavItem> getNavItems(BuildContext context, Keyring keyring) {
    return [
      HomeNavItem(
        text: 'Acala',
        icon: SvgPicture.asset(
          'packages/polkawallet_plugin_acala/assets/images/logo.svg',
          color: Theme.of(context).disabledColor,
        ),
        iconActive: SvgPicture.asset(
            'packages/polkawallet_plugin_acala/assets/images/logo.svg'),
        content: AcalaEntry(this, keyring),
      )
    ];
  }
```

#### 3.5. override `PolkawalletPlugin.getRoutes(Keyring)`
Define navigation route for your plugin pages.
```dart
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
```dart
  @override
  Future<String> loadJSCode() => rootBundle.loadString(
      'packages/polkawallet_plugin_acala/lib/js_service_acala/dist/main.js');
```

#### 3.7. override plugin life-circle methods
 - onWillStart(), you may want to prepare your plugin state data here.
 - onStarted(), remote node connected, you may fetch data from network.
 - onAccountChanged(), user just changed account, you may clear
 cache of the prev account and query data for new account.

Examples:
 - [kusama/polkadot](https://github.com/polkawallet-io/polkawallet_plugin_kusama/blob/master/lib/polkawallet_plugin_kusama.dart)
 - [acala](https://github.com/polkawallet-io/polkawallet_plugin_acala/blob/master/lib/polkawallet_plugin_acala.dart)
 - [laminar](https://github.com/polkawallet-io/polkawallet_plugin_laminar/blob/master/lib/polkawallet_plugin_laminar.dart)

## 4. Fetch data and build pages

We use [https://pub.dev/packages/mobx](https://pub.dev/packages/mobx) as the App state management tool.
 So the directories in a plugin looks like this:

```
__ lib
    |__ pages (the UI)
    |__ store (the MobX store)
    |__ service (the Actions fired by UI to mutate the store)
    |__ ...
```
To query data through `PolkawalletPlugin.sdk.api`:

(`polkawallet-io/polkawallet_plugin_kusama/lib/service/gov.dart`)
```dart
  Future<List> queryReferendums() async {
    final data = await api.gov.queryReferendums(keyring.current.address);
    store.gov.setReferendums(data);
    return data;
  }
```
To query data by calling JS directly:

(`polkawallet-io/polkawallet_plugin_kusama/lib/service/gov.dart`)
```dart
  Future<void> updateBestNumber() async {
    final int bestNumber = await api.service.webView
        .evalJavascript('api.derive.chain.bestNumber()');
    store.gov.setBestNumber(bestNumber);
  }
```

While we set data to MobX store, the MobX Observer Flutter Widget will rebuild with new data.

## 5. Run your pages in `example/` app
You may want to run an example app in dev while building your plugin pages.

See the `kusama/polkadot` or `acala` or `laminar` examples:
 - [kusama/polkadot](https://github.com/polkawallet-io/polkawallet_plugin_kusama)
 - [acala](https://github.com/polkawallet-io/polkawallet_plugin_acala)
 - [laminar](https://github.com/polkawallet-io/polkawallet_plugin_laminar)