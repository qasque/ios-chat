import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mobile/src/models/app_user.dart';
import 'package:mobile/src/services/chat_service.dart';

class ChatController extends ChangeNotifier {
  final ChatService _service;
  StreamSubscription<ChatState>? _sub;
  ChatState _state = ChatState.initial();

  ChatController(this._service) {
    _sub = _service.state.listen((next) {
      _state = next;
      notifyListeners();
    });
  }

  ChatState get state => _state;

  Future<void> connect({
    required String baseUrl,
    required String inboxIdentifier,
    required AppUser user,
  }) {
    return _service.connect(
      baseUrl: baseUrl,
      inboxIdentifier: inboxIdentifier,
      user: user,
    );
  }

  Future<void> sendMessage(String message) => _service.sendMessage(message);

  Future<void> reload() => _service.reload();

  Future<void> disconnect() => _service.disconnect();

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
