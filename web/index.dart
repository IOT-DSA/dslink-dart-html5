library dslink_html5;

import 'dart:html' as dom;
import 'dart:async';

import 'package:dslink/browser.dart';

import 'package:mdl/mdl.dart';
import 'package:mdl/mdlobservable.dart';
import 'package:di/di.dart' as di;

import 'package:dslink_html5/dialogs.dart';

/// Manages the link and nodes to DSLink
class Html5Link {
  static String DEFAULT_BROKER;
  /// Default name for the link
  static const DEFAULT_NAME = "HTML5";
  /// Default nodes provided by the link
  static final DEFAULT_NODES = {
    "Message": {
      r"$type": "string",
      "?value": ""
    },
    "Geolocation": {
      "Latitude": {
        r"$type": "number",
        "?value": 0.0
      },
      "Longitude": {
        r"$type": "number",
        "?value": 0.0
      },
      "Heading": {
        r"$type": "number",
        "?value": 0.0
      },
      "Altitude": {
        r"$type": "number",
        "?value": 0.0
      },
      "Speed": {
        r"$type": "number",
        "?value": 0.0
      }
    },
    "Accelerometer": {
      "Alpha": {
        r"$type": "number",
        "?value": 0.0
      },
      "Beta": {
        r"$type": "number",
        "?value": 0.0
      },
      "Gamma": {
        r"$type": "number",
        "?value": 0.0
      }
    },
    "Text_Display": {
      r"$name": "Text Display",
      "Visible": {
        r"$type": "bool",
        r"$writable": "write",
        "?value": false
      },
      "Text_Size": {
        r"$name": "Text Size",
        r"$type": "number",
        r"$writable": "write"
      },
      "Text": {
        r"$name": "Text",
        r"$type": "string",
        r"$writable": "write",
        "?value": ""
      }
    }
  };

  String currentName;
  String currentBroker;
  LinkProvider link;
  SimpleNode latitudeNode;
  SimpleNode longitudeNode;
  SimpleNode headingNode;
  SimpleNode altitudeNode;
  SimpleNode speedNode;
  SimpleNode alphaNode;
  SimpleNode betaNode;
  SimpleNode gammaNode;
  SimpleNode batteryNode;
  SimpleNodeProvider provider;

  Html5Model model;
  TextDisplayDialog textDialog;

  Html5Link(this.model, this.textDialog) {
    provider = new SimpleNodeProvider();
  }

  Future initialize() async {
    DEFAULT_BROKER = await BrowserUtils.fetchBrokerUrlFromPath("broker_url", "http://localhost:8080/conn");
    if (dom.window.localStorage.containsKey("log_level")) {
      var l = dom.window.localStorage["log_level"];
      updateLogLevel(l);
    }
    if (dom.window.localStorage.containsKey("broker_url")) {
      currentBroker = dom.window.localStorage["broker_url"];
    } else {
      currentBroker = DEFAULT_BROKER;
    }
    if (dom.window.localStorage.containsKey("link_name")) {
      currentName = dom.window.localStorage["link_name"];
    } else {
      currentName = DEFAULT_NAME;
    }

    link = new LinkProvider(currentBroker, "${currentName}-",
        defaultNodes: DEFAULT_NODES, provider: provider);
    await link.init();
    latitudeNode = provider.getNode("/Geolocation/Latitude");
    longitudeNode = provider.getNode("/Geolocation/Longitude");
    headingNode = provider.getNode("/Geolocation/Heading");
    altitudeNode = provider.getNode("/Geolocation/Altitude");
    speedNode = provider.getNode("/Geolocation/Speed");
    alphaNode = provider.getNode("/Accelerometer/Alpha");
    betaNode = provider.getNode("/Accelerometer/Beta");
    gammaNode = provider.getNode("/Accelerometer/Gamma");

    dom.window.navigator.geolocation.watchPosition(
        enableHighAccuracy: true,
        timeout: const Duration(seconds: 60),
        maximumAge: const Duration(seconds: 0)
    ).listen(positionUpdated).onError((error) {
      print(error.message);
    });
    dom.window.on['deviceorientation'].listen(orientationUpdated);

    provider.getNode("/Text_Display/Visible").subscribe((ValueUpdate update) {
      if (update.value) {
        textDialog.show().then((status) {
          provider.updateValue('/Text_Display/Visible', false);
        });
      } else {
        textDialog.close(MdlDialogStatus.OK);
      }
    });

    var textSizeNode = provider.getNode("/Text_Display/Text_Size");
    textSizeNode.subscribe((ValueUpdate update) {
      textDialog.fontSize.value = update.value;
    });

    textSizeNode.updateValue(textDialog.fontSize.value);
    provider.getNode("/Text_Display/Text").subscribe((ValueUpdate update) {
      textDialog.text.value = update.value.toString();
    });
  }

  Future connect() async {
    link.close();
    link.brokerUrl = currentBroker;
    link.prefix = '${currentName}-';
    await link.init();
    link.connect();
  }

  /// Event handler for geolocation.watchPosition
  void positionUpdated(update) {
    var coords = update.coords;
    latitudeNode.updateValue(coords.latitude);
    longitudeNode.updateValue(coords.longitude);
    headingNode.updateValue(coords.heading);
    altitudeNode.updateValue(coords.altitude);
    speedNode.updateValue(coords.speed);

    model.latitude.value = coords.latitude.toStringAsFixed(7);
    model.longitude.value = coords.longitude.toStringAsFixed(7);
    if(coords.heading != null) {
      model.heading.value = coords.heading.toStringAsFixed(7);
    }
    if(coords.speed != null) {
      model.speed.value = coords.speed.toStringAsFixed(7);
    }
    print('Lat & lon Updated');
  }

  /// Event handler for device orientation
  void orientationUpdated(dom.DeviceOrientationEvent event) {
    if(event.alpha != null) {
      alphaNode.updateValue(event.alpha);
      model.alpha.value = event.alpha.toStringAsFixed(7);
    }
    if (event.beta != null) {
      betaNode.updateValue(event.beta);
      model.beta.value = event.beta.toStringAsFixed(7);
    }
    if (event.gamma != null) {
      gammaNode.updateValue(event.gamma);
      model.gamma.value = event.gamma.toStringAsFixed(7);
    }
  }

  /// Triggered by OK response to Message Dialog
  void sendReply(String message) {
    provider.updateValue('/Message', message);
  }

  /// Triggered by OK response to Settings Dialog
  void updateSettings(String broker, String name) {
    if (currentBroker != broker || currentName != name) {
      currentBroker = broker;
      currentName = name;
      dom.window.localStorage["broker_url"] = currentBroker;
      dom.window.localStorage["link_name"] = currentName;
      connect();
    }
  }
}

/// Model class to encapsulate HTML 5 data
@MdlComponentModel
class Html5Model {
  ObservableProperty<String> latitude = new ObservableProperty<String>("");
  ObservableProperty<String> longitude = new ObservableProperty<String>("");
  ObservableProperty<String> heading = new ObservableProperty<String>("");
  ObservableProperty<String> speed = new ObservableProperty<String>("");
  ObservableProperty<String> alpha = new ObservableProperty<String>("");
  ObservableProperty<String> beta = new ObservableProperty<String>("");
  ObservableProperty<String> gamma = new ObservableProperty<String>("");
  dom.DivElement latContent;
  dom.DivElement lonContent;
  dom.DivElement headContent;
  dom.DivElement speedContent;
  dom.DivElement alphaContent;
  dom.DivElement betaContent;
  dom.DivElement gammaContent;

  Html5Model() {
    latContent = dom.querySelector('#latitude');
    lonContent = dom.querySelector('#longitude');
    headContent = dom.querySelector('#heading');
    speedContent = dom.querySelector('#speed');
    alphaContent = dom.querySelector('#alpha');
    betaContent = dom.querySelector('#beta');
    gammaContent = dom.querySelector('#gamma');

    latitude.onChange.listen((event) {
      latContent.text = 'Latitude: ${event.value}';
    });
    longitude.onChange.listen((event) {
      lonContent.text = 'Longitude: ${event.value}';
    });
    heading.onChange.listen((event) {
      _checkVisibility(headContent, event.value);
      headContent.text = 'Heading: ${event.value}';
    });
    speed.onChange.listen((event) {
      _checkVisibility(speedContent, event.value);
      speedContent.text = 'Speed: ${event.value}';
    });
    alpha.onChange.listen((event) {
      _checkVisibility(alphaContent, event.value);
      alphaContent.text = 'Alpha: ${event.value}';
    });
    beta.onChange.listen((event) {
      _checkVisibility(betaContent, event.value);
      betaContent.text = 'Beta: ${event.value}';
    });
    gamma.onChange.listen((event) {
      _checkVisibility(gammaContent, event.value);
      gammaContent.text = 'Gamma: ${event.value}';
    });
  }

  void _checkVisibility(dom.DivElement el, String value) {
    if(value != null && value.isNotEmpty) {
      el.hidden = false;
    } else {
      el.hidden = true;
    }
  }
}

@MdlComponentModel @di.Injectable()
class Application extends MaterialApplication {
  ReplyDialog replyDialog;
  SettingsDialog settingsDialog;
  TextDisplayDialog textDialog;

  Application() {
    replyDialog = new ReplyDialog();
    settingsDialog = new SettingsDialog();
    textDialog = new TextDisplayDialog();
  }

  @override
  run() async {
    final Html5Model model = new Html5Model();
    final Html5Link myLink = new Html5Link(model, textDialog);
    final replyBtn = MaterialButton.widget(dom.querySelector('#replybtn'));
    final settingsBtn = MaterialButton.widget(dom.querySelector('#settingsbtn'));

    replyBtn.onClick.listen((_) {
      replyDialog(title: 'Reply').show().then((MdlDialogStatus status) {
        if(status == MdlDialogStatus.OK) {
          myLink.sendReply(replyDialog.replyValue.value);
        }
      });
    });
    settingsBtn.onClick.listen((_) {
      settingsDialog(title: 'Settings').show().then((MdlDialogStatus status) {
        if(status == MdlDialogStatus.OK) {
          var broker = settingsDialog.brokerUrl.value;
          var name = settingsDialog.linkName.value;
          myLink.updateSettings(broker, name);
        }
      });
    });
    await myLink.initialize();
    myLink.connect();
  }
}

main() {
  registerMdl();
  var application = componentFactory().rootContext(Application).run()
    .then((Application app) {
    return app.run();
  });
}