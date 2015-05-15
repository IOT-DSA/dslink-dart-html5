import "dart:html" show HttpRequest;
import "package:dslink/worker.dart";

main(args, message) async {
  await buildWorkerForScript(message).init(methods: {
    "hello": (_) => print("Hello World"),
    "fetch": (String url) =>
      HttpRequest.getString(url)
  });
}
