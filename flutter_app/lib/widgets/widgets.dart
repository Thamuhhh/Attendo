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
      const Color(0xFF1976D2), const Color(0xFF388E3C), const Color(0xFFD32F2F),
      const Color(0xFFF57C00), const Color(0xFF7B1FA2), const Color(0xFF0097A7),
      const Color(0xFFC2185B), const Color(0xFF512DA8), const Color(0xFF00796B),
      const Color(0xFF5D4037), const Color(0xFF455A64), const Color(0xFF303F9F),
      const Color(0xFF0288D1), const Color(0xFF689F38), const Color(0xFFE64A19),
    ];
    final bg = colors[name.hashCode.abs() % colors.length];
    final char = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Text(char, style: TextStyle(
          color: Colors.white, fontWeight: FontWeight.w500, fontSize: fontSize * 0.55,
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
                painter: _RingPainter(v, _color, strokeWidth),
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

  _RingPainter(this.progress, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..color = Colors.grey.shade200
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

  const GlassCard({super.key, required this.child, this.padding, this.margin, this.blur = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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

  const BackgroundDecoration({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _BgPainter())),
        child,
      ],
    );
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = AppTheme.primary.withValues(alpha: 0.03);
    canvas.drawCircle(Offset(size.width * 0.85, -20), 180, paint);
    canvas.drawCircle(Offset(-40, size.height * 0.4), 140, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.85), 120, paint);

    paint.color = AppTheme.accent.withValues(alpha: 0.03);
    canvas.drawCircle(Offset(size.width * 0.2, -30), 100, paint);
    canvas.drawCircle(Offset(size.width - 40, size.height * 0.7), 90, paint);
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
