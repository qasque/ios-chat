import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/theme.dart';

class PremiumNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const PremiumNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<PremiumNavBar> createState() => _PremiumNavBarState();
}

class _PremiumNavBarState extends State<PremiumNavBar>
    with TickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final AnimationController _glowCtrl;
  late Animation<double> _slideAnim;
  int _prevIndex = 0;

  static const _items = <_NavItemData>[
    _NavItemData(
      icon: Icons.forum_outlined,
      activeIcon: Icons.forum_rounded,
      label: "Диалоги",
    ),
    _NavItemData(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: "Чат",
    ),
    _NavItemData(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: "Профиль",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.selectedIndex;
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween(
      begin: widget.selectedIndex.toDouble(),
      end: widget.selectedIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _slideCtrl,
      curve: Curves.easeOutCubic,
    ));
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(PremiumNavBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      _slideAnim = Tween(
        begin: _prevIndex.toDouble(),
        end: widget.selectedIndex.toDouble(),
      ).animate(CurvedAnimation(
        parent: _slideCtrl,
        curve: Curves.easeOutBack,
      ));
      _slideCtrl.forward(from: 0);
      _glowCtrl.forward(from: 0);
      _prevIndex = widget.selectedIndex;
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.82),
            border: const Border(
              top: BorderSide(
                color: Color(0xFF2A2F38),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: AnimatedBuilder(
                animation: Listenable.merge([_slideCtrl, _glowCtrl]),
                builder: (context, _) => _buildBar(context, bottomPad),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBar(BuildContext context, double bottomPad) {
    final itemWidth = MediaQuery.of(context).size.width / _items.length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // sliding glow + pill
        Positioned(
          left: _slideAnim.value * itemWidth + (itemWidth - 56) / 2,
          top: 6,
          child: _buildIndicator(),
        ),
        // items
        Row(
          children: List.generate(_items.length, (i) {
            final active = i == widget.selectedIndex;
            return Expanded(
              child: _NavItem(
                data: _items[i],
                active: active,
                onTap: () {
                  if (i != widget.selectedIndex) {
                    HapticFeedback.lightImpact();
                    widget.onTap(i);
                  }
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildIndicator() {
    final glow = _glowCtrl.value;
    final glowOpacity = glow < 0.5
        ? (glow * 2).clamp(0.0, 1.0)
        : ((1 - glow) * 2).clamp(0.0, 1.0);

    return Column(
      children: [
        // glow blob above the pill
        Container(
          width: 56,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: RadialGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.18 + 0.12 * glowOpacity),
                AppColors.accent.withValues(alpha: 0.0),
              ],
              radius: 1.2,
            ),
          ),
        ),
        // the pill
        Container(
          width: 34,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: AppColors.accentLight.withValues(alpha: 0.7),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.4 + 0.3 * glowOpacity),
                blurRadius: 10 + 6 * glowOpacity,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavItem extends StatefulWidget {
  final _NavItemData data;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.active,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.12), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.96), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _bounceCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _bounceCtrl,
        builder: (context, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: _scale.value,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Icon(
                    widget.active ? widget.data.activeIcon : widget.data.icon,
                    key: ValueKey(widget.active),
                    size: 23,
                    color: widget.active
                        ? AppColors.accentLight
                        : AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: widget.active ? 11 : 10.5,
                  fontWeight: widget.active ? FontWeight.w600 : FontWeight.w400,
                  color: widget.active
                      ? AppColors.accentLight
                      : AppColors.textTertiary,
                  letterSpacing: widget.active ? 0.2 : 0,
                  fontFamily: "sans-serif",
                ),
                child: Text(widget.data.label),
              ),
            ],
          );
        },
      ),
    );
  }
}
