import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class JsBridgeService {
  late final WebViewController _controller;
  final _tlvStreamController = StreamController<Uint8List>.broadcast();

  Stream<Uint8List> get tlvStream => _tlvStreamController.stream;

  Future<void> init() async {
    final javascriptBridge =
        await rootBundle.loadString('assets/js/javascript_bridge.js');
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <script>
    function flutterLog(msg) {
      if (window.FlutterLogChannel) {
        FlutterLogChannel.postMessage(msg);
      }
    }

    $javascriptBridge

    function debugFlutter(msg) {
      if (window.FlutterDebugChannel) {
        FlutterDebugChannel.postMessage(msg);
      }
      console.log('[FlutterDebug]', msg);
    }

    function sendGifTLV(obj, gifBase64) {
      try {
        const res = [];
        if (gifBase64) {
          const bin = atob(gifBase64);
          const arr = new Uint8Array(bin.length);
          for (let i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
          res.push(arr);
          debugFlutter("sendGifTLV: Used real GIF data in res[0]");
        } else {
          res.push(new Uint8Array([0]));
          debugFlutter("sendGifTLV: Fallback dummy payload used");
        }
        const tlv = parse_data(obj, res);
        debugFlutter("sendGifTLV: TLV generated, length: " + (tlv?.length ?? 'null'));
        postTLVResult(obj, tlv);
      } catch (e) {
        postError(obj, e);
      }
    }

    function sendImageTLV(obj) {
      try {
        const res = [];

        if (obj.res_base64) {
          const bin = atob(obj.res_base64);
          const arr = new Uint8Array(bin.length);
          for (let i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
          res.push(arr);
          debugFlutter('sendImageTLV: res_base64 found, length: ' + arr.length);
        } else {
          console.warn("⚠️ No res_base64 found in image JSON");
          debugFlutter('sendImageTLV: No res_base64 found in image JSON');
        }

        const tlv = parse_data(obj, res);
        debugFlutter('sendImageTLV: TLV generated, length: ' + (tlv ? tlv.length : 'null'));
        postTLVResult(obj, tlv);
      } catch (e) {
        postError(obj, e);
      }
    }

    function sendTextTLV(obj) {
      try {
        const tlv = parse_data(obj, []);
        debugFlutter("sendTextTLV: TLV generated, length: " + (tlv?.length ?? 'null'));
        postTLVResult(obj, tlv);
      } catch (e) {
        postError(obj, e);
      }
    }

    function sendRTDrawTLV(obj) {
  try {
    const tlv = parse_data(obj, []);
    debugFlutter("sendRTDrawTLV: TLV generated, length: " + (tlv?.length ?? 'null'));
    postTLVResult(obj, tlv);
  } catch (e) {
    postError(obj, e);
  }
}


    function postTLVResult(obj, tlv) {
      if (tlv && tlv.length > 0) {
        debugFlutter('postTLVResult: TLV valid, sending to Dart. Length: ' + tlv.length);
        const b64 = btoa(String.fromCharCode(...tlv));
        TLVChannel.postMessage(b64);
      } else {
        debugFlutter('postTLVResult: Empty TLV generated, sending error to Dart.');
        TLVChannel.postMessage(JSON.stringify({
          error: "❌ Empty TLV generated",
          input: obj
        }));
      }
    }

    function postError(obj, e) {
      debugFlutter('postError: TLV generation error: ' + e.toString());
      console.error('❌ TLV generation error:', e);
      TLVChannel.postMessage(JSON.stringify({
        error: e.toString(),
        stack: e.stack,
        input: obj
      }));
    }

    function parseTLVHexNotification(hexStr) {
      try {
        const bytes = hexStr.trim().split(' ').map(b => parseInt(b, 16));
        const parsed = parse_ack(bytes);
        TLVChannel.postMessage(JSON.stringify({ ack: parsed }));
      } catch (e) {
        TLVChannel.postMessage(JSON.stringify({ ackError: e.toString() }));
      }
    }
  </script>
</head>
<body>
  <h3>Decoded Image Preview:</h3>
  <canvas id="debugCanvas" width="500" height="500" style="border:1px solid #000; image-rendering: pixelated;"></canvas>
  <br/>
  <button onclick="saveCanvasAsPNG()">Save as PNG</button>
  <script>
    function saveCanvasAsPNG() {
      const canvas = document.getElementById('debugCanvas');
      if (!canvas) return;
      const link = document.createElement('a');
      link.download = 'canvas_image.png';
      link.href = canvas.toDataURL('image/png');
      link.click();
    }
  </script>
</body>
</html>
''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'TLVChannel',
        onMessageReceived: (msg) {
          final message = msg.message.trim();
          if (message.isNotEmpty) {
            try {
              final bytes = base64.decode(message);
              _tlvStreamController.add(Uint8List.fromList(bytes));
            } catch (e) {
              // handle error
            }
          }
        },
      )
      ..loadHtmlString(html);
  }

  WebViewController get controller => _controller;

  /// Call this to send an image or GIF to JS for TLV encoding
  Future<void> sendImageOrGif(Map<String, dynamic> jsonCmd,
      {String? base64Image, String? gifBase64}) async {
    final jsonStr = jsonEncode(jsonCmd);
    if (gifBase64 != null) {
      await _controller.runJavaScript("sendGifTLV($jsonStr, '$gifBase64');");
    } else if (base64Image != null) {
      await _controller.runJavaScript("sendImageTLV($jsonStr);");
    }
  }

  Future<void> sendText(Map<String, dynamic> jsonCmd) async {
    final jsonStr = jsonEncode(jsonCmd);
    await _controller.runJavaScript("sendTextTLV($jsonStr);");
  }

  Future<void> sendRTDraw(Map<String, dynamic> jsonCmd) async {
    final jsonStr = jsonEncode(jsonCmd);
    await _controller.runJavaScript("sendRTDrawTLV($jsonStr);");
  }  

  void dispose() {
    _tlvStreamController.close();
  }
}
