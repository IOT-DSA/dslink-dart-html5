import "dart:html";
 
import "package:dslink/browser_client.dart";
import "package:dslink/responder.dart";
import "package:dslink/src/crypto/pk.dart";

import "package:polymer/polymer.dart";

const String DEFAULT_BROKER = "http://titan.directcode.org:8025/conn";

BrowserECDHLink link;
SimpleNode latitudeNode;
SimpleNode longitudeNode;
SimpleNode headingNode;
SimpleNode altitudeNode;
SimpleNode speedNode;
SimpleNode alphaNode;
SimpleNode betaNode;
SimpleNode gammaNode;
SimpleNodeProvider provider = new SimpleNodeProvider();

main() async {
  await initPolymer();
  
  PrivateKey key;
 
  if (window.localStorage.containsKey("dsa_key")) {
    key = new PrivateKey.loadFromString(window.localStorage["dsa_key"]);
  } else {
    key = new PrivateKey.generate();
    window.localStorage["dsa_key"] = key.saveToString();
  }
 
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
 
  provider.init(defaultNodes);
 
  link = new BrowserECDHLink(DEFAULT_BROKER, "WebBrowser-", key,
      isResponder: true, isRequester: false,
      nodeProvider: provider);
  link.connect();
 
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
  });
  
  window.on["deviceorientation"].listen((event) {
    alphaNode.updateValue(event.alpha);
    betaNode.updateValue(event.beta);
    gammaNode.updateValue(event.gamma);
  });
}