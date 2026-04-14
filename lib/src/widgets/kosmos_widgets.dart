import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/theme.dart';

/// Animated triple-dot spinner replacing CircularProgressIndicator
class KosmosSpinner extends StatefulWidget {
  final double size;
  final Color? color;
  const KosmosSpinner({super.key, this.size = 20, this.color});

  @override
  State<KosmosSpinner> createState() => _KosmosSpinnerState();
}

class _KosmosSpinnerState extends State<KosmosSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.accentLight;
    final dotSize = widget.size * 0.28;
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return CustomPaint(
              isComplex: true,
              willChange: true,
              painter: _SpinnerPainter(
                progress: _ctrl.value,
                color: color,
                dotSize: dotSize,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double dotSize;

  _SpinnerPainter({
    required this.progress,
    required this.color,
    required this.dotSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - dotSize / 2;

    for (int i = 0; i < 3; i++) {
      final angle = progress * 2 * math.pi + (i * 2 * math.pi / 3);
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      final opacity = (1.0 - (i * 0.25)).clamp(0.3, 1.0);
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), dotSize / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter old) =>
      old.progress != progress;
}

/// Animated shimmer progress bar replacing LinearProgressIndicator
class KosmosProgressBar extends StatefulWidget {
  final double height;
  final Color? color;
  const KosmosProgressBar({super.key, this.height = 2.5, this.color});

  @override
  State<KosmosProgressBar> createState() => _KosmosProgressBarState();
}

class _KosmosProgressBarState extends State<KosmosProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.accent;
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return CustomPaint(
              isComplex: true,
              willChange: true,
              size: Size(double.infinity, widget.height),
              painter: _ShimmerBarPainter(
                progress: _ctrl.value,
                color: color,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShimmerBarPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ShimmerBarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.surface;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final barWidth = size.width * 0.35;
    final start = progress * (size.width + barWidth) - barWidth;
    final gradient = LinearGradient(
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.8),
        color,
        color.withValues(alpha: 0.8),
        color.withValues(alpha: 0.0),
      ],
    );
    final rect = Rect.fromLTWH(start, 0, barWidth, size.height);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShimmerBarPainter old) =>
      old.progress != progress;
}

/// Avatar with optional accent ring (no CircleAvatar — lighter repaint).
class KosmosAvatar extends StatelessWidget {
  final String initials;
  final double radius;
  final Color? backgroundColor;
  final bool showRing;

  const KosmosAvatar({
    super.key,
    required this.initials,
    this.radius = 20,
    this.backgroundColor,
    this.showRing = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.accent.withValues(alpha: 0.2);
    final d = radius * 2;
    final inner = RepaintBoundary(
      child: Container(
        width: d,
        height: d,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
        ),
        child: Text(
          initials,
          style: TextStyle(
            color: AppColors.accentLight,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.7,
          ),
        ),
      ),
    );
    if (!showRing) return inner;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent,
            AppColors.accentLight,
            AppColors.accentMuted,
          ],
        ),
      ),
      child: inner,
    );
  }
}

/// Glassmorphism container
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.blur = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.6),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Animated badge (unread count, status pill)
class KosmosBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final bool pulse;

  const KosmosBadge({
    super.key,
    required this.text,
    this.color,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.accent;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
    if (!pulse) return badge;
    return _PulseBadge(child: badge);
  }
}

class _PulseBadge extends StatefulWidget {
  final Widget child;
  const _PulseBadge({required this.child});

  @override
  State<_PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<_PulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Transform.scale(
          scale: 1.0 + 0.08 * _ctrl.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Premium button with glow and press animation
class KosmosButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool outlined;
  final IconData? icon;
  final bool loading;
  final bool danger;
  /// Narrower vertical padding for toolbars / dense rows.
  final bool compact;

  const KosmosButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.outlined = false,
    this.icon,
    this.loading = false,
    this.danger = false,
    this.compact = false,
  });

  @override
  State<KosmosButton> createState() => _KosmosButtonState();
}

class _KosmosButtonState extends State<KosmosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.danger
        ? AppColors.red
        : (widget.color ?? AppColors.accent);
    final enabled = widget.onPressed != null && !widget.loading;

    return AnimatedBuilder(
      animation: _pressCtrl,
      builder: (_, __) {
        return Transform.scale(
          scale: _scale.value,
          child: GestureDetector(
            onTapDown: enabled ? (_) => _pressCtrl.forward() : null,
            onTapUp: enabled
                ? (_) {
                    _pressCtrl.reverse();
                    HapticFeedback.lightImpact();
                    widget.onPressed?.call();
                  }
                : null,
            onTapCancel: enabled ? () => _pressCtrl.reverse() : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: widget.compact ? 10 : 14,
              ),
              decoration: BoxDecoration(
                color: widget.outlined
                    ? Colors.transparent
                    : (enabled
                        ? baseColor
                        : baseColor.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: widget.outlined
                      ? (widget.danger
                          ? baseColor.withValues(alpha: 0.4)
                          : AppColors.border)
                      : Colors.transparent,
                ),
                boxShadow: !widget.outlined && enabled
                    ? [
                        BoxShadow(
                          color: baseColor.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeInOutCubic,
                  switchOutCurve: Curves.easeInOutCubic,
                  child: widget.loading
                      ? KosmosSpinner(
                          key: const ValueKey("spin"),
                          size: 20,
                          color: widget.outlined
                              ? baseColor
                              : Colors.white,
                        )
                      : Row(
                          key: const ValueKey("label"),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                size: 18,
                                color: widget.outlined
                                    ? (widget.danger
                                        ? baseColor
                                        : AppColors.textPrimary)
                                    : Colors.white,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: widget.outlined
                                    ? (widget.danger
                                        ? baseColor
                                        : AppColors.textPrimary)
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Branded gradient title for the app bar.
class KosmosAppTitle extends StatelessWidget {
  const KosmosAppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/branding/kosmos-orbit-mark.png',
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.accentLight, AppColors.accentMuted],
          ).createShader(bounds),
          child: const Text(
            "Kosmos",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Rounded surface with soft accent glow (replaces ad-hoc profile / settings cards).
class KosmosSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool showAccentCap;

  const KosmosSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = AppRadii.lg,
    this.showAccentCap = true,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.07),
              blurRadius: 28,
              offset: const Offset(0, 10),
              spreadRadius: -12,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -14,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showAccentCap)
                Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentLight,
                        AppColors.accent,
                        AppColors.accentMuted,
                      ],
                    ),
                  ),
                ),
              Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Text field with Kosmos styling (does not rely on theme defaults alone).
class KosmosTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool autocorrect;
  final int? maxLines;

  const KosmosTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.autocorrect = true,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      maxLines: maxLines,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
      cursorColor: AppColors.accentLight,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: AppColors.textTertiary)
            : null,
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Toolbar / list icon control with haptic (replaces IconButton in key places).
class KosmosIconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double iconSize;
  final Color? color;
  final String? tooltip;

  const KosmosIconAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.iconSize = 22,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    final btn = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        onTap: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: iconSize, color: c),
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) return btn;
    return Tooltip(message: tooltip!, child: btn);
  }
}

/// Compact primary pill for inline actions (e.g. visitor «Открыть»).
class KosmosInlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const KosmosInlineButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// Online / away chip for the app bar.
class KosmosPresenceToggle extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onChanged;

  const KosmosPresenceToggle({
    super.key,
    required this.isOnline,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isOnline),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: isOnline
              ? AppColors.green.withValues(alpha: 0.14)
              : AppColors.orange.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: isOnline
                ? AppColors.green.withValues(alpha: 0.35)
                : AppColors.orange.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.green : AppColors.orange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              child: Text(
                isOnline ? "Онлайн" : "Отошёл",
                key: ValueKey(isOnline),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOnline ? AppColors.green : AppColors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom snackbar with icon and animation
void showKosmosSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
  bool isSuccess = false,
}) {
  final color = isError
      ? AppColors.red
      : (isSuccess ? AppColors.green : AppColors.accentLight);
  final icon = isError
      ? Icons.error_outline_rounded
      : (isSuccess
          ? Icons.check_circle_outline_rounded
          : Icons.info_outline_rounded);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.surfaceLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: const Duration(seconds: 3),
    ),
  );
}
