// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
@HtmlImport('main_app.html')
library dslink.html5.main_app;

import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:polymer/polymer.dart';
import 'package:polymer_elements/paper_dialog.dart';
import 'package:polymer_elements/paper_input.dart';
import 'package:polymer_elements/paper_button.dart';
import 'package:polymer_elements/paper_header_panel.dart';
import 'package:polymer_elements/paper_toolbar.dart';
import 'package:polymer_elements/paper_icon_button.dart';
import 'package:polymer_elements/iron_icons.dart';
import 'package:polymer_elements/av_icons.dart';
import 'package:polymer_elements/neon_animation.dart';
import 'package:web_components/web_components.dart';

import 'package:dslink_html5/app_router.dart';
import 'package:dslink_html5/link_model.dart';
import 'package:dslink_html5/html5_link.dart';

import 'package:dslink/browser.dart';

/// Uses [PaperInput]
@PolymerRegister('main-app')
class MainApp extends PolymerElement {
  @property
  String brokerUrl = '';
  @property
  String linkName = '';
  @property
  String replyMessage = '';
  @property
  LinkModel model;
  @property
  Html5Link link;

  @property
  String videoPath = '';

  VideoElement video;

  PaperDialog settingDialog;
  PaperDialog replyDialog;
  PaperDialog msgDialog;
  PaperDialog videoDialog;
  DivElement msgFont;

  String _origUrl;
  String _origName;
  bool _msgIsOpen = false;

  final Completer<bool> _readyComp = new Completer<bool>();
  Future<bool> get isReady => _readyComp.future;

  /// Constructor used to create instance of MainApp.
  MainApp.created() : super.created() {
    model = new LinkModel();
    notifyPath('model', model);
    settingDialog = $['settings-dialog'];
    settingDialog.on['iron-overlay-closed'].listen(closeSettingsDialog);
    replyDialog = $['reply-dialog'];
    replyDialog.on['iron-overlay-closed'].listen(closeReplyDialog);
    msgDialog = $['msg-dialog'];
    videoDialog = $['video-dialog'];
    msgDialog.on['iron-overlay-closed'].listen((_) {
      if (_msgIsOpen) {
        link.messageOpenNode.updateValue(false);
      }
      _msgIsOpen = false;
    });
    msgFont = $['msg-font'];
    video = $['video'];
  }

  /// Helper function to initialize [link] adding required listeners.
  @reflectable
  void _initLink() {
    if (link == null) {
      link = new Html5Link(linkName, brokerUrl)
        ..onFontSize.listen((font) {
          msgFont.style.fontSize = '${font}px';
        })
        ..onMessage.listen((msg) {
          set('model.message', msg);
        })
        ..onDisplayMsg.listen((isOn) {
          if (isOn) {
            _msgIsOpen = isOn;
            msgDialog.open();
          } else {
            if (_msgIsOpen) {
              _msgIsOpen = isOn;
              msgDialog.close();
            }
          }
        })
        ..initialize();
    }
  }

  @reflectable
  void openVideoDialog(Event e, detail) {
    videoDialog.open();
  }

  /// Event handler for open reply button
  @reflectable
  void openReplyDialog(Event e, detail) {
    replyDialog.open();
  }

  /// Event handler for reply dialog dismiss (button or click outside)
  @reflectable
  closeReplyDialog(CustomEvent e) async {
    var status = e.detail;
    if (status['confirmed'] == true) {
      _initLink();
      link.provider.updateValue('/Message', replyMessage);
      print(replyMessage);
    }
  }

  /// Event handler for open settings button
  @reflectable
  void openSettingsDialog(Event e, detail) {
    _origName = linkName;
    _origUrl = brokerUrl;
    settingDialog.open();
  }

  /// Event handler for settings dialog dismiss (by clicking outside or dismiss
  /// button)
  @reflectable
  closeSettingsDialog(CustomEvent e) async {
    var status = e.detail;
    // Closed with 'save' option.
    if (status['confirmed'] == true) {
      if (link == null) {
        _initLink();
      } else {
        link.currentName = linkName;
        link.currentBroker = brokerUrl;
      }
      window.localStorage['broker_url'] = brokerUrl;
      window.localStorage['link_name'] = linkName;
      await link.connect();
    } else {
      // closed with dismiss
      if (_origUrl != brokerUrl) {
        set('brokerUrl', _origUrl);
      }
      if (_origName != linkName) {
        set('linkName', _origName);
      }
    }
  }

  /// Event handler for 'on-route-changed' (fired by [AppRouter])
  @reflectable
  routeChanged(CustomEvent e, detail) async {
    set('brokerUrl', detail['url']);
    set('linkName', detail['name']);
    _initLink();
    if (detail['firstRun']) {
      isReady.then((_) {
        _origName = linkName;
        _origUrl = brokerUrl;
        settingDialog.open();
      });
    } else {
      link.currentBroker = brokerUrl;
      link.currentName = linkName;
      link.connect();
    }
  }

  // Optional lifecycle methods - uncomment if needed.

  /// Called when an instance of main-app is inserted into the DOM.
  @reflectable
  void attached() {
    super.attached();
    _readyComp.complete(true);

    /// Setup event listeners
    window.navigator.geolocation
        .watchPosition(
            enableHighAccuracy: true,
            timeout: const Duration(seconds: 60),
            maximumAge: const Duration(seconds: 0))
        .listen(positionUpdate)
        .onError((error) => print(error.message));

    window.on['deviceorientation'].listen(orientationUpdated);
    window.on['devicemotion'].listen(motionUpdated);
  }

  /// Event handler for device geolocation
  @reflectable
  void positionUpdate(Geoposition update) {
    var coords = update.coords;
    link.updateCoordinates(coords);

    set('model.latitude', coords.latitude.toStringAsFixed(7));
    set('model.longitude', coords.longitude.toStringAsFixed(7));

    if (coords.heading != null) {
      if ($['heading-box'].hidden) {
        $['heading-box'].hidden = false;
      }
      set('model.heading', coords.heading.toStringAsFixed(7));
    }

    if (coords.speed != null) {
      if ($['speed-box'].hidden) {
        $['speed-box'].hidden = false;
      }
      set('model.speed', coords.speed.toStringAsFixed(7));
    }
  }

  /// Event handler for device orientation.
  @reflectable
  void orientationUpdated(DeviceOrientationEvent e) {
    if (e.alpha != null) {
      if ($['alpha-box'].hidden) {
        $['alpha-box'].hidden = false;
      }
      link.alphaNode.updateValue(e.alpha);
      set('model.alpha', e.alpha.toStringAsFixed(7));
    }
    if (e.beta != null) {
      if ($['beta-box'].hidden) {
        $['beta-box'].hidden = false;
      }
      link.betaNode.updateValue(e.beta);
      set('model.beta', e.beta.toStringAsFixed(7));
    }
    if (e.gamma != null) {
      if ($['gamma-box'].hidden) {
        $['gamma-box'].hidden = false;
      }
      link.gammaNode.updateValue(e.gamma);
      set('model.gamma', e.gamma.toStringAsFixed(7));
    }
  }

  /// Event handler for device motion
  @reflectable
  void motionUpdated(DeviceMotionEvent e) {
    if (e.acceleration?.x != null &&
        e.acceleration?.y != null &&
        e.acceleration?.z != null) {
      var accel = e.acceleration;

      link
        ..accelXNode.updateValue(accel.x)
        ..accelYNode.updateValue(accel.y)
        ..accelZNode.updateValue(accel.z)
        ..intervalNode.updateValue(e.interval);
      set('model.accelX', accel.x.toStringAsFixed(2));
      set('model.accelY', accel.y.toStringAsFixed(2));
      set('model.accelZ', accel.z.toStringAsFixed(2));
    }

    if (e.rotationRate != null) {
      var rot = e.rotationRate;
      link
        ..rotAlphaNode.updateValue(rot.alpha)
        ..rotBetaNode.updateValue(rot.beta)
        ..rotGammaNode.updateValue(rot.gamma);
    }
  }

  @reflectable
  startVideo(Event e, detail) async {
    if (video.src != null && video.src.isNotEmpty) {
      video.pause();
      video.src = "";
    }

    var path = videoPath;
    print("Displaying Video from ${path}");

    var sizePath = path + "/size";
    var getChunkPath = path + "/readBinaryChunk";
    var contentTypePath = path + "/type";

    int size = (await link.link.requester.getNodeValue(sizePath)).value;
    String contentType = (await link.link.requester.getNodeValue(contentTypePath)).value;
    String codec = 'video/mp4; codecs="avc1.42E01E, mp4a.40.2"';

    if (contentType == "video/webm") {
      codec = 'video/webm; codecs="vorbis, vp8"';
    }

    print("Video Size: ${size} bytes");

    var source = new MediaSource();

    source.addEventListener("sourceopen", (e) async {
      CHUNK_COUNT = (size / 512000).round();
      var chunkSize = (size / CHUNK_COUNT).ceil();

      print("Chunk Size: ${chunkSize} bytes");

      var buff = source.addSourceBuffer(codec);
      for (var i = 0; i < CHUNK_COUNT; ++i) {
        var start = chunkSize * i;
        var end = start + chunkSize;
        RequesterInvokeUpdate update = await link.link.requester.invoke(getChunkPath, {
          "start": start,
          "end": start + chunkSize
        }).first;

        Map map = update.updates[0];
        ByteData data = map["data"];

        print("Chunk ${i} out of ${CHUNK_COUNT}");

        if (i + 1 == CHUNK_COUNT) {
          source.endOfStream();
        } else {
          buff.appendBuffer(data.buffer);
        }

        await buff.on["updateend"].first;
      }

      source.endOfStream();
    });

    video.src = Url.createObjectUrlFromSource(source);
    video.autoplay = true;
    video.play();
  }

  int CHUNK_COUNT = 200;

//  /// Called when an instance of main-app is removed from the DOM.
//  detached() {
//    super.detached();
//  }

//  /// Called when an attribute (such as a class) of an instance of
//  /// main-app is added, changed, or removed.
//  attributeChanged(String name, String oldValue, String newValue) {
//    super.attributeChanged(name, oldValue, newValue);
//  }

//  /// Called when main-app has been fully prepared (Shadow DOM created,
//  /// property observers set up, event listeners attached).
//  ready() {
//  }
}
