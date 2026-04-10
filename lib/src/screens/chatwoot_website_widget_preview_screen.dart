import 'package:flutter/material.dart';

/// Демо UI как у официального website widget Chatwoot (пузырёк + окно во фрейме).
/// Цвета и пропорции близки к `app/javascript/sdk/sdk.js` (SDK_CSS).
class ChatwootWebsiteWidgetPreviewScreen extends StatefulWidget {
  const ChatwootWebsiteWidgetPreviewScreen({super.key});

  static const Color chatwootBlue = Color(0xFF1F93FF);

  @override
  State<ChatwootWebsiteWidgetPreviewScreen> createState() =>
      _ChatwootWebsiteWidgetPreviewScreenState();
}

class _ChatwootWebsiteWidgetPreviewScreenState
    extends State<ChatwootWebsiteWidgetPreviewScreen> {
  bool _panelOpen = false;
  bool _expandedBubble = false;
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isNarrow = mq.size.width < 668;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Как выглядит виджет Chatwoot"),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _expandedBubble = !_expandedBubble),
            icon: Icon(
              _expandedBubble ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: Colors.white70,
            ),
            label: Text(
              _expandedBubble ? "Expanded bubble" : "Standard bubble",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Условная «страница сайта» под виджетом
          Container(
            width: double.infinity,
            color: const Color(0xFFF2F3F7),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Пример сайта",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF37546D),
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Скрипт Chatwoot вставляет пузырёк и iframe с маршрутом "
                      "/widget. Ниже — упрощённая копия внешнего вида.",
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Панель чата (как .woot-widget-holder; на узком экране — на весь экран, как в SDK)
          if (_panelOpen && isNarrow)
            Positioned.fill(
              child: _WidgetPanel(
                onClose: () => setState(() => _panelOpen = false),
                composer: _composer,
                fullBleed: true,
              ),
            )
          else if (_panelOpen)
            Positioned(
              right: 20,
              bottom: 104,
              width: 400,
              height: (mq.size.height * 0.9 - 64 - 20).clamp(250.0, 640.0),
              child: _WidgetPanel(
                onClose: () => setState(() => _panelOpen = false),
                composer: _composer,
                fullBleed: false,
              ),
            ),

          // Лаунчер (как .woot-widget-bubble; на мобильном при открытой панели SDK прячет bubble)
          if (!(isNarrow && _panelOpen))
            Positioned(
              right: 20,
              bottom: 24,
              child: _LauncherBubble(
                expanded: _expandedBubble,
                onTap: () => setState(() => _panelOpen = !_panelOpen),
                open: _panelOpen,
              ),
            ),
        ],
      ),
    );
  }
}

class _LauncherBubble extends StatelessWidget {
  final bool expanded;
  final bool open;
  final VoidCallback onTap;

  const _LauncherBubble({
    required this.expanded,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return Material(
        elevation: 8,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(100),
        color: ChatwootWebsiteWidgetPreviewScreen.chatwootBlue,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 20, 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  open ? Icons.close_rounded : Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  open ? "Закрыть" : "Напишите нам",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      elevation: 8,
      shadowColor: Colors.black38,
      shape: const CircleBorder(),
      color: ChatwootWebsiteWidgetPreviewScreen.chatwootBlue,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(
            open ? Icons.close_rounded : Icons.chat_bubble_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _WidgetPanel extends StatelessWidget {
  final VoidCallback onClose;
  final TextEditingController composer;
  final bool fullBleed;

  const _WidgetPanel({
    required this.onClose,
    required this.composer,
    required this.fullBleed,
  });

  @override
  Widget build(BuildContext context) {
    final radius = fullBleed ? 0.0 : 16.0;
    return Material(
      elevation: fullBleed ? 0 : 16,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: fullBleed ? null : Border.all(color: const Color(0xFFE8E9EF)),
          boxShadow: fullBleed
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 40,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: ChatwootWebsiteWidgetPreviewScreen.chatwootBlue,
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Поддержка Acme",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Обычно отвечаем за несколько минут",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFF9FAFB),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                  children: const [
                    _AgentBubble(
                      text:
                          "Здравствуйте! Чем можем помочь? Это демо-интерфейс, похожий на окно /widget.",
                    ),
                    SizedBox(height: 10),
                    _UserBubble(text: "Нужна консультация по тарифу."),
                    SizedBox(height: 10),
                    _AgentBubble(
                      text:
                          "Сейчас уточним. Реальный виджет рендерится во Vue внутри iframe.",
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                10,
                8,
                10,
                8 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.mood_outlined, color: Colors.grey.shade600),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.attach_file_rounded,
                        color: Colors.grey.shade600),
                  ),
                  Expanded(
                    child: TextField(
                      controller: composer,
                      decoration: InputDecoration(
                        hintText: "Введите сообщение…",
                        filled: true,
                        fillColor: const Color(0xFFF2F3F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    backgroundColor:
                        ChatwootWebsiteWidgetPreviewScreen.chatwootBlue,
                    radius: 22,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {},
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentBubble extends StatelessWidget {
  final String text;

  const _AgentBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(text, style: const TextStyle(fontSize: 14, height: 1.35)),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;

  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: ChatwootWebsiteWidgetPreviewScreen.chatwootBlue
              .withValues(alpha: 0.12),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 14, height: 1.35)),
      ),
    );
  }
}
