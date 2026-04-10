import 'dart:async';
import 'dart:math';

import 'package:chatwoot_sdk/chatwoot_callbacks.dart';
import 'package:chatwoot_sdk/chatwoot_client.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_message.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_user.dart';
import 'package:mobile/src/models/app_user.dart';

class ChatState {
  final List<ChatwootMessage> messages;
  final bool loading;
  final bool typing;
  final String? error;
  final bool connected;

  const ChatState({
    required this.messages,
    required this.loading,
    required this.typing,
    required this.connected,
    required this.error,
  });

  factory ChatState.initial() => const ChatState(
    messages: [],
    loading: false,
    typing: false,
    connected: false,
    error: null,
  );

  ChatState copyWith({
    List<ChatwootMessage>? messages,
    bool? loading,
    bool? typing,
    bool? connected,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      typing: typing ?? this.typing,
      connected: connected ?? this.connected,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatService {
  final _controller = StreamController<ChatState>.broadcast();
  ChatState _state = ChatState.initial();
  ChatwootClient? _client;
  String? _baseUrl;
  String? _inbox;
  String? _identifier;

  Stream<ChatState> get state => _controller.stream;
  ChatState get currentState => _state;

  Future<void> connect({
    required String baseUrl,
    required String inboxIdentifier,
    required AppUser user,
  }) async {
    final sameSession =
        _baseUrl == baseUrl &&
        _inbox == inboxIdentifier &&
        _identifier == user.id &&
        _client != null;
    if (sameSession) return;

    await disconnect();
    _emit(_state.copyWith(loading: true, clearError: true));

    final callbacks = ChatwootCallbacks(
      onMessagesRetrieved: _onMessages,
      onPersistedMessagesRetrieved: _onMessages,
      onMessageReceived: (message) => _append(message),
      onMessageDelivered: (message, _) => _append(message),
      onMessageSent: (message, _) => _append(message),
      onConversationStartedTyping: () => _emit(_state.copyWith(typing: true)),
      onConversationStoppedTyping: () => _emit(_state.copyWith(typing: false)),
      onError:
          (error) =>
              _emit(_state.copyWith(loading: false, error: error.toString())),
      onConfirmedSubscription:
          () => _emit(
            _state.copyWith(connected: true, loading: false, clearError: true),
          ),
    );

    _client = await ChatwootClient.create(
      baseUrl: baseUrl,
      inboxIdentifier: inboxIdentifier,
      callbacks: callbacks,
      user: ChatwootUser(
        identifier: user.id,
        email: user.email,
        name: user.name,
      ),
      enablePersistence: true,
    );

    _baseUrl = baseUrl;
    _inbox = inboxIdentifier;
    _identifier = user.id;
    _client?.loadMessages();
    _emit(_state.copyWith(connected: true, loading: false));
  }

  Future<void> reload() async {
    _emit(_state.copyWith(loading: true));
    _client?.loadMessages();
    _emit(_state.copyWith(loading: false));
  }

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || _client == null) return;
    final echo =
        "${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(999)}";
    await _client!.sendMessage(content: trimmed, echoId: echo);
  }

  Future<void> disconnect() async {
    _client?.dispose();
    _client = null;
    _emit(ChatState.initial());
  }

  void _onMessages(List<ChatwootMessage> messages) {
    final sorted = [...messages]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _emit(_state.copyWith(messages: sorted, loading: false, clearError: true));
  }

  void _append(ChatwootMessage message) {
    final list = [
      ..._state.messages.where((item) => item.id != message.id),
      message,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _emit(_state.copyWith(messages: list, clearError: true));
  }

  void _emit(ChatState state) {
    _state = state;
    if (!_controller.isClosed) {
      _controller.add(_state);
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
  }
}
