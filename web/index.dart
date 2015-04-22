import "dart:html";

import "package:dslink/browser_client.dart";
import "package:dslink/responder.dart";
import "package:dslink/src/crypto/pk.dart";

import "package:polymer/polymer.dart";

import "package:paper_elements/paper_dialog.dart";

const String DEFAULT_BROKER = "http://127.0.0.1:8080/conn";

BrowserECDHLink link;
SimpleNode latitudeNode;
SimpleNode longitudeNode;
SimpleNode headingNode;
SimpleNode altitudeNode;
SimpleNode speedNode;
SimpleNode alphaNode;
SimpleNode betaNode;
SimpleNode gammaNode;
SimpleNode batteryNode;
SimpleNodeProvider provider = new SimpleNodeProvider();

LinkModel model;
PrivateKey key;

main() async {
  var zone = await initPolymer();
  await zone.run(() async {
    await Polymer.onReady;
    await initialize();
    await connect();
  });
}

initialize() async {
  model = new LinkModel();
  AutoBindingElement mainTemplate = querySelector("#main-template");
  mainTemplate.model = model;

  var defaultNodes = {
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
    }
  };

  if (window.localStorage.containsKey("dsa_key")) {
    key = new PrivateKey.loadFromString(window.localStorage["dsa_key"]);
  } else {
    key = new PrivateKey.generate();
    window.localStorage["dsa_key"] = key.saveToString();
  }

  if (window.localStorage.containsKey("broker_url")) {
    currentBroker = window.localStorage["broker_url"];
  } else {
    currentBroker = DEFAULT_BROKER;
  }

  provider.init(defaultNodes);

  latitudeNode = provider.getNode("/Geolocation/Latitude");
  longitudeNode = provider.getNode("/Geolocation/Longitude");
  headingNode = provider.getNode("/Geolocation/Heading");
  altitudeNode = provider.getNode("/Geolocation/Altitude");
  speedNode = provider.getNode("/Geolocation/Speed");
  alphaNode = provider.getNode("/Accelerometer/Alpha");
  betaNode = provider.getNode("/Accelerometer/Beta");
  gammaNode = provider.getNode("/Accelerometer/Gamma");

  window.navigator.geolocation.watchPosition(
      enableHighAccuracy: true,
      timeout: new Duration(seconds: 60),
      maximumAge: new Duration(seconds: 0)
  ).listen((update) {
    var coords = update.coords;

    latitudeNode.updateValue(coords.latitude);
    longitudeNode.updateValue(coords.longitude);
    headingNode.updateValue(coords.heading);
    altitudeNode.updateValue(coords.altitude);
    speedNode.updateValue(coords.speed);

    model.latitude = coords.latitude.toStringAsFixed(7);
    model.longitude = coords.longitude.toStringAsFixed(7);
    if (coords.heading != null) {
      querySelector("#heading-box").hidden = false;
      model.heading = coords.heading.toStringAsFixed(7);
    } else {
      querySelector("#heading-box").hidden = true;
    }

    if (coords.speed != null) {
      querySelector("#speed-box").hidden = false;
      model.speed = coords.speed.toStringAsFixed(7);
    } else {
      querySelector("#speed-box").hidden = true;
    }
  });

  window.on["deviceorientation"].listen((DeviceOrientationEvent event) {
    if (event.alpha != null) {
      alphaNode.updateValue(event.alpha);
      model.alpha = event.alpha.toStringAsFixed(7);
      querySelector("#alpha-box").hidden = false;
    } else {
      querySelector("#alpha-box").hidden = true;
    }

    if (event.beta != null) {
      betaNode.updateValue(event.beta);
      model.beta = event.beta.toStringAsFixed(7);
      querySelector("#beta-box").hidden = false;
    } else {
      querySelector("#beta-box").hidden = true;
    }

    if (event.gamma != null) {
      gammaNode.updateValue(event.gamma);
      model.gamma = event.gamma.toStringAsFixed(7);
      querySelector("#gamma-box").hidden = false;
    } else {
      querySelector("#gamma-box").hidden = true;
    }
  });
}

connect() async {
  if (link != null) {
    link.close();
  }

  link = new BrowserECDHLink(
    currentBroker,
    "WebBrowser-",
    key,
    isResponder: true,
    isRequester: false,
    nodeProvider: provider
  );

  link.connect();
}

String currentBroker;

class LinkModel extends Observable {
  @observable
  String latitude = "Unknown";

  @observable
  String longitude = "Unknown";

  @observable
  String heading = "Unknown";

  @observable
  String speed = "Unknown";

  @observable
  String alpha = "Unknown";

  @observable
  String beta = "Unknown";

  @observable
  String gamma = "Unknown";

  void openSettings() {
    var dialog = querySelector("#settings-dialog") as PaperDialog;
    dialog.toggle();
  }

  void closeSettings() {
    var dialog = querySelector("#settings-dialog") as PaperDialog;
    dialog.toggle();

    var settingBroker = querySelector("#setting-broker");
    var broker = settingBroker.value;
    if (currentBroker != broker) {
      currentBroker = broker;
      window.localStorage["broker_url"] = currentBroker;
      connect();
    }
  }
}
