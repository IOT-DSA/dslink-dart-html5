library dslink.html5.app_router;

import 'dart:html' as dom;
import 'package:polymer/polymer.dart';
//import 'package:web_components/web_components.dart';

@PolymerRegister('app-router')
class AppRouter extends PolymerElement {
  String _url;
  String _name;
  bool _updateUri = false;
  dom.Location _loc;

  bool firstRun = false;

  static const String defaultBroker = 'http://localhost:8080/conn';
  static const String defaultName = 'HTML5';

  AppRouter.created() : super.created() {
    _loc = dom.window.location;
    var args = {};
    if (_loc.search.length > 1) {
      args = Uri.splitQueryString(_loc.search.substring(1));
    }

    _getAddress(args);
    _getName(args);
  }

  @reflectable
  void _getAddress(Map args) {
    if (args['a'] != null && args['a'].isNotEmpty) {
      _url = args['a'];
    } else if (_loc.hash.isNotEmpty && _loc.hash.substring(1).isNotEmpty) {
      _url = Uri.decodeFull(_loc.hash.substring(1));
      _updateUri = true;
    } else if (dom.window.localStorage.containsKey('broker_url')) {
      _url = dom.window.localStorage['broker_url'];
      _updateUri = true;
    } else {
      _url = defaultBroker;
      _updateUri = true;
      firstRun = true;
    }
  }

  @reflectable
  void _getName(Map args) {
    if (args['n'] != null && args['n'].isNotEmpty) {
      _name = args['n'];
    } else if (dom.window.localStorage.containsKey('link_name')) {
      _name = dom.window.localStorage['link_name'];
      _updateUri = true;
    } else {
      _updateUri = true;
      _name = defaultName;
    }
  }

  void attached() {
    print('Firing: addr: $_url, name: $_name');
    if (_updateUri) {
      var url = _loc.protocol +
          '//' +
          _loc.host +
          _loc.pathname +
          '?n=${Uri.encodeComponent(_name)}'
          '&a=${Uri.encodeComponent(_url)}';
      print('Replacing: $url');
      dom.window.history
          .replaceState({'a': _url, 'n': _name}, dom.document.title, url);
      _updateUri = false;
    }
    this.fire('route-changed',
        detail: {'name': _name, 'url': _url, 'firstRun': firstRun});
  }
}
