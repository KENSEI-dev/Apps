// services/websocket_service.dart
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class WebSocketService {
  static WebSocketChannel? _channel;

  /// Returns the correct backend host depending on platform/environment
  static String get _wsHost {
    if (kIsWeb) {
      // Flutter Web runs in the browser — backend is on localhost
      return 'localhost:8000';
    }
    // Android emulator: 10.0.2.2 maps to host machine's localhost
    // Physical device: replace with your machine's actual LAN IP e.g. 192.168.1.5:8000
    return '10.0.2.2:8000';
  }

  static void connect(Function(Map<String, dynamic>) onCrowdUpdate) {
    final uri = Uri.parse('ws://$_wsHost/ws/crowd');
    debugPrint('🔌 WS → $uri');

    try {
      _channel = WebSocketChannel.connect(uri);
      debugPrint('✅ WS CONNECTED');

      _channel!.stream.listen(
        (message) {
          debugPrint('📨 WS: $message');
          try {
            final data = jsonDecode(message as String);
            onCrowdUpdate(data as Map<String, dynamic>);
          } catch (e) {
            debugPrint('❌ JSON parse: $e');
          }
        },
        onError: (error) {
          debugPrint('❌ WS ERROR: $error');
          // Silently fail — app still works without live updates
        },
        onDone: () => debugPrint('🔌 WS CLOSED'),
        cancelOnError: false, // ← don't kill the stream on first error
      );
    } catch (e) {
      debugPrint('❌ WS connect failed: $e');
    }
  }

  static void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}