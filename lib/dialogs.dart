library dslink_html5.dialogs;

import 'package:mdl/mdl.dart';
import 'package:mdl/mdldialog.dart';
import 'package:mdl/mdlobservable.dart';

import 'package:di/di.dart' as di;

/// Custom Dialog for Reply Dialog Window
@MdlComponentModel @di.Injectable()
class ReplyDialog extends MaterialDialog {
  static const String _DEFAULT_SUBMIT_BUTTON = "Send";
  static const String _DEFAULT_CANCEL_BUTTON = "Close";

  String title = "Reply";
  String yesButton = _DEFAULT_SUBMIT_BUTTON;
  String noButton = _DEFAULT_CANCEL_BUTTON;

  ObservableProperty<String> replyValue = new ObservableProperty<String>("");

  ReplyDialog() : super(new DialogConfig());

  ReplyDialog call({ final String title: "",
  final String yesButton: _DEFAULT_SUBMIT_BUTTON, final String noButton: _DEFAULT_CANCEL_BUTTON }) {

    this.title = title;
    this.yesButton = yesButton;
    this.noButton = noButton;

    return this;
  }

  bool get hasTitle => (title != null && title.isNotEmpty);

  void onSubmit() {
    print(replyValue.value);
    close(MdlDialogStatus.OK);
  }

  void onCancel() {
    close(MdlDialogStatus.CANCEL);
  }

  @override
  String template = """
        <div class="mdl-dialog reply-dialog">
          <div class="mdl-dialog__content">
            {{#hasTitle}}<h5>{{title}}</h5>{{/hasTitle}}
              <div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
                  <input class="mdl-textfield__input" type="text" id="reply-value" mdl-model="replyDialog.replyValue"/>
                  <label class="mdl-textfield__label" for="reply-value">Message</label>
              </div>
          </div>
          <div class="mdl-dialog__actions">
            <button class="mdl-button mdl-js-button mdl-button--colored" data-mdl-click="onSubmit()">
              {{yesButton}}
            </button>
            <button class="mdl-button mdl-js-button" data-mdl-click="onCancel()">
              {{noButton}}
            </button>
          </div>
        </div>
        """;
}

/// Customer Dialog for Settings Dialog window.
@MdlComponentModel @di.Injectable()
class SettingsDialog extends MaterialDialog {
  static const String _DEFAULT_SUBMIT_BUTTON = "Save";

  String title = "Settings";
  String yesButton = _DEFAULT_SUBMIT_BUTTON;

  ObservableProperty<String> linkName;
  ObservableProperty<String> brokerUrl;

  SettingsDialog(String broker) : super(new DialogConfig()) {
    linkName = new ObservableProperty<String>("HTML5");
    brokerUrl = new ObservableProperty<String>(broker);
  }

  SettingsDialog call({ final String title: "",
  final String yesButton: _DEFAULT_SUBMIT_BUTTON }) {

    this.title = title;
    this.yesButton = yesButton;

    return this;
  }

  bool get hasTitle => (title != null && title.isNotEmpty);

  void onSubmit() {
    var newUrl = brokerUrl.value;
    if(!newUrl.endsWith('conn')) {
      if(newUrl.endsWith('/')) {
        newUrl = '${newUrl}conn';
      } else {
        newUrl = '$newUrl/conn';
      }
      brokerUrl.value = newUrl;
      print('newUrl: $newUrl');
    }

    close(MdlDialogStatus.OK);
  }

  @override
  String template = """
        <div class="mdl-dialog reply-dialog">
          <div class="mdl-dialog__content">
            {{#hasTitle}}<h5>{{title}}</h5>{{/hasTitle}}
              <div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
                  <input class="mdl-textfield__input" type="text" id="linkname" mdl-model="settingsDialog.linkName"/>
                  <label class="mdl-textfield__label" for="reply-value">Link Name</label>
              </div>
              <div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
                  <input class="mdl-textfield__input" type="text" id="brokerurl" mdl-model="settingsDialog.brokerUrl"/>
                  <label class="mdl-textfield__label" for="reply-value">Broker URL</label>
              </div>
          </div>
          <div class="mdl-dialog__actions">
            <button class="mdl-button mdl-js-button mdl-button--colored" data-mdl-click="onSubmit()">
              {{yesButton}}
            </button>
          </div>
        </div>
        """;
}

/// Customer Dialog for Settings Dialog window.
@MdlComponentModel @di.Injectable()
class TextDisplayDialog extends MaterialDialog {
  ObservableProperty<String> text;
  ObservableProperty<int> fontSize;
  //ObservableProperty<bool> visible;

  TextDisplayDialog() : super (new DialogConfig()) {
    text = new ObservableProperty<String>('TestaRoonie');
    fontSize = new ObservableProperty<int>(12);
  }

  TextDisplayDialog call() => this;

  @override
  String template = """
      <div class="mdl-dialog text-dialog">
        <div class="mdl-dialog__content">
          <style>
          #text {
            font-size: {{fontSize.value}}px;
          }
          </style>
          <p id="text">{{text.value}}</p>
        </div>
      </div>
      """;
}