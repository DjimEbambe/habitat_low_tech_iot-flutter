import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _streamController = StreamController.broadcast();
  bool _isConnected = false;
  Timer? _reconnectTimer;

  Stream<Map<String, dynamic>> get stream => _streamController.stream;

  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://192.168.4.1/ws')); // Adresse IP de l'ESP32
      _isConnected = true;
      _channel!.stream.listen((data) {
        _streamController.add(jsonDecode(data));
      }, onError: (error) {
        _handleError(error);
      }, onDone: () {
        _handleDisconnect();
      });
    } catch (e) {
      _handleError(e);
    }
  }

  void send(Map<String, dynamic> message) {
    if (_isConnected) {
      try {
        _channel?.sink.add(jsonEncode(message));
      } catch (e) {
        _handleError(e);
      }
    } else {
      _handleError("WebSocket non connecté.");
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }

  void _handleError(dynamic error) {
    print("Erreur WebSocket : $error");
    _isConnected = false;
    _tryReconnect();
  }

  void _handleDisconnect() {
    print("Déconnecté du WebSocket.");
    _isConnected = false;
    _tryReconnect();
  }

  void _tryReconnect() {
    if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
      _reconnectTimer = Timer(Duration(seconds: 5), () {
        print("Tentative de reconnexion...");
        connect();
      });
    }
  }
}
