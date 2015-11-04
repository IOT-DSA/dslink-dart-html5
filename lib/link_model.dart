library dslink.html5.model;

import 'package:polymer/polymer.dart';

/// Acts as the model which interacts with the DOM.
/// This stores the values which are displayed on the interface page.
class LinkModel extends JsProxy {
  @reflectable String latitude = '';
  @reflectable String longitude = '';
  @reflectable String heading = '';
  @reflectable String speed = '';
  @reflectable String alpha = '';
  @reflectable String beta = '';
  @reflectable String gamma = '';
  @reflectable String accelX = '';
  @reflectable String accelY = '';
  @reflectable String accelZ = '';
  @reflectable int fontSize = 12;
  @reflectable String message = '';

  LinkModel();
}
