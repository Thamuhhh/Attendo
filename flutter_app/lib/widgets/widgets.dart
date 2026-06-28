import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme.dart';

class GradientAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double fontSize;

  const GradientAvatar({super.key, required this.name, this.size = 48, this.fontSize = 18});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF6C63FF), const Color(0xFF00C9A7), const Color(0xFFEF5350),
      const Color(0xFFFF7043), const Color(0xFFAB47BC), const Color(0xFF26C6DA),
      const Color(0xFFEC407A), const Color(0xFF7E57C2), const Color(0xFF66BB6A),
      const Color(0xFF8D6E63), const Color(0xFF78909C), const Color(0xFF5C6BC0),
      const Color(0xFF42A5F5), const Color(0xFF9CCC65), const Color(0xFFFFA726),
    ];
    final bg = colors[name.hashCode.abs() % colors.length];
    final char = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg, bg.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: bg.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Center(
        child: Text(char, style: TextStyle(
          color: Colors.white, fontWeight: FontWeight.w600, fontSize: fontSize * 0.55,
        )),
      ),
    );
  }
}

class AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Color? color;
  final double? fontSize;

  const AnimatedCounter({super.key, required this.value, this.style, this.color, this.fontSize});

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _display = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.addListener(() {
      setState(() => _display = (_anim.value * widget.value).round());
    });
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _ctrl.reset();
      _ctrl.forward();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Text('$_display', style: widget.style ?? TextStyle(fontSize: widget.fontSize ?? 28, fontWeight: FontWeight.w800, color: widget.color));
  }
}

class StaggeredList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsets padding;

  const StaggeredList({super.key, required this.itemCount, required this.itemBuilder, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (ctx, i) => _StaggeredItem(index: i, child: itemBuilder(ctx, i)),
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggeredItem({required this.index, required this.child});

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 50 * widget.index), _ctrl.forward);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class CircularProgressWidget extends StatelessWidget {
  final int percent;
  final double size;
  final double strokeWidth;

  const CircularProgressWidget({super.key, required this.percent, this.size = 72, this.strokeWidth = 6});

  Color get _color => percent >= 75 ? AppTheme.success : (percent >= 50 ? AppTheme.warning : AppTheme.danger);

  double get _fraction => percent / 100.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size, height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: _fraction),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (ctx, v, _) => CustomPaint(
                painter: _RingPainter(v, _color, strokeWidth, context),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: percent.toDouble()),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (ctx, v, _) => Text('${v.round()}%', style: TextStyle(
                  fontSize: size * 0.22, fontWeight: FontWeight.w800, color: _color,
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final BuildContext context;

  _RingPainter(this.progress, this.color, this.strokeWidth, this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..color = AppTheme.greyShade(context, 200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint);

    paint.color = color;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final bool hasBorder;

  const GlassCard({super.key, required this.child, this.padding, this.margin, this.blur = 16, this.hasBorder = true});

  @override
  Widget build(BuildContext context) {
    final d = AppTheme.isDark(context);
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: d
            ? AppTheme.cardBgDark.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: hasBorder
            ? Border.all(
                color: d
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.6),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: d ? 0.25 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: d ? 0.1 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}

class BackgroundDecoration extends StatelessWidget {
  final Widget child;
  final double topPadding;

  const BackgroundDecoration({super.key, required this.child, this.topPadding = 0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _BgPainter(context))),
        if (topPadding > 0)
          Padding(padding: EdgeInsets.only(top: topPadding), child: child)
        else
          child,
      ],
    );
  }
}

class _BgPainter extends CustomPainter {
  final BuildContext context;
  _BgPainter(this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final d = AppTheme.isDark(context);
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = AppTheme.primary.withValues(alpha: d ? 0.05 : 0.03);
    canvas.drawCircle(Offset(size.width * 0.85, -20), 200, paint);
    canvas.drawCircle(Offset(-40, size.height * 0.4), 160, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.85), 140, paint);

    paint.color = AppTheme.accent.withValues(alpha: d ? 0.04 : 0.025);
    canvas.drawCircle(Offset(size.width * 0.2, -30), 120, paint);
    canvas.drawCircle(Offset(size.width - 40, size.height * 0.7), 100, paint);

    if (d) {
      paint.color = AppTheme.primaryLight.withValues(alpha: 0.02);
      canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.2), 80, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class ScaleOnPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ScaleOnPress({super.key, required this.child, this.onTap});

  @override
  State<ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<ScaleOnPress> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), lowerBound: 0.95, upperBound: 1);
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.value = 1;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) { _ctrl.forward(); widget.onTap?.call(); },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final d = AppTheme.isDark(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: d ? 0.2 : 0.08),
                    AppTheme.primary.withValues(alpha: d ? 0.1 : 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: AppTheme.primary.withValues(alpha: d ? 0.6 : 0.4)),
            ),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: d ? Colors.white : AppTheme.textPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: d ? Colors.grey.shade400 : AppTheme.textSecondary, height: 1.4)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, this.message = 'Something went wrong', this.onRetry});

  @override
  Widget build(BuildContext context) {
    final d = AppTheme.isDark(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.danger.withValues(alpha: d ? 0.2 : 0.08),
                    AppTheme.danger.withValues(alpha: d ? 0.1 : 0.03),
                  ],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 38, color: AppTheme.danger.withValues(alpha: d ? 0.6 : 0.4)),
            ),
            const SizedBox(height: 20),
            Text(message, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: d ? Colors.white70 : AppTheme.textSecondary, height: 1.4)),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CustomRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  CustomRoute({required this.page})
    : super(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      );
}
