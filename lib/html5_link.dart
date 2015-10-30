library dslink.html5.link;

import 'dart:async';
import 'dart:html';
import 'package:dslink/browser.dart';

/// Provides the link to the DSA/Broker.
class Html5Link {
  /// Default nodes provided by the link
  static final defaultNodes = {
    "Message": {r"$type": "string", "?value": ""},
    "Geolocation": {
      "Latitude": {r"$type": "number", "?value": 0.0},
      "Longitude": {r"$type": "number", "?value": 0.0},
      "Heading": {r"$type": "number", "?value": 0.0},
      "Altitude": {r"$type": "number", "?value": 0.0},
      "Speed": {r"$type": "number", "?value": 0.0}
    },
    "Accelerometer": {
      "Orientation": {
        "Alpha": {r"$type": "number", "?value": 0.0},
        "Beta": {r"$type": "number", "?value": 0.0},
        "Gamma": {r"$type": "number", "?value": 0.0}
      },
      "Motion": {
        "Acceleration": {
          "X": {r"$type": "number", "?value": 0.0},
          "Y": {r"$type": "number", "?value": 0.0},
          "Z": {r"$type": "number", "?value": 0.0}
        },
        "RotationRate": {
          "Alpha": {r"$type": "number", "?value": 0.0},
          "Beta": {r"$type": "number", "?value": 0.0},
          "Gamma": {r"$type": "number", "?value": 0.0}
        },
        "Interval": {r"$type": "number", "?value": 0.0}
      }
    },
    "Text_Display": {
      r"$name": "Text Display",
      "Visible": {r"$type": "bool", r"$writable": "write", "?value": false},
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
  SimpleNode accelXNode;
  SimpleNode accelYNode;
  SimpleNode accelZNode;
  SimpleNode rotAlphaNode;
  SimpleNode rotBetaNode;
  SimpleNode rotGammaNode;
  SimpleNode intervalNode;
  SimpleNode batteryNode;
  SimpleNode messageOpenNode;
  SimpleNodeProvider provider;

  StreamController<String> _msgStream;
  Stream<String> get onMessage => _msgStream.stream;

  StreamController<int> _fontStream;
  Stream<int> get onFontSize => _fontStream.stream;

  StreamController<bool> _msgVisible;
  Stream<bool> get onDisplayMsg => _msgVisible.stream;

  Html5Link(this.currentName, this.currentBroker) {
    provider = new SimpleNodeProvider();
    _msgStream = new StreamController<String>();
    _fontStream = new StreamController<int>();
    _msgVisible = new StreamController<bool>();
  }

  initialize() async {
    link = new LinkProvider(currentBroker, '${currentName}-',
        defaultNodes: defaultNodes, provider: provider);
    await link.init();
    latitudeNode = provider.getNode("/Geolocation/Latitude");
    longitudeNode = provider.getNode("/Geolocation/Longitude");
    headingNode = provider.getNode("/Geolocation/Heading");
    altitudeNode = provider.getNode("/Geolocation/Altitude");
    speedNode = provider.getNode("/Geolocation/Speed");
    alphaNode = provider.getNode("/Accelerometer/Orientation/Alpha");
    betaNode = provider.getNode("/Accelerometer/Orientation/Beta");
    gammaNode = provider.getNode("/Accelerometer/Orientation/Gamma");
    accelXNode = provider.getNode("/Accelerometer/Motion/Acceleration/X");
    accelYNode = provider.getNode("/Accelerometer/Motion/Acceleration/Y");
    accelZNode = provider.getNode("/Accelerometer/Motion/Acceleration/Z");
    rotAlphaNode = provider.getNode("/Accelerometer/Motion/RotationRate/Alpha");
    rotBetaNode = provider.getNode("/Accelerometer/Motion/RotationRate/Beta");
    rotGammaNode = provider.getNode("/Accelerometer/Motion/RotationRate/Gamma");
    intervalNode = provider.getNode("/Accelerometer/Motion/Interval");

    var textSizeNode = provider.getNode('/Text_Display/Text_Size');
    textSizeNode.subscribe((ValueUpdate update) {
      _fontStream.add(update.value);
    });
    textSizeNode.updateValue(12);

    provider.getNode('/Text_Display/Text').subscribe((ValueUpdate update) {
      _msgStream.add(update.value);
    });

    messageOpenNode = provider.getNode('/Text_Display/Visible')
        ..subscribe((ValueUpdate update) {
          _msgVisible.add(update.value);
        });
  }

  connect() async {
    link.close();
    link.brokerUrl = currentBroker;
    link.prefix = '${currentName}-';
    await link.init();
    link.connect();
  }

  void updateCoordinates(Coordinates coords) {
    latitudeNode.updateValue(coords.latitude);
    longitudeNode.updateValue(coords.longitude);
    headingNode.updateValue(coords.heading);
    altitudeNode.updateValue(coords.altitude);
    speedNode.updateValue(coords.speed);
  }

}